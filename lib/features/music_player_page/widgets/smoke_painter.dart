import 'dart:math';
import 'package:flutter/material.dart';

class SmokePainter extends CustomPainter {
  final Color color;
  final double progress;

  SmokePainter({required this.color, required this.progress});

  static const _blobs = [
    _BlobConfig(phaseOffset: 0.0,  xFactor: 0.3,  yStart: 0.9,  radius: 200),
    _BlobConfig(phaseOffset: 0.25, xFactor: 0.7,  yStart: 0.85, radius: 170),
    _BlobConfig(phaseOffset: 0.5,  xFactor: 0.5,  yStart: 1.0,  radius: 230),
    _BlobConfig(phaseOffset: 0.15, xFactor: 0.15, yStart: 0.95, radius: 155),
    _BlobConfig(phaseOffset: 0.65, xFactor: 0.85, yStart: 1.0,  radius: 185),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.screen;

    for (final blob in _blobs) {
      final t = (progress + blob.phaseOffset) % 1.0;
      final y = size.height * (blob.yStart - t * 1.25);
      final sway = sin(t * pi * 2 + blob.phaseOffset * pi) * size.width * 0.14;
      final x = size.width * blob.xFactor + sway;
      // Peak opacity raised from 0.18 → 0.45 for much more visible smoke
      final opacity = (sin(t * pi) * 0.25).clamp(0.0, 0.25);

      paint.shader = RadialGradient(
        colors: [color.withOpacity(opacity), color.withOpacity(0)],
      ).createShader(
        Rect.fromCircle(center: Offset(x, y), radius: blob.radius.toDouble()),
      );

      canvas.drawCircle(Offset(x, y), blob.radius.toDouble(), paint);
    }
  }

  @override
  bool shouldRepaint(SmokePainter old) =>
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