import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/music_provider.dart';
import '../../../utils/lrc_parser.dart';

class LrcView extends StatefulWidget {
  final List<LrcLine>? lines;
  final VoidCallback onPickLrc;

  const LrcView({
    super.key,
    required this.lines,
    required this.onPickLrc,
  });

  @override
  State<LrcView> createState() => _LrcViewState();
}

class _LrcViewState extends State<LrcView> {
  final ScrollController _scrollController = ScrollController();

  // One key per line — always valid because we use ListView (not .builder),
  // so every item is always in the widget tree and its context is never null.
  List<GlobalKey> _keys = [];

  int _lastScrolledIndex = -1;
  bool _initialScrollDone = false;

  @override
  void initState() {
    super.initState();
    _buildKeys();
  }

  @override
  void didUpdateWidget(LrcView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Song changed — rebuild keys and reset scroll state
    if (oldWidget.lines != widget.lines) {
      _buildKeys();
      _lastScrolledIndex = -1;
      _initialScrollDone = false;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _buildKeys() {
    _keys = List.generate(
      widget.lines?.length ?? 0,
      (_) => GlobalKey(),
    );
  }

  /// Scrolls [index] to the vertical center of the viewport.
  /// [instant] = true  → Duration.zero  (used when opening lyrics)
  /// [instant] = false → 500ms animated (used during playback advance)
  void _scrollTo(int index, {required bool instant}) {
    if (index < 0 || index >= _keys.length) return;
    final ctx = _keys[index].currentContext;
    if (ctx == null) return; // should never happen with full ListView

    _lastScrolledIndex = index;

    Scrollable.ensureVisible(
      ctx,
      alignment: 0.5, // center in viewport
      duration: instant ? Duration.zero : const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MusicProvider>(context);
    final position = provider.currentPosition;

    // ── No-lyrics state ────────────────────────────────────────────────────
    if (widget.lines == null || widget.lines!.isEmpty) {
      return SizedBox(
        key: const ValueKey('lrc_empty'),
        width: double.infinity,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lyrics_outlined, size: 48, color: Colors.white24),
              const SizedBox(height: 16),
              const Text(
                'No Lyrics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No lyrics available for this song',
                style: TextStyle(fontSize: 13, color: Colors.white38),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: widget.onPickLrc,
                icon: const Icon(Icons.folder_open, size: 18),
                label: const Text('Select LRC File'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Active line ────────────────────────────────────────────────────────
    final activeLine = getCurrentLine(widget.lines!, position);
    // If nothing has played yet, highlight line 0 so the list starts centered
    final activeIndex = activeLine != null
        ? widget.lines!.indexOf(activeLine)
        : 0;

    // Schedule scroll after this frame so the layout is always committed first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (!_initialScrollDone) {
        // Opening lyrics: jump instantly to wherever the song currently is
        _scrollTo(activeIndex, instant: true);
        _initialScrollDone = true;
      } else if (activeIndex != _lastScrolledIndex) {
        // Playback advanced to a new line: smooth animation
        _scrollTo(activeIndex, instant: false);
      }
    });

    // ── Layout ─────────────────────────────────────────────────────────────
    final viewportHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      key: const ValueKey('lrc_list'),
      width: double.infinity,
      child: ShaderMask(
        // Fade top and bottom edges so the list feels infinite
        shaderCallback: (Rect bounds) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [0.0, 0.13, 0.87, 1.0],
        ).createShader(bounds),
        blendMode: BlendMode.dstIn,
        child: SingleChildScrollView(
          controller: _scrollController,
          // Half-viewport padding top and bottom so the first and last lines
          // can reach the center on every screen size
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: viewportHeight * 0.44,
          ),
          // ── Full ListView (not .builder) ──────────────────────────────
          // All items are always in the tree, so GlobalKey contexts are
          // guaranteed non-null — ensureVisible always works on first try.
          child: Column(
            children: List.generate(widget.lines!.length, (i) {
              final line = widget.lines![i];
              final isActive = i == activeIndex;

              return GestureDetector(
                key: _keys[i],
                onTap: () => provider.seekToDuration(line.timestamp),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: isActive
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glow layer — blurred copy behind the text
                            Text(
                              line.text,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                foreground: Paint()
                                  ..color = Colors.white.withOpacity(0.6)
                                  ..maskFilter = const MaskFilter.blur(
                                      BlurStyle.normal, 8),
                                height: 1.6,
                              ),
                            ),
                            // Crisp text on top
                            Text(
                              line.text,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                height: 1.6,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          line.text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white38,
                            fontWeight: FontWeight.normal,
                            height: 1.6,
                          ),
                        ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}