import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'music_page.dart';
import 'music_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(child: _buildPlaylist(context)),
          // Mini player
          Consumer<MusicProvider>(
            builder: (context, provider, child) {
              return _buildMiniPlayer(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylist(BuildContext context) {
    final provider = Provider.of<MusicProvider>(context);

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
              final isCurrent = index == provider.currentSongIndex;

              return ListTile(
                leading: Hero(
                  tag: 'playlist_image_$index',
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: AssetImage(song['imagePath']),
                    backgroundColor: Colors.transparent,
                    onBackgroundImageError: (_, __) {
                      // Fallback if image fails to load
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            song['primaryColor'],
                            song['secondaryColor'],
                          ],
                        ),
                      ),
                      child: Center(
                        child: isCurrent
                            ? const Icon(
                                Icons.play_arrow,
                                size: 16,
                                color: Colors.white,
                              )
                            : Text(
                                '${index + 1}',
                                style: const TextStyle(fontSize: 12),
                              ),
                      ),
                    ),
                  ),
                ),
                title: Text(
                  song['title'],
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
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
                          fontSize: 12,
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
                  provider.playFromPlaylist(index);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMiniPlayer(BuildContext context) {
    final provider = Provider.of<MusicProvider>(context, listen: false);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 350),
            pageBuilder: (context, animation, secondaryAnimation) =>
                const MusicPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
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
      },
      child: Container(
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
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Consumer<MusicProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                // Mini progress bar
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
                        Hero(
                          tag: 'music_page_hero',
                          createRectTween: (Rect? begin, Rect? end) {
                            return RectTween(begin: begin, end: end);
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: AssetImage(provider.currentImagePath),
                                fit: BoxFit.cover,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: provider.currentPrimaryColor
                                      .withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.currentSongTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.skip_previous, size: 22),
                              onPressed: () => provider.previousSong(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
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
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    transitionDuration: const Duration(
                                      milliseconds: 250,
                                    ),
                                    reverseTransitionDuration: const Duration(
                                      milliseconds: 250,
                                    ),
                                    pageBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) => const MusicPage(showQueue: true),
                                    transitionsBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                          child,
                                        ) {
                                          return SlideTransition(
                                            position:
                                                Tween<Offset>(
                                                  begin: const Offset(0, 1),
                                                  end: Offset.zero,
                                                ).animate(
                                                  CurvedAnimation(
                                                    parent: animation,
                                                    curve: Curves.easeOut,
                                                  ),
                                                ),
                                            child: child,
                                          );
                                        },
                                  ),
                                );
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
