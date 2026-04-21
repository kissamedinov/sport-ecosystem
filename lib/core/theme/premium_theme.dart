import 'package:flutter/material.dart';
import 'dart:ui';

class PremiumTheme {
  // Brand Colors
  static const Color neonGreen = Color(0xFF00E676);
  static const Color electricBlue = Color(0xFF2979FF);
  static const Color deepNavy = Color(0xFF0A0E12);
  static const Color cardNavy = Color(0xFF161B22);
  static const Color danger = Color(0xFFFF5252);
  static const Color amber = Color(0xFFFFD740);
  static const Color borderGrey = Color(0xFF30363D);
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonGreen, Color(0xFF00C853)],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [electricBlue, Color(0xFF2962FF)],
  );

  static const LinearGradient liveRedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE91E63), Color(0xFFFF5252)],
  );

  static const LinearGradient pitchGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
  );

  // Shadows
  static List<BoxShadow> neonShadow({Color? color, double opacity = 0.3}) {
    return [
      BoxShadow(
        color: (color ?? neonGreen).withValues(alpha: opacity),
        blurRadius: 10,
        spreadRadius: 2,
      ),
    ];
  }

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  // Glassmorphism Decoration
  static BoxDecoration glassDecoration({double blur = 10.0, double radius = 16.0}) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
    );
  }

  static Widget glassEffect({required Widget child, double blur = 10.0, double radius = 16.0}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: child,
      ),
    );
  }
  static InputDecoration inputDecoration(String label, {IconData? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: neonGreen, size: 20) : null,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: neonGreen),
      ),
    );
  }
}
