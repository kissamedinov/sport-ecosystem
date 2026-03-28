import 'package:flutter/material.dart';
import 'dart:ui';

class PremiumTheme {
  // Brand Colors
  static const Color neonGreen = Color(0xFF00E676);
  static const Color electricBlue = Color(0xFF2979FF);
  static const Color deepNavy = Color(0xFF0A0E12);
  static const Color cardNavy = Color(0xFF161B22);
  
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
