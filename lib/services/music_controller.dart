// music_controller.dart
//
// This service will replace music_provider.dart when the real audio
// engine is integrated. The music_player_page feature will send signals
// here (play, pause, seek, next, previous) and listen to state changes,
// without knowing anything about the underlying audio implementation.
//
// Example future interface:
//
// abstract class MusicController {
//   Stream<PlaybackState> get stateStream;
//   Stream<Duration> get positionStream;
//
//   void play();
//   void pause();
//   void seekTo(Duration position);
//   void skipNext();
//   void skipPrevious();
//   void dispose();
// }
