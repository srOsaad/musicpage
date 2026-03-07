import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/music_provider.dart';
import '../../utils/lrc_parser.dart';
import 'widgets/music_info_view.dart';
import 'widgets/queue_view.dart';
import 'widgets/lrc_view.dart';
import 'widgets/smoke_painter.dart';

class MusicPage extends StatefulWidget {
  final bool showQueue;
  const MusicPage({super.key, this.showQueue = false});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage>
    with SingleTickerProviderStateMixin {
  late bool _showQueue;
  bool _showLrc = false;
  bool _isDragging = false;
  double _dragValue = 0.0;
  // Calculated once from MediaQuery — never rechecked again
  double _artSize = 0;

  late PageController _pageController;
  late AnimationController _smokeController;
  MusicProvider? _provider;
  final ValueNotifier<bool> _isProgrammaticScroll = ValueNotifier(false);

  // LRC cache — keyed by song index
  final Map<int, List<LrcLine>> _lrcData = {};

  // Repeating seek timer for long-press on skip buttons
  Timer? _seekRepeatTimer;

  // Track song index so _onProviderChange can detect auto-advance
  int _lastKnownSongIndex = -1;

  @override
  void initState() {
    super.initState();
    _showQueue = widget.showQueue;

    _provider = Provider.of<MusicProvider>(context, listen: false);
    _lastKnownSongIndex = _provider!.currentSongIndex;
    _pageController = PageController(initialPage: _provider!.currentSongIndex);

    _smokeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    if (_provider!.isPlaying) _smokeController.repeat();
    _provider!.addListener(_onProviderChange);

    // Load current song LRC and preload adjacent
    _loadLrcForSong(_provider!.currentSongIndex);
    _preloadAdjacentLrc(_provider!.currentSongIndex);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read screen width once — ??= ensures it never runs again after first call
    if (_artSize == 0) {
      _artSize = MediaQuery.of(context).size.width - 104;
    }
  }

  @override
  void dispose() {
    _seekRepeatTimer?.cancel();
    _provider?.removeListener(_onProviderChange);
    _pageController.dispose();
    _smokeController.dispose();
    _isProgrammaticScroll.dispose();
    super.dispose();
  }

  // ── Provider listener ─────────────────────────────────────────────────────

  void _onProviderChange() {
    if (!mounted) return;

    // Sync smoke animation
    final isPlaying = _provider!.isPlaying;
    if (isPlaying && !_smokeController.isAnimating) {
      _smokeController.repeat();
    } else if (!isPlaying && _smokeController.isAnimating) {
      _smokeController.stop();
    }

    // Detect song change (auto-advance, shuffle, etc.)
    final newIndex = _provider!.currentSongIndex;
    if (newIndex != _lastKnownSongIndex) {
      _lastKnownSongIndex = newIndex;

      // Sync PageView artwork
      if (_pageController.hasClients) {
        _isProgrammaticScroll.value = true;
        _pageController
            .animateToPage(
              newIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            )
            .then((_) => Future.delayed(
                  const Duration(milliseconds: 50),
                  () => _isProgrammaticScroll.value = false,
                ));
      }

      // Load LRC for new song + preload neighbors
      _loadLrcForSong(newIndex);
      _preloadAdjacentLrc(newIndex);
    }
  }

  // ── LRC loading ───────────────────────────────────────────────────────────

  void _loadLrcForSong(int index) {
    if (_lrcData.containsKey(index)) return;
    final assetPath = 'assets/lrc/song_${index + 1}.lrc';
    DefaultAssetBundle.of(context).loadString(assetPath).then((content) {
      if (mounted) setState(() => _lrcData[index] = parseLrc(content));
    }).catchError((_) {
      if (mounted) setState(() => _lrcData[index] = []);
    });
  }

  // Preload next and previous song LRC so there's no gap on swipe
  void _preloadAdjacentLrc(int index) {
    final count = _provider!.playlist.length;
    _loadLrcForSong((index + 1) % count);
    _loadLrcForSong((index - 1 + count) % count);
  }

  // Fix #4: use dart:io File for real file paths, bytes for web/memory
  Future<void> _pickLrc(int songIndex) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['lrc'],
    );
    if (result == null || result.files.isEmpty) return;

