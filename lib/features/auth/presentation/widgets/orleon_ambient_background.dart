import 'dart:math' as math;
import 'package:flutter/material.dart';

class OrleonAmbientBackground extends StatelessWidget {
  final Color accent;

  const OrleonAmbientBackground({
    super.key,
    this.accent = const Color(0xFFF5C518),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _AmbientPainter(accent: accent));
  }
}

class _AmbientPainter extends CustomPainter {
  final Color accent;

  _AmbientPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Top glow
    final topRect = Rect.fromLTWH(-w * 0.45, -h * 0.3, w * 1.9, h * 1.3);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = RadialGradient(
          colors: [accent.withValues(alpha: 0.18), Colors.transparent],
          center: const Alignment(0, -1),
          radius: 0.9,
        ).createShader(topRect),
    );

    // Bottom glow
    final bottomRect = Rect.fromLTWH(-w * 0.45, 0, w * 1.9, h * 1.3);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x1E00E676), Colors.transparent],
          center: Alignment(0, 1),
          radius: 0.9,
        ).createShader(bottomRect),
    );

    // Kazakh sun rays
    canvas.save();
    canvas.translate(w / 2, h * 0.18);
    final rayPaint = Paint()
      ..color = accent.withValues(alpha: 0.06)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 32; i++) {
      final a = i / 32 * 2 * math.pi - math.pi / 2;
      canvas.drawLine(
        Offset(math.cos(a) * 90, math.sin(a) * 90),
        Offset(math.cos(a) * 155, math.sin(a) * 155),
        rayPaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AmbientPainter old) => old.accent != accent;
}
