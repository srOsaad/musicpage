import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/music_provider.dart';
import '../music_player_page/music_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(child: _buildPlaylist(context)),
          // Fix #9: single Consumer here, no outer Consumer in build
          _buildMiniPlayer(context),
        ],
      ),
    );
  }

  // ── Playlist ───────────────────────────────────────────────────────────────

  Widget _buildPlaylist(BuildContext context) {
    // Fix #5: Selector scoped to only the fields the list actually needs.
    // This prevents a full list rebuild every timer tick.
    return Selector<MusicProvider, ({int currentIndex, String currentTime})>(
      selector: (_, p) => (
        currentIndex: p.currentSongIndex,
        currentTime: p.currentTimeFormatted,
      ),
      builder: (context, data, _) {
        final provider = Provider.of<MusicProvider>(context, listen: false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Playlist',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: provider.playlist.length,
                itemBuilder: (context, index) {
                  final song = provider.playlist[index];
                  final isCurrent = index == data.currentIndex;

                  return ListTile(
                    leading: Hero(
                      tag: 'playlist_image_$index',
                      child: CircleAvatar(
                        radius: 20,
                        // Fix #7: show album art when available,
                        // gradient only as background (no opaque child on top)
                        backgroundColor:
                            (song['primaryColor'] as Color).withOpacity(0.6),
                        backgroundImage: song['imagePath'].isNotEmpty
                            ? AssetImage(song['imagePath']) as ImageProvider
                            : null,
                        child: song['imagePath'].isEmpty
                            ? Text(
                                '${index + 1}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.white),
                              )
                            : isCurrent
                                ? Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black.withOpacity(0.45),
                                    ),
                                    child: const Icon(Icons.play_arrow,
                                        size: 16, color: Colors.white),
                                  )
                                : null,
                      ),
                    ),
                    title: Text(
                      song['title'],
                      style: TextStyle(
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? (song['primaryColor'] as Color) : Colors.white,
                      ),
                    ),
                    subtitle: Text(song['artist']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCurrent)
                          Text(
                            data.currentTime,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        const SizedBox(width: 8),
                        Icon(
                          song['favorited']
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 16,
                          color:
                              song['favorited'] ? Colors.red : Colors.grey,
                        ),
                      ],
                    ),
                    onTap: () => provider.playFromPlaylist(index),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _openPlayer(BuildContext context, {bool showQueue = false}) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration:
            Duration(milliseconds: showQueue ? 250 : 350),
        reverseTransitionDuration:
            Duration(milliseconds: showQueue ? 250 : 350),
        pageBuilder: (context, animation, secondaryAnimation) =>
            MusicPage(showQueue: showQueue),
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) {
          if (showQueue) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: child,
            );
          }
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  // ── Mini player ────────────────────────────────────────────────────────────

  Widget _buildMiniPlayer(BuildContext context) {
    // Fix #9: single Consumer — no redundant outer wrapper
    return Consumer<MusicProvider>(
      builder: (context, provider, _) {
        return Container(
          height: 80,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                // Fix #8: use song accent colour instead of hardcoded purple
                color: provider.currentPrimaryColor.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: provider.progressValue,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(
                  provider.currentPrimaryColor,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // LEFT: art + text — tapping opens player
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _openPlayer(context),
                        child: Row(
                          children: [
                            Hero(
                              tag: 'music_page_hero',
                              createRectTween: (begin, end) =>
                                  RectTween(begin: begin, end: end),
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[850],
                                  image: provider.currentImagePath.isNotEmpty
                                      ? DecorationImage(
                                          image: AssetImage(
                                              provider.currentImagePath),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: provider.currentPrimaryColor
                                          .withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: provider.currentImagePath.isEmpty
                                    ? const Icon(Icons.music_note,
                                        color: Colors.white54, size: 24)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Fix #10: Flexible replaces fixed 120px width
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 160),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    provider.currentSongTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    provider.currentArtistName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${provider.currentTimeFormatted} / ${provider.totalTimeFormatted}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // RIGHT: controls
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.skip_previous, size: 22),
                        onPressed: () => provider.previousSong(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Container(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 4),
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
                            size: 22,
                          ),
                          onPressed: () => provider.playPause(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next, size: 22),
                        onPressed: () => provider.nextSong(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.queue_music, size: 22),
                        onPressed: () =>
                            _openPlayer(context, showQueue: true),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}