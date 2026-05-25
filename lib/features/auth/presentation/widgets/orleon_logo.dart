import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kNavy = Color(0xFF0A0E12);
const _kGold = Color(0xFFF5C518);
const _kGreen = Color(0xFF00E676);

class OrleonLogo extends StatelessWidget {
  final double size;

  const OrleonLogo({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 200;
    canvas.scale(scale, scale);
    const center = Offset(100, 100);

    // Outer ring with radial gradient
    final outerRect = Rect.fromCircle(center: center, radius: 86);
    canvas.drawCircle(
      center,
      86,
      Paint()
        ..shader = const RadialGradient(
          colors: [_kGold, _kGreen],
          center: Alignment(-0.3, -0.4),
        ).createShader(outerRect),
    );

    // Inner hole
    canvas.drawCircle(center, 56, Paint()..color = _kNavy);

    // Top-left highlight arc
    final arcPath = Path()
      ..moveTo(30, 60)
      ..arcToPoint(const Offset(140, 30), radius: const Radius.circular(80), clockwise: false);
    canvas.drawPath(
      arcPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Clip to inner circle for shanyrak content
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: 53)));

    // Shanyrak outer ring stroke with gradient
    final shanRect = Rect.fromCircle(center: center, radius: 42);
    const shanGrad = LinearGradient(
      colors: [_kGold, _kGreen],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    canvas.drawCircle(
      center,
      42,
      Paint()
        ..shader = shanGrad.createShader(shanRect)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    // 12 curved spokes
    for (int i = 0; i < 12; i++) {
      final a = i / 12 * 2 * math.pi;
      final a2 = a + (2 * math.pi / 12) * 0.35;
      final x1 = center.dx + math.cos(a) * 12;
      final y1 = center.dy + math.sin(a) * 12;
      final x2 = center.dx + math.cos(a) * 42;
      final y2 = center.dy + math.sin(a) * 42;
      final qx = center.dx + math.cos(a2) * 26.5;
      final qy = center.dy + math.sin(a2) * 26.5;

      final spokePath = Path()
        ..moveTo(x1, y1)
        ..quadraticBezierTo(qx, qy, x2, y2);

      final spokePaint = Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      if (i % 3 == 0) {
        spokePaint.color = _kGold;
      } else if (i % 3 == 1) {
        spokePaint.color = _kGreen;
      } else {
        spokePaint.shader = shanGrad.createShader(shanRect);
      }

      canvas.drawPath(spokePath, spokePaint);
    }

    // Center hub
    final hubRect = Rect.fromCircle(center: center, radius: 11);
    final hubGrad = const RadialGradient(colors: [_kGold, _kGreen]).createShader(hubRect);
    canvas.drawCircle(center, 11, Paint()..shader = hubGrad);
    canvas.drawCircle(center, 7, Paint()..color = _kNavy.withValues(alpha: 0.8));
    canvas.drawCircle(center, 3.5, Paint()..shader = hubGrad);
  }

  @override
  bool shouldRepaint(_LogoPainter old) => false;
}

class OrleonBrandHeader extends StatelessWidget {
  final String? subtitle;

  const OrleonBrandHeader({super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const OrleonLogo(size: 56),
            Transform.translate(
              offset: const Offset(-2, 0),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'rle',
                      style: GoogleFonts.outfit(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                        color: onSurface,
                      ),
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [_kGold, _kGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          'On',
                          style: GoogleFonts.outfit(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'SPORT ECOSYSTEM · KAZAKHSTAN',
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.4,
            color: _kGold.withValues(alpha: 0.85),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 14),
          Text(
            subtitle!,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ],
    );
  }
}