    String? content;
    final bytes = result.files.first.bytes;
    final path = result.files.first.path;

    if (bytes != null) {
      content = String.fromCharCodes(bytes);
    } else if (path != null) {
      try {
        content = await File(path).readAsString();
      } catch (_) {
        content = null;
      }
    }

    if (content != null && content.isNotEmpty && mounted) {
      setState(() => _lrcData[songIndex] = parseLrc(content!));
    }
  }

  // ── View toggles ──────────────────────────────────────────────────────────

  void _toggleQueue() {
    setState(() {
      _showQueue = !_showQueue;
      if (_showQueue) _showLrc = false;
    });
  }

  void _toggleLrc() {
    final index = _provider!.currentSongIndex;
    // Ensure LRC data is loaded before opening (fallback for edge cases)
    if (!_lrcData.containsKey(index)) _loadLrcForSong(index);
    setState(() {
      _showLrc = !_showLrc;
      if (_showLrc) _showQueue = false;
    });
  }

  void _onSongChanged(int index) {
    _provider!.playFromPlaylist(index);
    _loadLrcForSong(index);
    _preloadAdjacentLrc(index);
  }

  // ── Repeating seek (long-press) ───────────────────────────────────────────

  void _startSeekRepeat(int seconds) {
    // Fire once immediately, then repeat every 500ms
    _provider!.seekBySeconds(seconds);
    _seekRepeatTimer?.cancel();
    _seekRepeatTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _provider!.seekBySeconds(seconds),
    );
  }

  void _stopSeekRepeat() {
    _seekRepeatTimer?.cancel();
    _seekRepeatTimer = null;
  }

  // ── Programmatic page navigation ─────────────────────────────────────────

  void _animateToPage(int index) {
    if (!_pageController.hasClients) return;
    _isProgrammaticScroll.value = true;
    _pageController
        .animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        )
        .then((_) => Future.delayed(
              const Duration(milliseconds: 50),
              () => _isProgrammaticScroll.value = false,
            ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              _buildSmokeBackground(provider),
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildAppBar(provider),
                    const SizedBox(height: 16),
                    _buildTopSection(provider),
                    const SizedBox(height: 20),
                    _buildSeekBar(provider),
                    const SizedBox(height: 20),
                    _buildControls(provider),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Smoke ─────────────────────────────────────────────────────────────────

  Widget _buildSmokeBackground(MusicProvider provider) {
    return AnimatedBuilder(
      animation: _smokeController,
      builder: (context, _) {
        return AnimatedOpacity(
          opacity: provider.isPlaying ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 800),
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: provider.currentPrimaryColor),
            duration: const Duration(milliseconds: 800),
            builder: (context, color, _) {
              return CustomPaint(
                painter: SmokePainter(
                  color: color ?? provider.currentPrimaryColor,
                  progress: _smokeController.value,
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ── AppBar — title switches to song title when lyrics are open ────────────

  Widget _buildAppBar(MusicProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, size: 28),
            onPressed: () {
              if (!widget.showQueue && _showQueue) {
                setState(() => _showQueue = false);
                Future.delayed(
                  const Duration(milliseconds: 150),
                  () => Navigator.of(context).pop(),
                );
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _showLrc
                    ? provider.currentSongTitle
                    : provider.isPlaying
                        ? 'Now Playing'
                        : 'Paused',
                key: ValueKey(_showLrc
                    ? 'song'
                    : provider.isPlaying
                        ? 'playing'
                        : 'paused'),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: _showLrc ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: _showLrc || provider.isPlaying
                      ? Colors.white
                      : Colors.grey,
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            color: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (_) {},
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'add_playlist',
                child: Row(children: [
                  Icon(Icons.playlist_add, size: 20, color: Colors.white70),
                  SizedBox(width: 12),
                  Text('Add to playlist'),
                ]),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(children: [
                  Icon(Icons.share, size: 20, color: Colors.white70),
                  SizedBox(width: 12),
                  Text('Share'),
                ]),
              ),
              PopupMenuItem(
                value: 'sleep_timer',
                child: Row(children: [
                  Icon(Icons.bedtime_outlined, size: 20, color: Colors.white70),
                  SizedBox(width: 12),
                  Text('Sleep timer'),
                ]),
              ),
              PopupMenuItem(
                value: 'equalizer',
                child: Row(children: [
                  Icon(Icons.equalizer, size: 20, color: Colors.white70),
                  SizedBox(width: 12),
                  Text('Equalizer'),
                ]),
              ),
              PopupMenuItem(
                value: 'song_info',
                child: Row(children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.white70),
                  SizedBox(width: 12),
                  Text('Song info'),
                ]),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                  SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: Colors.redAccent)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Top section ───────────────────────────────────────────────────────────

  Widget _buildTopSection(MusicProvider provider) {
    return SizedBox(
      height: 440,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 120),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: _showQueue
            ? const QueueView()
            : _showLrc
                ? LrcView(
                    lines: _lrcData[provider.currentSongIndex],
                    onPickLrc: () => _pickLrc(provider.currentSongIndex),
                  )
                : MusicInfoView(
                    pageController: _pageController,
                    onTapArtwork: _toggleLrc,
                    onSongChanged: _onSongChanged,
                    isProgrammaticScroll: _isProgrammaticScroll,
                    artSize: _artSize,
                  ),
      ),
    );
  }

  // ── Seek bar ──────────────────────────────────────────────────────────────

  Widget _buildSeekBar(MusicProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Slider(
            value: _isDragging ? _dragValue : provider.progressValue,
            activeColor: provider.currentPrimaryColor,
            onChanged: (value) {
              setState(() {
                _isDragging = true;
                _dragValue = value;
              });
            },
            onChangeEnd: (value) {
              provider.seekTo(value);
              setState(() => _isDragging = false);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isDragging
                      ? _formatDuration(Duration(
                          milliseconds: (_dragValue *
                                  provider.totalDuration.inMilliseconds)
                              .round()))
                      : provider.currentTimeFormatted,
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  provider.totalTimeFormatted,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Controls ──────────────────────────────────────────────────────────────

  Widget _buildControls(MusicProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mode cycle
          IconButton(
            icon: Icon(
              _getModeIcon(provider.playMode),
              size: 26,
              color: _getModeColor(provider.playMode, provider.currentPrimaryColor),
            ),
            onPressed: () => provider.cycleMode(),
          ),

          // Previous — tap: skip, long-press: repeat -5s every 500ms
          GestureDetector(
            onTap: () => provider.previousSong(),
            onLongPressStart: (_) => _startSeekRepeat(-5),
            onLongPressEnd: (_) => _stopSeekRepeat(),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.skip_previous, size: 32),
            ),
          ),

          // Play / pause
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: IconButton(
              icon: Icon(
                provider.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.black,
                size: 32,
              ),
              onPressed: () => provider.playPause(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ),

          // Next — tap: skip, long-press: repeat +5s every 500ms
          GestureDetector(
            onTap: () => provider.nextSong(),
            onLongPressStart: (_) => _startSeekRepeat(5),
            onLongPressEnd: (_) => _stopSeekRepeat(),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.skip_next, size: 32),
            ),
          ),

          // Queue / LRC toggle
          _showLrc
              ? IconButton(
                  icon: const Icon(Icons.lyrics, size: 26),
                  color: provider.currentPrimaryColor,
                  onPressed: _toggleLrc,
                )
              : IconButton(
                  icon: Icon(
                    Icons.queue_music,
                    size: 26,
                    color: _showQueue ? provider.currentPrimaryColor : Colors.white,
                  ),
                  onPressed: _toggleQueue,
                ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  IconData _getModeIcon(int mode) {
    switch (mode) {
      case 1: return Icons.repeat;
      case 2: return Icons.repeat_one;
      case 3: return Icons.shuffle;
      default: return Icons.repeat;
    }
  }

  Color _getModeColor(int mode, Color accent) =>
      mode == 0 ? Colors.white : accent;

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }
}