import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class MusicProvider extends ChangeNotifier {
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
  // Fix #1: start at zero, not 1:24
  Duration _currentPosition = Duration.zero;
  bool _isPlaying = false;
  Timer? _positionTimer;
  // Fix #6: proper random for shuffle
  final Random _random = Random();

  // playMode: 0=off, 1=repeat all, 2=repeat one, 3=shuffle
  int _playMode = 0;

  // ── Getters ──────────────────────────────────────────────────────────────

  String get currentSongTitle => _playlist[_currentSongIndex]['title'];
  String get currentArtistName => _playlist[_currentSongIndex]['artist'];
  // Fix #7: read favorited directly from playlist — no separate field to drift
  bool get isFavorited => _playlist[_currentSongIndex]['favorited'] as bool;
  Duration get totalDuration => _playlist[_currentSongIndex]['duration'];
  Duration get currentPosition => _currentPosition;
  bool get isPlaying => _isPlaying;
  List<Map<String, dynamic>> get playlist => _playlist;
  int get currentSongIndex => _currentSongIndex;
  String get currentImagePath => _playlist[_currentSongIndex]['imagePath'];
  Color get currentPrimaryColor => _playlist[_currentSongIndex]['primaryColor'];
  Color get currentSecondaryColor => _playlist[_currentSongIndex]['secondaryColor'];

  double get progressValue {
    if (totalDuration.inMilliseconds == 0) return 0.0;
    return _currentPosition.inMilliseconds / totalDuration.inMilliseconds;
  }

  String get currentTimeFormatted => _formatDuration(_currentPosition);
  String get totalTimeFormatted => _formatDuration(totalDuration);

  int get playMode => _playMode;
  int get shuffleMode => _playMode == 3 ? 1 : 0;
  int get repeatMode {
    if (_playMode == 1) return 1;
    if (_playMode == 2) return 2;
    return 0;
  }

  MusicProvider() {
    _loadSongByIndex(0, notify: false);
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  // ── Timer ─────────────────────────────────────────────────────────────────

  void _startTimer() {
    _stopTimer();
    _positionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPlaying) return;
      _currentPosition = Duration(
        milliseconds: _currentPosition.inMilliseconds + 1000,
      );
      if (_currentPosition >= totalDuration) {
        _currentPosition = totalDuration;
        notifyListeners();
        _onSongComplete();
      } else {
        notifyListeners();
      }
    });
  }

  void _stopTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  void _onSongComplete() {
    _stopTimer();
    switch (repeatMode) {
      case 2: // repeat one
        _currentPosition = Duration.zero;
        _isPlaying = true;
        _startTimer();
        notifyListeners();
        break;
      case 1: // repeat all
        _nextIndex();
        break;
      default:
        if (_currentSongIndex < _playlist.length - 1) {
          _nextIndex();
        } else {
          _isPlaying = false;
          notifyListeners();
        }
    }
  }

  // ── Internal load — single notify point ──────────────────────────────────

  void _loadSongByIndex(int index, {bool notify = true}) {
    if (index < 0 || index >= _playlist.length) return;
    _currentSongIndex = index;
    _currentPosition = Duration.zero;
    if (notify) notifyListeners();
  }

  void _nextIndex() {
    int next;
    if (shuffleMode == 1) {
      do {
        next = _random.nextInt(_playlist.length);
      } while (next == _currentSongIndex && _playlist.length > 1);
    } else {
      next = (_currentSongIndex + 1) % _playlist.length;
    }
    _loadSongByIndex(next);
    _isPlaying = true;
    _startTimer();
    notifyListeners();
  }

  // ── Public controls ───────────────────────────────────────────────────────

  void pause() {
    if (!_isPlaying) return;
    _isPlaying = false;
    _stopTimer();
    notifyListeners();
  }

  void resume() {
    if (_isPlaying) return;
    _isPlaying = true;
    _startTimer();
    notifyListeners();
  }

  void playPause() {
    _isPlaying = !_isPlaying;
    _isPlaying ? _startTimer() : _stopTimer();
    notifyListeners();
  }

  // Fix #5: no double notifyListeners — _loadSongByIndex handles it
  void nextSong() {
    _nextIndex();
  }

  void previousSong() {
    final prev = (_currentSongIndex - 1 + _playlist.length) % _playlist.length;
    _loadSongByIndex(prev);
    _isPlaying = true;
    _startTimer();
    notifyListeners();
  }

  void playFromPlaylist(int index) {
    if (index < 0 || index >= _playlist.length) return;
    _stopTimer();
    _loadSongByIndex(index);
    _isPlaying = true;
    _startTimer();
    notifyListeners();
  }

  void seekBySeconds(int seconds) {
    final next = _currentPosition + Duration(seconds: seconds);
    _currentPosition = next < Duration.zero
        ? Duration.zero
        : next > totalDuration
            ? totalDuration
            : next;
    notifyListeners();
  }

  void seekTo(double value) {
    if (totalDuration.inMilliseconds > 0) {
      _currentPosition = Duration(
        milliseconds: (value * totalDuration.inMilliseconds).round(),
      );
      notifyListeners();
    }
  }

  void seekToDuration(Duration position) {
    _currentPosition = position < Duration.zero
        ? Duration.zero
        : position > totalDuration
            ? totalDuration
            : position;
    notifyListeners();
  }

  void toggleFavorite() {
    // Fix #7: write directly to playlist map, no separate field
    _playlist[_currentSongIndex]['favorited'] =
        !(_playlist[_currentSongIndex]['favorited'] as bool);
    notifyListeners();
  }

  void reorderPlaylist(int oldIndex, int newIndex) {
    // ReorderableListView calls newIndex after removal, so adjust
    if (newIndex > oldIndex) newIndex--;
    final item = _playlist.removeAt(oldIndex);
    _playlist.insert(newIndex, item);
    // Keep _currentSongIndex pointing at the same song
    if (oldIndex == _currentSongIndex) {
      _currentSongIndex = newIndex;
    } else if (oldIndex < _currentSongIndex && newIndex >= _currentSongIndex) {
      _currentSongIndex--;
    } else if (oldIndex > _currentSongIndex && newIndex <= _currentSongIndex) {
      _currentSongIndex++;
    }
    notifyListeners();
  }

  void cycleMode() {
    _playMode = (_playMode + 1) % 4;
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }
}