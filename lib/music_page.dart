import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'music_provider.dart';

class MusicPage extends StatefulWidget {
  final bool showQueue;
  const MusicPage({super.key, this.showQueue = false});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage>
    with SingleTickerProviderStateMixin {
  late bool _showQueue;
  bool _isDragging = false;
  double _dragValue = 0.0;
  late PageController _pageController;
  late AnimationController _smokeController;

  @override
  void initState() {
    super.initState();
    _showQueue = widget.showQueue;
    final provider = Provider.of<MusicProvider>(context, listen: false);
    _pageController = PageController(initialPage: provider.currentSongIndex);

    _smokeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _smokeController.dispose();
    super.dispose();
  }

  void _toggleQueue() {
    setState(() {
      _showQueue = !_showQueue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Smoke background
              TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: provider.currentPrimaryColor),
                duration: const Duration(milliseconds: 800),
                builder: (context, color, _) {
                  return AnimatedBuilder(
                    animation: _smokeController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _SmokePainter(
                          color: color ?? provider.currentPrimaryColor,
                          progress: _smokeController.value,
                        ),
                      );
                    },
                  );
                },
              ),
              // Page content on top
              SafeArea(
                child: Column(
                  children: [
                    // AppBar
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              size: 28,
                            ),
                            onPressed: () {
                              if (!widget.showQueue && _showQueue) {
                                // Opened normally but queue is visible —
                                // snap queue closed then use normal route reverse
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
                          const Text(
                            'Now Playing',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Animated top section
                    SizedBox(
                      height: 440,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 120),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                        child: _showQueue
                            ? _buildQueueList(provider)
                            : _buildMusicInfo(provider),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Seekbar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        children: [
                          Slider(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            value: _isDragging
                                ? _dragValue
                                : provider.progressValue,
                            activeColor: provider.currentPrimaryColor,
                            onChanged: (value) {
                              setState(() {
                                _isDragging = true;
                                _dragValue = value;
                              });
                            },
                            onChangeEnd: (value) {
                              provider.seekTo(value);
                              setState(() {
                                _isDragging = false;
                              });
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _isDragging
                                    ? _formatDuration(
                                        Duration(
                                          seconds:
                                              (_dragValue *
                                                      provider
                                                          .totalDuration
                                                          .inSeconds)
                                                  .round(),
                                        ),
                                      )
                                    : provider.currentTimeFormatted,
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                provider.totalTimeFormatted,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Playback controls
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(
                              _getModeIcon(provider.playMode),
                              size: 26,
                              color: _getModeColor(provider.playMode),
                            ),
                            onPressed: () => provider.cycleMode(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_previous, size: 32),
                            onPressed: () {
                              provider.previousSong();
                              if (_pageController.hasClients) {
                                _pageController.animateToPage(
                                  provider.currentSongIndex,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: IconButton(
                              icon: Icon(
                                provider.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.black,
                                size: 32,
                              ),
                              onPressed: () => provider.playPause(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next, size: 32),
                            onPressed: () {
                              provider.nextSong();
                              if (_pageController.hasClients) {
                                _pageController.animateToPage(
                                  provider.currentSongIndex,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.queue_music,
                              size: 26,
                              color: _showQueue ? Colors.blue : Colors.white,
                            ),
                            onPressed: _toggleQueue,
                          ),
                        ],
                      ),
                    ),
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

  // 0=off, 1=repeat all, 2=repeat one, 3=shuffle
  IconData _getModeIcon(int playMode) {
    switch (playMode) {
      case 1:
        return Icons.repeat;
      case 2:
        return Icons.repeat_one;
      case 3:
        return Icons.shuffle;
      default:
        return Icons.repeat;
    }
  }

  Color _getModeColor(int playMode) {
    return playMode == 0 ? Colors.white : Colors.blue;
  }

  Widget _buildMusicInfo(MusicProvider provider) {
    return Center(
      key: const ValueKey('music_info'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            height: 280,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                final p = Provider.of<MusicProvider>(context, listen: false);
                if (notification is ScrollEndNotification) {
                  final index = _pageController.page!.round();
                  if (index != p.currentSongIndex) {
                    p.pause();
                    Future.delayed(const Duration(milliseconds: 300), () {
                      p.playFromPlaylist(index);
                    });
                  } else {
                    p.resume();
                  }
                }
                return false;
              },
              child: PageView.builder(
                controller: _pageController,
                itemCount: provider.playlist.length,
                itemBuilder: (context, index) {
                  final song = provider.playlist[index];
                  final artwork = Center(
                    child: SizedBox(
                      width: 280,
                      height: 280,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24, width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: song['imagePath'].isEmpty
                              ? const Center(
                                  child: Icon(
                                    Icons.music_note,
                                    size: 80,
                                    color: Colors.white24,
                                  ),
                                )
                              : Image(
                                  image: AssetImage(song['imagePath']),
                                  fit: BoxFit.contain,
                                  width: 280,
                                  height: 280,
                                ),
                        ),
                      ),
                    ),
                  );
                  return index == provider.currentSongIndex
                      ? Hero(tag: 'music_page_hero', child: artwork)
                      : artwork;
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            provider.currentSongTitle,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            provider.currentArtistName,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          IconButton(
            icon: Icon(
              provider.isFavorited ? Icons.favorite : Icons.favorite_border,
              color: provider.isFavorited ? Colors.red : Colors.white70,
              size: 28,
            ),
            onPressed: () => provider.toggleFavorite(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueList(MusicProvider provider) {
    return Container(
      key: const ValueKey('queue'),
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Up Next',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: provider.playlist.length,
              itemBuilder: (context, index) {
                final song = provider.playlist[index];
                final isCurrent = index == provider.currentSongIndex;

                return ListTile(
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundImage: song['imagePath'].isEmpty
                        ? null
                        : AssetImage(song['imagePath']) as ImageProvider,
                    backgroundColor: (song['primaryColor'] as Color)
                        .withOpacity(0.5),
                    child: song['imagePath'].isEmpty
                        ? const Icon(
                            Icons.music_note,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  title: Text(
                    song['title'],
                    style: TextStyle(
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isCurrent ? Colors.blue : Colors.white,
                    ),
                  ),
                  subtitle: Text(song['artist']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCurrent)
                        Text(
                          provider.currentTimeFormatted,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        song['favorited']
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 16,
                        color: song['favorited'] ? Colors.red : Colors.grey,
                      ),
                    ],
                  ),
                  onTap: () {
                    Provider.of<MusicProvider>(
                      context,
                      listen: false,
                    ).playFromPlaylist(index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

class _SmokePainter extends CustomPainter {
  final Color color;
  final double progress;

  _SmokePainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.screen;

    // Draw several drifting blobs at different phases
    final blobs = [
      _BlobConfig(phaseOffset: 0.0, xFactor: 0.3, yStart: 0.9, radius: 180),
      _BlobConfig(phaseOffset: 0.25, xFactor: 0.7, yStart: 0.85, radius: 150),
      _BlobConfig(phaseOffset: 0.5, xFactor: 0.5, yStart: 1.0, radius: 200),
      _BlobConfig(phaseOffset: 0.15, xFactor: 0.15, yStart: 0.95, radius: 130),
      _BlobConfig(phaseOffset: 0.65, xFactor: 0.85, yStart: 1.0, radius: 160),
    ];

    for (final blob in blobs) {
      final t = (progress + blob.phaseOffset) % 1.0;

      // Each blob drifts upward and sways side to side
      final y = size.height * (blob.yStart - t * 1.2);
      final sway = sin(t * pi * 2 + blob.phaseOffset * pi) * size.width * 0.12;
      final x = size.width * blob.xFactor + sway;

      // Fade in from bottom, fade out near top
      final opacity = (sin(t * pi) * 0.18).clamp(0.0, 0.18);

      paint.shader =
          RadialGradient(
            colors: [color.withOpacity(opacity), color.withOpacity(0)],
          ).createShader(
            Rect.fromCircle(
              center: Offset(x, y),
              radius: blob.radius.toDouble(),
            ),
          );

      canvas.drawCircle(Offset(x, y), blob.radius.toDouble(), paint);
    }
  }

  @override
  bool shouldRepaint(_SmokePainter old) =>
      old.progress != progress || old.color != color;
}

class _BlobConfig {
  final double phaseOffset;
  final double xFactor;
  final double yStart;
  final int radius;

  const _BlobConfig({
    required this.phaseOffset,
    required this.xFactor,
    required this.yStart,
    required this.radius,
  });
}
