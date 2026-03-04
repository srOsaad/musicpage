import 'dart:async';
import 'package:flutter/material.dart';

class MusicProvider extends ChangeNotifier {
  // Sample playlist with dummy image paths
  final List<Map<String, dynamic>> _playlist = [
    {
      'title': 'Bohemian Rhapsody',
      'artist': 'Queen',
      'duration': const Duration(minutes: 5, seconds: 55),
      'favorited': false,
      'imagePath': 'assets/images/album_1.jpg',
      'primaryColor': Colors.purple,
      'secondaryColor': Colors.pink,
    },
    {
      'title': 'Shape of You',
      'artist': 'Ed Sheeran',
      'duration': const Duration(minutes: 4, seconds: 23),
      'favorited': true,
      'imagePath': 'assets/images/album_2.jpg',
      'primaryColor': Colors.blue,
      'secondaryColor': Colors.lightBlue,
    },
    {
      'title': 'Blinding Lights',
      'artist': 'The Weeknd',
      'duration': const Duration(minutes: 3, seconds: 20),
      'favorited': false,
      'imagePath': 'assets/images/album_3.jpg',
      'primaryColor': Colors.teal,
      'secondaryColor': Colors.green,
    },
    {
      'title': 'Rolling in the Deep',
      'artist': 'Adele',
      'duration': const Duration(minutes: 3, seconds: 48),
      'favorited': true,
      'imagePath': 'assets/images/album_4.jpg',
      'primaryColor': Colors.orange,
      'secondaryColor': Colors.deepOrange,
    },
    {
      'title': 'Hotel California',
      'artist': 'Eagles',
      'duration': const Duration(minutes: 6, seconds: 30),
      'favorited': false,
      'imagePath': 'assets/images/album_5.jpg',
      'primaryColor': Colors.pink,
      'secondaryColor': Colors.purple,
    },
    {
      'title': 'Imagine',
      'artist': 'John Lennon',
      'duration': const Duration(minutes: 3, seconds: 4),
      'favorited': true,
      'imagePath': 'assets/images/album_6.jpg',
      'primaryColor': Colors.indigo,
      'secondaryColor': Colors.blue,
    },
    {
      'title': 'Stairway to Heaven',
      'artist': 'Led Zeppelin',
      'duration': const Duration(minutes: 8, seconds: 2),
      'favorited': false,
      'imagePath': '',
      'primaryColor': Colors.brown,
      'secondaryColor': Colors.orange,
    },
  ];

  int _currentSongIndex = 0;
  bool _isFavorited = false;
  Duration _currentPosition = const Duration(minutes: 1, seconds: 24);
  bool _isPlaying = false;

  // Timer for updating position
  Timer? _positionTimer;

  // Getters
  String get currentSongTitle => _playlist[_currentSongIndex]['title'];
  String get currentArtistName => _playlist[_currentSongIndex]['artist'];
  bool get isFavorited => _isFavorited;
  Duration get totalDuration => _playlist[_currentSongIndex]['duration'];
  Duration get currentPosition => _currentPosition;
  bool get isPlaying => _isPlaying;
  List<Map<String, dynamic>> get playlist => _playlist;
  int get currentSongIndex => _currentSongIndex;
  String get currentImagePath => _playlist[_currentSongIndex]['imagePath'];
  Color get currentPrimaryColor => _playlist[_currentSongIndex]['primaryColor'];
  Color get currentSecondaryColor =>
      _playlist[_currentSongIndex]['secondaryColor'];

  // Progress as double (0.0 to 1.0)
  double get progressValue {
    if (totalDuration.inSeconds == 0) return 0.0;
    return _currentPosition.inSeconds / totalDuration.inSeconds;
  }

  // Formatted time strings
  String get currentTimeFormatted => _formatDuration(_currentPosition);
  String get totalTimeFormatted => _formatDuration(totalDuration);

