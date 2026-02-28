import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dummy Music Page',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        sliderTheme: const SliderThemeData(
          thumbColor: Colors.white,
          activeTrackColor: Colors.white,
          inactiveTrackColor: Colors.grey,
        ),
      ),
      home: const MusicPage(),
    );
  }
}

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  // Shuffle/repeat modes
  int _modeIndex = 0; // 0: shuffle, 1: repeat, 2: repeat_one
  final List<IconData> _modeIcons = [
    Icons.shuffle,
    Icons.repeat,
    Icons.repeat_one,
  ];

  // Favorite state
  bool _isFavorited = false;

  // Queue visibility
  bool _showQueue = false;

  void _toggleMode() {
    setState(() {
      _modeIndex = (_modeIndex + 1) % _modeIcons.length;
    });
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorited = !_isFavorited;
    });
  }

  void _toggleQueue() {
    setState(() {
      _showQueue = !_showQueue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {},
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Animated top section (fixed height)
            SizedBox(
              height:
                  440, // Enough to contain either the music info or the playlist
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: _showQueue ? _buildQueueList() : _buildMusicInfo(),
              ),
            ),
            const SizedBox(height: 20),
            // Seekbar and time labels (always visible)
            Slider(value: 0.4, padding: const EdgeInsets.symmetric(vertical: 20), onChanged: (value) {}),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1:24', style: TextStyle(fontSize: 12)),
                Text('3:45', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 20),
            // Playback controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Merged shuffle/repeat (three modes)
                IconButton(
                  icon: Icon(_modeIcons[_modeIndex], size: 26),
                  onPressed: _toggleMode,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous, size: 32),
                  onPressed: () {},
                ),
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.play_arrow,
                      color: Colors.black,
                      size: 32,
                    ),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, size: 32),
                  onPressed: () {},
                ),
                // Queue button (toggles animated view)
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
          ],
        ),
      ),
    );
  }

  // Widget for the main music info (album art, title, artist, favorite)
  Widget _buildMusicInfo() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Album art
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Colors.purple, Colors.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.music_note,
              size: 120,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 20),
          // Song title and artist
          const Text(
            'Song Title',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Artist Name',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          // Favorite button (toggles between outline and filled)
          IconButton(
            icon: Icon(
              _isFavorited ? Icons.favorite : Icons.favorite_border,
              color: _isFavorited ? Colors.red : Colors.white70,
              size: 28,
            ),
            onPressed: _toggleFavorite,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // Dummy playlist that replaces the music info
  Widget _buildQueueList() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white10,
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
              itemCount: 6,
              itemBuilder: (context, index) => ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      Colors.primaries[index % Colors.primaries.length],
                  child: const Icon(
                    Icons.music_note,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                title: Text('Song ${index + 1}'),
                subtitle: Text('Artist ${index + 1}'),
                trailing: const Icon(
                  Icons.play_arrow,
                  size: 20,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
