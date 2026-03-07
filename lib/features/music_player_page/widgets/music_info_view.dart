import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/music_provider.dart';

class MusicInfoView extends StatefulWidget {
  final PageController pageController;
  final VoidCallback onTapArtwork;
  final void Function(int index) onSongChanged;
  final ValueNotifier<bool> isProgrammaticScroll;
  final double artSize;

  const MusicInfoView({
    super.key,
    required this.pageController,
    required this.onTapArtwork,
    required this.onSongChanged,
    required this.isProgrammaticScroll,
    required this.artSize,
  });

  @override
  State<MusicInfoView> createState() => _MusicInfoViewState();
}

class _MusicInfoViewState extends State<MusicInfoView> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MusicProvider>(context);
    final artSize = widget.artSize;

    return Center(
      key: const ValueKey('music_info'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            height: artSize,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                final p = Provider.of<MusicProvider>(context, listen: false);
                if (notification is ScrollEndNotification) {
                  if (widget.isProgrammaticScroll.value) return false;
                  final index = widget.pageController.page!.round();
                  if (index != p.currentSongIndex) {
                    p.pause();
                    Future.delayed(const Duration(milliseconds: 300), () {
                      widget.onSongChanged(index);
                    });
                  }
                  // Do NOT resume here — if user was paused and swipes
                  // back to the same song it would start playback unexpectedly
                }
                return false;
              },
              child: PageView.builder(
                controller: widget.pageController,
                itemCount: provider.playlist.length,
                itemBuilder: (context, index) {
                  final song = provider.playlist[index];
                  final artwork = Center(
                    child: SizedBox(
                      width: artSize,
                      height: artSize,
                      child: GestureDetector(
                        onTap: widget.onTapArtwork,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white24,
                              width: 1.5,
                            ),
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
                                    width: artSize,
                                    height: artSize,
                                  ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: MarqueeText(
              text: provider.currentSongTitle,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              key: ValueKey(provider.currentSongTitle),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: MarqueeText(
              text: provider.currentArtistName,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
              key: ValueKey(provider.currentArtistName),
            ),
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
}

/// Scrolls text horizontally when it overflows, stays still when it fits.
/// Uses LayoutBuilder to get the exact container width, so scroll distances
/// are always correct regardless of the spacer or scroll content size.
class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const MarqueeText({required Key key, required this.text, required this.style})
      : super(key: key);

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  final ScrollController _scroll = ScrollController();
  bool _running = false;
  // Container width captured by LayoutBuilder before scroll starts
  double _containerWidth = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStart());
  }

  @override
  void dispose() {
    _running = false;
    _scroll.dispose();
    super.dispose();
  }

  double _measureTextWidth() {
    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: double.infinity);
    return painter.width;
  }

  Future<void> _maybeStart() async {
    if (!mounted) return;

    // Wait one more frame so LayoutBuilder has set _containerWidth
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    final textWidth  = _measureTextWidth();
    // overflow = how many pixels past the right edge the text extends
    final overflow   = textWidth - _containerWidth;

    if (overflow <= 0) return; // fits — nothing to do

    _running = true;

    // Hold still so the user can read the start
    await Future.delayed(const Duration(milliseconds: 1500));

    while (_running && mounted) {
      // scrollTarget: move text fully past the right edge
      //   overflow  → last character reaches right edge
      //   + _containerWidth → entire text is off screen
      final scrollTarget = overflow + _containerWidth;

      await _scroll.animateTo(
        scrollTarget,
        duration: Duration(milliseconds: (scrollTarget * 18).round()),
        curve: Curves.linear,
      );

      if (!mounted) break;

      // Hold at end so it doesn't feel rushed
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) break;

      // Jump back — text is off screen so the reset is invisible
      _scroll.jumpTo(0);

      // Hold at start before next pass
      await Future.delayed(const Duration(milliseconds: 1500));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _containerWidth = constraints.maxWidth;
        final textWidth = _measureTextWidth();
        final overflows = textWidth > _containerWidth;

        // Short text — just center it, no scrolling needed
        if (!overflows) {
          return SizedBox(
            width: _containerWidth,
            child: Text(
              widget.text,
              style: widget.style,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          );
        }

        // Faded edges + scrolling marquee
        return ShaderMask(
          shaderCallback: (Rect bounds) => LinearGradient(
            colors: const [
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
            stops: const [0.0, 0.08, 0.92, 1.0],
          ).createShader(bounds),
          blendMode: BlendMode.dstIn,
          child: SingleChildScrollView(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: [
                // Small gap so the first character clears the left fade zone
                const SizedBox(width: 14),
                Text(widget.text, style: widget.style, maxLines: 1),
                // Spacer must be >= _containerWidth so scrollTarget is reachable
                SizedBox(width: _containerWidth + 100),
              ],
            ),
          ),
        );
      },
    );
  }
}