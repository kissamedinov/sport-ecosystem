import 'package:flutter/material.dart';
import 'dart:ui';

class PremiumTheme {
  // === Brand Colors (theme-independent) ===
  static const Color neonGreen = Color(0xFF00E676);
  static const Color electricBlue = Color(0xFF2979FF);
  static const Color danger = Color(0xFFFF5252);
  static const Color amber = Color(0xFFFFD740);
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);

  // === Theme-aware accent green ===
  // Resolves to neonGreen in dark, muted green in light. Use this for UI
  // accents (focus borders, prefix icons, accent text) so they match
  // AppTheme primary in both themes. Brand `neonGreen` constant remains
  // for fixed brand uses (gradients, brand marks).
  static Color accent(BuildContext c) =>
      _isDark(c) ? neonGreen : const Color(0xFF00C853);

  // === Theme-aware surface colors ===
  static Color surfaceBase(BuildContext c) =>
      _isDark(c) ? const Color(0xFF0A0E12) : const Color(0xFFF5F5F5);

  static Color surfaceCard(BuildContext c) =>
      _isDark(c) ? const Color(0xFF161B22) : Colors.white;

  static Color borderSubtle(BuildContext c) =>
      _isDark(c) ? const Color(0xFF30363D) : const Color(0xFFE0E0E0);

  static bool _isDark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  // === Deprecated constants (remove after call-site migration) ===
  @Deprecated('Use PremiumTheme.surfaceBase(context)')
  static const Color deepNavy = Color(0xFF0A0E12);

  @Deprecated('Use PremiumTheme.surfaceCard(context)')
  static const Color cardNavy = Color(0xFF161B22);

  @Deprecated('Use PremiumTheme.borderSubtle(context)')
  static const Color borderGrey = Color(0xFF30363D);

  // === Gradients (theme-independent) ===
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

  // === Theme-aware shadows ===
  static List<BoxShadow> neonShadow({Color? color, double opacity = 0.3}) {
    return [
      BoxShadow(
        color: (color ?? neonGreen).withValues(alpha: opacity),
        blurRadius: 10,
        spreadRadius: 2,
      ),
    ];
  }

  // Deprecated zero-arg getter — replaced by `softShadowOf(context)`.
  // We keep the old name returning the dark-mode shadow so unmigrated
  // call-sites compile (and look correct in dark, slightly heavy in light).
  @Deprecated('Use PremiumTheme.softShadowOf(context)')
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> softShadowOf(BuildContext c) {
    final dark = _isDark(c);
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? 0.20 : 0.08),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ];
  }

  // === Theme-aware glassmorphism ===
  // Old zero-arg version kept and deprecated; new version takes context.
  @Deprecated('Use PremiumTheme.glassDecorationOf(context, ...)')
  static BoxDecoration glassDecoration({double blur = 10.0, double radius = 16.0}) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
    );
  }

  static BoxDecoration glassDecorationOf(BuildContext c, {double radius = 16.0}) {
    final dark = _isDark(c);
    final tint = dark ? Colors.white : Colors.black;
    return BoxDecoration(
      color: tint.withValues(alpha: dark ? 0.05 : 0.04),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: tint.withValues(alpha: dark ? 0.10 : 0.08)),
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

  @Deprecated('Use PremiumTheme.inputDecorationOf(context, label, prefixIcon: ...)')
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

  static InputDecoration inputDecorationOf(BuildContext c, String label, {IconData? prefixIcon}) {
    final dark = _isDark(c);
    final tint = dark ? Colors.white : Colors.black;
    final ac = accent(c);
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: tint.withValues(alpha: 0.38)),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: ac, size: 20) : null,
      filled: true,
      fillColor: tint.withValues(alpha: 0.05),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: tint.withValues(alpha: 0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: ac),
      ),
    );
  }
}
