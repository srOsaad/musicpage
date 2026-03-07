import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/music_provider.dart';

class QueueView extends StatelessWidget {
  const QueueView({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<MusicProvider, ({int currentIndex, int playlistLength})>(
      selector: (_, p) => (
        currentIndex: p.currentSongIndex,
        playlistLength: p.playlist.length,
      ),
      builder: (context, data, _) {
        final provider = Provider.of<MusicProvider>(context, listen: false);

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
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Up Next',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: provider.playlist.length,
                  buildDefaultDragHandles: false,
                  onReorder: (oldIndex, newIndex) =>
                      provider.reorderPlaylist(oldIndex, newIndex),
                  proxyDecorator: (child, index, animation) => Material(
                    color: Colors.transparent,
                    elevation: 0,
                    child: child,
                  ),
                  itemBuilder: (context, index) {
                    final song = provider.playlist[index];
                    final isCurrent = index == data.currentIndex;

                    return GestureDetector(
                      key: ValueKey(song['title']),
                      onTap: () => provider.playFromPlaylist(index),
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            // Album art
                            CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  (song['primaryColor'] as Color).withOpacity(0.5),
                              backgroundImage: song['imagePath'].isNotEmpty
                                  ? AssetImage(song['imagePath']) as ImageProvider
                                  : null,
                              child: song['imagePath'].isEmpty
                                  ? const Icon(Icons.music_note,
                                      size: 16, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            // Title + artist
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    song['title'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isCurrent
                                          ? (song['primaryColor'] as Color)
                                          : Colors.white,
                                    ),
                                  ),
                                  Text(
                                    song['artist'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Drag handle
                            ReorderableDragStartListener(
                              index: index,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(
                                  Icons.drag_handle,
                                  color: Colors.white38,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}