  MusicProvider() {
    // Load first song
    _loadSongByIndex(0);
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  // Timer management
  void _startTimer() {
    _stopTimer();
    _positionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPlaying) {
        _updatePosition();
      }
    });
  }

  void _stopTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  void _updatePosition() {
    if (_currentPosition < totalDuration) {
      _currentPosition = Duration(seconds: _currentPosition.inSeconds + 1);
      notifyListeners();

      // Check if song ended
      if (_currentPosition >= totalDuration) {
        _onSongComplete();
      }
    }
  }

  void _onSongComplete() {
    switch (repeatMode) {
      case 2: // Repeat one
        _currentPosition = Duration.zero;
        notifyListeners();
        break;
      case 1: // Repeat all
        nextSong();
        break;
      default: // No repeat
        if (_currentSongIndex < _playlist.length - 1) {
          nextSong();
        } else {
          _isPlaying = false;
          _stopTimer();
          notifyListeners();
        }
    }
  }

  void _loadSongByIndex(int index) {
    if (index >= 0 && index < _playlist.length) {
      _currentSongIndex = index;
      _isFavorited = _playlist[index]['favorited'] ?? false;
      _currentPosition = Duration.zero;
      notifyListeners();

      // Update notification here (in real app)
      _updateNotification();
    }
  }

  // Play controls
  void pause() {
    if (_isPlaying) {
      _isPlaying = false;
      _stopTimer();
      notifyListeners();
    }
  }

  void resume() {
    if (!_isPlaying) {
      _isPlaying = true;
      _startTimer();
      notifyListeners();
    }
  }

  void playPause() {
    _isPlaying = !_isPlaying;
    if (_isPlaying) {
      _startTimer();
    } else {
      _stopTimer();
    }
    notifyListeners();
    _updateNotification();
  }

  void nextSong() {
    if (shuffleMode == 1) {
      int nextIndex;
      do {
        nextIndex = DateTime.now().millisecondsSinceEpoch % _playlist.length;
      } while (nextIndex == _currentSongIndex && _playlist.length > 1);
      _loadSongByIndex(nextIndex);
    } else {
      int nextIndex = (_currentSongIndex + 1) % _playlist.length;
      _loadSongByIndex(nextIndex);
    }

    _isPlaying = true;
    _startTimer();
    notifyListeners();
  }

  void previousSong() {
    int prevIndex = _currentSongIndex - 1;
    if (prevIndex < 0) {
      prevIndex = _playlist.length - 1;
    }
    _loadSongByIndex(prevIndex);

    _isPlaying = true;
    _startTimer();
    notifyListeners();
  }

  void seekTo(double value) {
    if (totalDuration.inSeconds > 0) {
      _currentPosition = Duration(
        seconds: (value * totalDuration.inSeconds).round(),
      );
      notifyListeners();
      _updateNotification();
    }
  }

  // Toggles
  void toggleFavorite() {
    _isFavorited = !_isFavorited;
    // Update playlist favorite status
    _playlist[_currentSongIndex]['favorited'] = _isFavorited;
    notifyListeners();
    _updateNotification();
  }

  // playMode: 0=off, 1=repeat all, 2=repeat one, 3=shuffle
  int _playMode = 0;
  int get playMode => _playMode;

  int get shuffleMode => _playMode == 3 ? 1 : 0;
  int get repeatMode {
    if (_playMode == 1) return 1;
    if (_playMode == 2) return 2;
    return 0;
  }

  void cycleMode() {
    _playMode = (_playMode + 1) % 4;
    notifyListeners();
  }

  void toggleShuffle() {
    cycleMode();
  }

  void cycleRepeat() {
    cycleMode();
  }

  // Load song from playlist by index
  void playFromPlaylist(int index) {
    if (index >= 0 && index < _playlist.length) {
      _isPlaying = false;
      _stopTimer();
      _loadSongByIndex(index);
      _isPlaying = true;
      _startTimer();
      notifyListeners();
    }
  }

  // Simulate notification update
  void _updateNotification() {
    // This would communicate with native code to update notification
    print(
      'Notification updated: $currentSongTitle - $currentArtistName ($currentTimeFormatted/$totalTimeFormatted)',
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
