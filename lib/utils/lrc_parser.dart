import '../models/lrc_line.dart';

export '../models/lrc_line.dart';

// Parses standard LRC format: [mm:ss.xx]Lyric line
List<LrcLine> parseLrc(String content) {
  final lines = <LrcLine>[];
  final lineRegex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');

  for (final raw in content.split('\n')) {
    final match = lineRegex.firstMatch(raw.trim());
    if (match == null) continue;

    final minutes = int.parse(match.group(1)!);
    final seconds = int.parse(match.group(2)!);
    final centisStr = match.group(3)!;
    // Handle both 2-digit (centiseconds) and 3-digit (milliseconds)
    final millis = centisStr.length == 3
        ? int.parse(centisStr)
        : int.parse(centisStr) * 10;
    final text = match.group(4)!.trim();

    if (text.isEmpty) continue; // skip instrumental gaps / blank lines
    lines.add(LrcLine(
      timestamp: Duration(
        minutes: minutes,
        seconds: seconds,
        milliseconds: millis,
      ),
      text: text,
    ));
  }

  // Sort by timestamp in case the file is out of order
  lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return lines;
}

// Returns the current active line based on playback position
LrcLine? getCurrentLine(List<LrcLine> lines, Duration position) {
  LrcLine? current;
  for (final line in lines) {
    if (line.timestamp <= position) {
      current = line;
    } else {
      break;
    }
  }
  return current;
}