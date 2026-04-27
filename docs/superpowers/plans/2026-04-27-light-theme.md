# Light Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a fully working light theme to the sport-ecosystem Flutter app with a System / Light / Dark toggle in a new Settings screen, persisted across launches.

**Architecture:**
- `AppTheme` exposes `light` and `dark` `ThemeData` built from a shared base.
- `ThemeProvider` (ChangeNotifier) holds the active `ThemeMode`, persists via `SharedPreferences`.
- `PremiumTheme` (existing utility class used in 43 files) becomes context-aware: theme-dependent values become methods taking `BuildContext`. Brand constants (gradients, accent colors) stay constants.
- Migration is split: PremiumTheme call-sites are migrated everywhere (mechanical, ~133 sites in 43 files); direct hardcoded colors are migrated only in P1 screens (auth, main navigation, profile, dashboards). Out-of-scope screens stay visually polished only in dark.

**Tech Stack:** Flutter, Provider 6.x, SharedPreferences 2.5.x, GoogleFonts (already in pubspec).

**Reference spec:** [`docs/superpowers/specs/2026-04-27-light-theme-design.md`](../specs/2026-04-27-light-theme-design.md)

**Replacement rules (used by migration tasks):**

| Pattern | Replacement |
|---|---|
| `Colors.white` (background/surface) | `Theme.of(context).colorScheme.surface` |
| `Colors.white` (text on brand-colored buttons) | `Theme.of(context).colorScheme.onPrimary` (or keep literal if on a fixed brand color) |
| `Colors.white70` (secondary text) | `Theme.of(context).colorScheme.onSurfaceVariant` |
| `Colors.white12` / `Colors.white24` (dividers) | `Theme.of(context).dividerColor` |
| `Colors.black` (text) | `Theme.of(context).colorScheme.onSurface` |
| `Color(0xFF161B22)` / `0xFF0A0E12` (surfaces) | `PremiumTheme.surfaceCard(context)` / `PremiumTheme.surfaceBase(context)` |
| `Color(0xFF30363D)` (borders) | `PremiumTheme.borderSubtle(context)` |

**Untouched:** brand colors (`neonGreen`, `electricBlue`, `gold`, `silver`, `bronze`, `danger`, `amber`), icon colors when they are brand marks, gradients, image assets.

---

## Task 1: Refactor `app_theme.dart` — extract base, add `AppTheme.light`

**Files:**
- Modify: `lib/core/theme/app_theme.dart`

- [ ] **Step 1: Replace `app_theme.dart` content with refactored version**

Open `lib/core/theme/app_theme.dart` and replace its entire content with:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand accent colors (theme-independent)
  static const Color brandNeonGreen = Color(0xFF00E676);
  static const Color brandElectricBlue = Color(0xFF2979FF);

  // Dark theme palette
  static const Color _darkBg = Color(0xFF121212);
  static const Color _darkSurface = Color(0xFF1E1E1E);
  static const Color _darkCard = Color(0xFF252525);

  // Light theme palette
  static const Color _lightBg = Color(0xFFF5F5F5);
  static const Color _lightSurface = Colors.white;
  static const Color _lightOnSurface = Color(0xFF1A1A1A);
  static const Color _lightOnSurfaceVariant = Color(0xFF757575);
  static const Color _lightOutline = Color(0xFFE0E0E0);
  static const Color _lightPrimary = Color(0xFF00C853); // muted neonGreen for contrast on white

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        scheme: const ColorScheme.dark(
          primary: brandNeonGreen,
          secondary: brandElectricBlue,
          surface: _darkSurface,
          onPrimary: Colors.black,
          onSecondary: Colors.white,
          onSurface: Colors.white,
          surfaceTint: Colors.transparent,
        ),
        scaffoldBg: _darkBg,
        cardColor: _darkCard,
        inputFill: _darkSurface,
        bottomNavBg: _darkSurface,
        primaryButtonFg: Colors.black,
        cardBorder: null,
      );

  static ThemeData get light => _build(
        brightness: Brightness.light,
        scheme: const ColorScheme.light(
          primary: _lightPrimary,
          secondary: brandElectricBlue,
          surface: _lightSurface,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: _lightOnSurface,
          onSurfaceVariant: _lightOnSurfaceVariant,
          outline: _lightOutline,
          surfaceTint: Colors.transparent,
        ),
        scaffoldBg: _lightBg,
        cardColor: _lightSurface,
        inputFill: _lightSurface,
        bottomNavBg: _lightSurface,
        primaryButtonFg: Colors.white,
        cardBorder: _lightOutline,
      );

  // Backwards compatibility: existing code references AppTheme.darkTheme.
  // Keep alias until callers migrate (currently only main.dart).
  static ThemeData get darkTheme => dark;

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color scaffoldBg,
    required Color cardColor,
    required Color inputFill,
    required Color bottomNavBg,
    required Color primaryButtonFg,
    required Color? cardBorder,
  }) {
    final isLight = brightness == Brightness.light;
    final secondaryTextColor =
        isLight ? _lightOnSurfaceVariant : Colors.white70;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: scheme.primary,
      scaffoldBackgroundColor: scaffoldBg,
      canvasColor: scaffoldBg,
      dialogBackgroundColor: scheme.surface,
      colorScheme: scheme,
      cardTheme: CardThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: cardBorder == null
              ? BorderSide.none
              : BorderSide(color: cardBorder, width: 1),
        ),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: scheme.onSurface,
        iconColor: secondaryTextColor,
      ),
      dividerTheme: DividerThemeData(
        color: isLight
            ? _lightOutline
            : Colors.white.withValues(alpha: 0.12),
        thickness: 1,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        TextTheme(
          headlineMedium:
              TextStyle(fontWeight: FontWeight.bold, color: scheme.onSurface),
          titleLarge:
              TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface),
          bodyLarge: TextStyle(color: scheme.onSurface),
          bodyMedium: TextStyle(color: secondaryTextColor),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isLight ? Colors.white : Colors.transparent,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: scheme.onSurface,
          letterSpacing: 2,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bottomNavBg,
        selectedItemColor: scheme.primary,
        unselectedItemColor: secondaryTextColor,
        type: BottomNavigationBarType.fixed,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: primaryButtonFg,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: isLight
              ? const BorderSide(color: _lightOutline)
              : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: isLight
              ? const BorderSide(color: _lightOutline)
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.primary, width: 1),
        ),
        labelStyle: TextStyle(color: secondaryTextColor),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify build & analyzer**

Run:
```bash
flutter analyze lib/core/theme/app_theme.dart
```
Expected: `No issues found!`

Run:
```bash
flutter analyze
```
Expected: `No issues found!` (existing dark theme still works through `AppTheme.darkTheme` alias)

- [ ] **Step 3: Commit**

```bash
git add lib/core/theme/app_theme.dart
git commit -m "theme: extract base theme builder, add AppTheme.light"
```

---

## Task 2: Create `ThemeProvider` with unit test (TDD)

**Files:**
- Create: `lib/core/theme/theme_provider.dart`
- Create: `test/core/theme/theme_provider_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/core/theme/theme_provider_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to ThemeMode.system when no value persisted', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = ThemeProvider(prefs);
      expect(provider.themeMode, ThemeMode.system);
    });

    test('decodes a persisted value on construction', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      final prefs = await SharedPreferences.getInstance();
      final provider = ThemeProvider(prefs);
      expect(provider.themeMode, ThemeMode.light);
    });

    test('falls back to system on invalid persisted value', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'garbage'});
      final prefs = await SharedPreferences.getInstance();
      final provider = ThemeProvider(prefs);
      expect(provider.themeMode, ThemeMode.system);
    });

    test('setThemeMode updates state, notifies, and persists', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = ThemeProvider(prefs);
      var notified = 0;
      provider.addListener(() => notified++);

      await provider.setThemeMode(ThemeMode.dark);

      expect(provider.themeMode, ThemeMode.dark);
      expect(notified, 1);
      expect(prefs.getString('theme_mode'), 'dark');
    });

    test('setThemeMode is a no-op if mode unchanged', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = ThemeProvider(prefs);
      var notified = 0;
      provider.addListener(() => notified++);

      await provider.setThemeMode(ThemeMode.system);

      expect(notified, 0);
    });
  });
}
```

- [ ] **Step 2: Run test, verify it fails to compile**

Run:
```bash
flutter test test/core/theme/theme_provider_test.dart
```
Expected: compile error (`ThemeProvider` not defined / file not found).

- [ ] **Step 3: Write the minimal implementation**

Create `lib/core/theme/theme_provider.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';
  final SharedPreferences _prefs;
  ThemeMode _mode;

  ThemeProvider(this._prefs)
      : _mode = _decode(_prefs.getString(_key)) ?? ThemeMode.system;

  ThemeMode get themeMode => _mode;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    try {
      await _prefs.setString(_key, _encode(mode));
    } catch (e, s) {
      debugPrint('ThemeProvider: failed to persist theme mode: $e\n$s');
    }
  }

  static String _encode(ThemeMode m) => m.name;

  static ThemeMode? _decode(String? s) {
    if (s == null) return null;
    for (final m in ThemeMode.values) {
      if (m.name == s) return m;
    }
    return null;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
flutter test test/core/theme/theme_provider_test.dart
```
Expected: `All tests passed!` (5 tests).

Run analyzer:
```bash
flutter analyze
```
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme/theme_provider.dart test/core/theme/theme_provider_test.dart
git commit -m "theme: add ThemeProvider with SharedPreferences persistence"
```

---

## Task 3: Wire `ThemeProvider` into `main.dart`

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Update `main()` to load `SharedPreferences` synchronously and provide `ThemeProvider`**

In `lib/main.dart`:

Change the imports section to add (after existing theme import on line 4):
```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/theme_provider.dart';
```

Change the `void main()` signature to async and add prefs loading at the top of the function (line 40 currently). Replace lines 40–56 (`void main() {` through `final bookingRepository = BookingRepository(apiClient);`) with:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  final apiClient = ApiClient();
  final authRepository = AuthRepository(apiClient);
  final tournamentRepository = TournamentRepository(apiClient);
  final teamRepository = TeamRepository(apiClient);
  final childRepository = ChildRepository(apiClient);
  final matchRepository = MatchRepository(apiClient);
  final fieldRepository = FieldRepository(apiClient);
  final tournamentSquadRepository = TournamentSquadRepository(apiClient);
  final playerRepository = PlayerRepository(apiClient);
  final academyRepository = AcademyRepository(apiClient);
  final clubRepository = ClubRepository(apiClient);
  final notificationRepository = NotificationRepository(apiClient);
  final mediaRepository = MediaRepository(apiClient);
  final adminRepository = AdminRepository(apiClient);
  final bookingRepository = BookingRepository(apiClient);
```

- [ ] **Step 2: Add `ThemeProvider` to the `MultiProvider` providers list**

In the `providers: [...]` list (currently starts at line 59), insert as the **first** entry:

```dart
ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
```

- [ ] **Step 3: Update `SportsApp.build` to use `themeMode`**

Replace the body of `SportsApp.build` (lines 91–104) with:

```dart
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'Football Ecosystem',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainNavigationScreen(),
      },
    );
  }
```

- [ ] **Step 4: Verify build**

Run:
```bash
flutter analyze
```
Expected: `No issues found!`

Run smoke test:
```bash
flutter test test/widget_test.dart
```
Expected: `All tests passed!` (existing widget test, may need update if it fails — see Step 5).

- [ ] **Step 5: If smoke test fails, update `test/widget_test.dart` to wrap `SportsApp` with `ThemeProvider`**

If Step 4's widget test fails because `SportsApp` now requires `ThemeProvider`, replace `test/widget_test.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/theme/theme_provider.dart';
import 'package:mobile/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(prefs),
        child: const SportsApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
```

Re-run:
```bash
flutter test test/widget_test.dart
```
Expected: `All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add lib/main.dart test/widget_test.dart
git commit -m "theme: wire ThemeProvider into MaterialApp"
```

---

## Task 4: Refactor `PremiumTheme` — add context-aware methods, deprecate old constants

**Files:**
- Modify: `lib/core/theme/premium_theme.dart`

This task adds the new context-aware API alongside existing constants. Old constants stay (marked `@Deprecated`) so the project keeps compiling. Tasks 5–7 then migrate call-sites in batches.

- [ ] **Step 1: Replace `premium_theme.dart` content**

Open `lib/core/theme/premium_theme.dart` and replace the entire content with:

```dart
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
```

- [ ] **Step 2: Verify analyzer (deprecation warnings expected)**

Run:
```bash
flutter analyze
```
Expected: many `info` warnings about deprecated `deepNavy`, `cardNavy`, `borderGrey`, `softShadow`, `glassDecoration`, `inputDecoration` usage in 43 files — **but no errors**. These warnings are the migration checklist for Tasks 5–7.

If any **errors** appear, fix them before committing.

- [ ] **Step 3: Commit**

```bash
git add lib/core/theme/premium_theme.dart
git commit -m "theme: refactor PremiumTheme to context-aware getters"
```

---

## Task 5: Migrate `PremiumTheme` call-sites in `lib/core/`

**Files:**
- Modify: `lib/core/presentation/screens/main_navigation_screen.dart`
- Modify: `lib/core/presentation/widgets/orleon_widgets.dart`
- Modify: `lib/core/presentation/widgets/premium_widgets.dart`

Apply the following mechanical replacements **only to deprecated `PremiumTheme.*` references**. Leave `Colors.white` and hex literals untouched in this task.

| Find | Replace |
|---|---|
| `PremiumTheme.deepNavy` | `PremiumTheme.surfaceBase(context)` |
| `PremiumTheme.cardNavy` | `PremiumTheme.surfaceCard(context)` |
| `PremiumTheme.borderGrey` | `PremiumTheme.borderSubtle(context)` |
| `PremiumTheme.softShadow` | `PremiumTheme.softShadowOf(context)` |
| `PremiumTheme.glassDecoration(` (zero or named-args) | `PremiumTheme.glassDecorationOf(context, ` (preserve named args) |
| `PremiumTheme.inputDecoration(` | `PremiumTheme.inputDecorationOf(context, ` |

If a call site is in a function that doesn't have `context` in scope, propagate `BuildContext context` through the function signature.

- [ ] **Step 1: Locate exact call-sites in the 3 core files**

Run:
```bash
grep -nE 'PremiumTheme\.(deepNavy|cardNavy|borderGrey|softShadow[^O]|glassDecoration\(|inputDecoration\()' \
  lib/core/presentation/screens/main_navigation_screen.dart \
  lib/core/presentation/widgets/orleon_widgets.dart \
  lib/core/presentation/widgets/premium_widgets.dart
```
Expected: prints each occurrence with file:line.

- [ ] **Step 2: Apply replacements in `main_navigation_screen.dart`**

Open `lib/core/presentation/screens/main_navigation_screen.dart` and apply the replacement table to each line surfaced by Step 1. Add `context` parameter to any helper function that uses these getters but currently has no context.

- [ ] **Step 3: Apply replacements in `orleon_widgets.dart`**

Same procedure for `lib/core/presentation/widgets/orleon_widgets.dart`.

- [ ] **Step 4: Apply replacements in `premium_widgets.dart`**

Same procedure for `lib/core/presentation/widgets/premium_widgets.dart`.

- [ ] **Step 5: Verify analyzer — no deprecation warnings remain in these 3 files**

Run:
```bash
flutter analyze lib/core/presentation/
```
Expected: `No issues found!` for these files. Repeat the grep from Step 1 — should return **no matches**.

Run full analyzer (other files still have deprecation warnings — that's expected for now):
```bash
flutter analyze
```
Expected: `No issues found!` (errors), only `info` deprecation warnings in non-core files.

- [ ] **Step 6: Commit**

```bash
git add lib/core/presentation/
git commit -m "theme: migrate core widgets to context-aware PremiumTheme"
```

---

## Task 6: Migrate `PremiumTheme` call-sites in P1 features (auth, profile, dashboards, coaches)

**Files:**
- Modify: `lib/features/auth/presentation/screens/my_children_screen.dart`
- Modify: `lib/features/profile/presentation/screens/profile_screen.dart`
- Modify: `lib/features/profile/presentation/screens/edit_profile_screen.dart`
- Modify: `lib/features/profile/presentation/screens/coach_profile.dart`
- Modify: `lib/features/profile/presentation/screens/club_owner_profile.dart`
- Modify: `lib/features/profile/presentation/screens/child_player_profile.dart`
- Modify: `lib/features/profile/presentation/widgets/child_player_profile_body.dart`
- Modify: `lib/features/dashboard/screens/adult_player_dashboard.dart`
- Modify: `lib/features/dashboard/screens/parent_dashboard.dart`
- Modify: `lib/features/dashboard/screens/child_player_dashboard.dart`
- Modify: `lib/features/dashboard/screens/coach_dashboard.dart`
- Modify: `lib/features/dashboard/screens/coach_dashboard_screen.dart`
- Modify: `lib/features/coaches/presentation/screens/coach_dashboard_screen.dart`
- Modify: `lib/features/coaches/presentation/screens/coach_teams_screen.dart`
- Modify: `lib/features/coaches/presentation/screens/coach_performance_screen.dart`

Apply the same replacement table from Task 5 to each file.

- [ ] **Step 1: Locate exact call-sites in the P1 feature files**

Run:
```bash
grep -rnE 'PremiumTheme\.(deepNavy|cardNavy|borderGrey|softShadow[^O]|glassDecoration\(|inputDecoration\()' \
  lib/features/auth/presentation/screens/my_children_screen.dart \
  lib/features/profile/ \
  lib/features/dashboard/ \
  lib/features/coaches/
```

- [ ] **Step 2: Apply replacements file by file**

For each file in the list, open it and apply the replacement table. If a helper function has no `context`, propagate it through. The compiler error becomes the migration checklist if you miss a spot.

- [ ] **Step 3: Verify**

Run:
```bash
grep -rnE 'PremiumTheme\.(deepNavy|cardNavy|borderGrey|softShadow[^O]|glassDecoration\(|inputDecoration\()' \
  lib/features/auth/presentation/screens/my_children_screen.dart \
  lib/features/profile/ \
  lib/features/dashboard/ \
  lib/features/coaches/
```
Expected: no matches.

```bash
flutter analyze lib/features/profile/ lib/features/dashboard/ lib/features/coaches/ lib/features/auth/presentation/screens/my_children_screen.dart
```
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/profile/ lib/features/dashboard/ lib/features/coaches/ lib/features/auth/presentation/screens/my_children_screen.dart
git commit -m "theme: migrate profile/dashboard/coaches to context-aware PremiumTheme"
```

---

## Task 7: Migrate `PremiumTheme` call-sites in remaining features

**Files (43-file list minus those done in Tasks 5–6):**
- `lib/features/academies/presentation/screens/training_management_screen.dart`
- `lib/features/bookings/presentation/screens/field_booking_screen.dart`
- `lib/features/children/presentation/widgets/activity_calendar_widget.dart`
- `lib/features/children/presentation/screens/child_management_screen.dart`
- `lib/features/children/presentation/screens/add_child_screen.dart`
- `lib/features/children/presentation/screens/children_activity_screen.dart`
- `lib/features/clubs/presentation/screens/invitations_screen.dart`
- `lib/features/clubs/presentation/screens/academy_management_screen.dart`
- `lib/features/clubs/presentation/screens/team_management_screen.dart`
- `lib/features/clubs/presentation/screens/invite_member_screen.dart`
- `lib/features/clubs/presentation/screens/club_dashboard_screen.dart`
- `lib/features/lineups/presentation/screens/lineup_screen.dart`
- `lib/features/matches/presentation/widgets/match_event_dialog.dart`
- `lib/features/matches/presentation/screens/live_match_screen.dart`
- `lib/features/matches/presentation/screens/match_events_screen.dart`
- `lib/features/media/presentation/screens/upload_media_screen.dart`
- `lib/features/notifications/presentation/screens/notification_screen.dart`
- `lib/features/player_stats/presentation/widgets/career_history_chart.dart`
- `lib/features/stats/presentation/screens/performance_screen.dart`
- `lib/features/tournaments/presentation/screens/tournament_list_screen.dart`
- `lib/features/tournaments/presentation/screens/tournament_leaderboard_screen.dart`
- `lib/features/tournaments/presentation/screens/tournament_details_page.dart`
- `lib/features/tournaments/presentation/screens/tournament_squad_screen.dart`
- `lib/features/tournaments/presentation/screens/tournament_announcements_screen.dart`
- `lib/features/tournaments/presentation/screens/create_tournament_screen.dart`

Same replacement table. This is bulky but mechanical.

- [ ] **Step 1: Locate remaining call-sites**

Run:
```bash
grep -rnE 'PremiumTheme\.(deepNavy|cardNavy|borderGrey|softShadow[^O]|glassDecoration\(|inputDecoration\()' lib/
```
Expected: matches in the files above.

- [ ] **Step 2: Apply replacements**

For each file, open and apply the replacement table.

- [ ] **Step 3: Verify**

Run:
```bash
grep -rnE 'PremiumTheme\.(deepNavy|cardNavy|borderGrey|softShadow[^O]|glassDecoration\(|inputDecoration\()' lib/
```
Expected: **no matches** anywhere.

```bash
flutter analyze
```
Expected: `No issues found!` — no deprecation warnings remain.

- [ ] **Step 4: Commit**

```bash
git add lib/features/
git commit -m "theme: migrate remaining features to context-aware PremiumTheme"
```

---

## Task 8: Remove deprecated `PremiumTheme` constants

**Files:**
- Modify: `lib/core/theme/premium_theme.dart`

- [ ] **Step 1: Delete the deprecated members**

Open `lib/core/theme/premium_theme.dart` and delete these blocks:
- The `@Deprecated('Use PremiumTheme.surfaceBase(context)')` block declaring `deepNavy`
- The `@Deprecated('Use PremiumTheme.surfaceCard(context)')` block declaring `cardNavy`
- The `@Deprecated('Use PremiumTheme.borderSubtle(context)')` block declaring `borderGrey`
- The `@Deprecated('Use PremiumTheme.softShadowOf(context)')` getter `softShadow`
- The `@Deprecated('Use PremiumTheme.glassDecorationOf(context, ...)')` method `glassDecoration` (keep `glassDecorationOf` and `glassEffect`)
- The `@Deprecated('Use PremiumTheme.inputDecorationOf(...')` method `inputDecoration` (keep `inputDecorationOf`)

- [ ] **Step 2: Verify**

```bash
flutter analyze
```
Expected: `No issues found!` — confirms zero call-sites depend on the deprecated API.

If errors appear, find the offending file and migrate it (see Task 5 for the rule), then re-run.

- [ ] **Step 3: Commit**

```bash
git add lib/core/theme/premium_theme.dart
git commit -m "theme: remove deprecated PremiumTheme constants"
```

---

## Task 9: Create `SettingsScreen` and wire navigation

**Files:**
- Create: `lib/features/settings/presentation/screens/settings_screen.dart`
- Modify: `lib/features/profile/presentation/screens/profile_screen.dart`

- [ ] **Step 1: Create the settings screen**

Create `lib/features/settings/presentation/screens/settings_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/theme/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'APPEARANCE',
              style: textTheme.labelMedium?.copyWith(letterSpacing: 1.4),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme', style: textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.phone_android),
                        label: Text('System'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode),
                        label: Text('Light'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode),
                        label: Text('Dark'),
                      ),
                    ],
                    selected: {themeProvider.themeMode},
                    onSelectionChanged: (set) =>
                        context.read<ThemeProvider>().setThemeMode(set.first),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Choose how the app looks. "System" follows your device.',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Wire navigation from profile bottom-sheet**

In `lib/features/profile/presentation/screens/profile_screen.dart`, find the `Settings` menu item (currently around line 51, the third `_buildMenuItem(...)` in the bottom-sheet). Replace its `onTap` body with navigation to `SettingsScreen`.

Find:
```dart
_buildMenuItem(Icons.settings_outlined, 'Settings', Colors.white70, () {
  Navigator.pop(ctx);
}),
```

Replace with:
```dart
_buildMenuItem(Icons.settings_outlined, 'Settings', Colors.white70, () {
  Navigator.pop(ctx);
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SettingsScreen()),
  );
}),
```

Add the import at the top of `profile_screen.dart`:
```dart
import 'package:mobile/features/settings/presentation/screens/settings_screen.dart';
```

- [ ] **Step 3: Verify**

```bash
flutter analyze
```
Expected: `No issues found!`

- [ ] **Step 4: Manual smoke test**

Run the app:
```bash
flutter run
```
- Log in
- Open profile → tap menu (three dots) → Settings → opens new screen
- Tap Light segment → app switches to light theme everywhere visible
- Tap Dark segment → switches back
- Tap System → follows device theme
- Hot-restart the app — chosen mode persists

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings/ lib/features/profile/presentation/screens/profile_screen.dart
git commit -m "feat(settings): add SettingsScreen with theme toggle"
```

---

## Task 10: Migrate auth screens to `colorScheme`

**Files:**
- Modify: `lib/features/auth/presentation/screens/splash_screen.dart`
- Modify: `lib/features/auth/presentation/screens/login_screen.dart`
- Modify: `lib/features/auth/presentation/screens/register_screen.dart`

Apply the **direct hardcoded color** rules from the replacement table at the top of this plan. The `Color(0xFF00E676)` brand neon (e.g. soccer-ball icon on splash) should stay as-is — it's a brand mark.

- [ ] **Step 1: Locate hardcoded colors in each file**

Run:
```bash
grep -nE 'Colors\.(white|black)|Color\(0xFF' \
  lib/features/auth/presentation/screens/splash_screen.dart \
  lib/features/auth/presentation/screens/login_screen.dart \
  lib/features/auth/presentation/screens/register_screen.dart
```

- [ ] **Step 2: Apply replacements per the table**

For each match, decide:
- If it's a **surface/background** Colors.white → `Theme.of(context).colorScheme.surface`
- If it's **secondary text** Colors.white70 → `Theme.of(context).colorScheme.onSurfaceVariant`
- If it's a **brand-mark color** (`0xFF00E676` neon, `0xFF2979FF` blue) → leave as-is
- If it's a **dark-themed surface hex** (`0xFF161B22`, `0xFF0A0E12`) → `PremiumTheme.surfaceCard(context)` / `surfaceBase(context)`
- If it's a **border** (`0xFF30363D` or similar) → `PremiumTheme.borderSubtle(context)`
- If it's plain `Colors.white` for **text on a brand button** → `Theme.of(context).colorScheme.onPrimary`

Where text styles have explicit `color:`, prefer dropping the `color:` and letting M3 inherit from `colorScheme.onSurface`.

- [ ] **Step 3: Verify analyzer**

```bash
flutter analyze lib/features/auth/presentation/screens/splash_screen.dart lib/features/auth/presentation/screens/login_screen.dart lib/features/auth/presentation/screens/register_screen.dart
```
Expected: `No issues found!`

- [ ] **Step 4: Manual visual test in both themes**

```bash
flutter run
```
On splash, login, register screens — toggle theme via Settings, then logout to revisit auth screens. Confirm:
- No white-on-white or black-on-black text
- All borders visible in both themes
- Brand neon icon still shows green on splash

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/presentation/screens/splash_screen.dart lib/features/auth/presentation/screens/login_screen.dart lib/features/auth/presentation/screens/register_screen.dart
git commit -m "theme: migrate auth screens to colorScheme"
```

---

## Task 11: Migrate main navigation

**Files:**
- Modify: `lib/core/presentation/screens/main_navigation_screen.dart`

- [ ] **Step 1: Locate hardcoded colors**

```bash
grep -nE 'Colors\.(white|black)|Color\(0xFF' lib/core/presentation/screens/main_navigation_screen.dart
```

- [ ] **Step 2: Apply replacement rules**

Same rules as Task 10 Step 2. Pay attention to bottom-nav bar styling — the `BottomNavigationBarTheme` already comes from `ThemeData`, so any local overrides should be removed in favor of theme defaults.

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/core/presentation/screens/main_navigation_screen.dart
```
Expected: `No issues found!`

- [ ] **Step 4: Visual test**

```bash
flutter run
```
- Log in → home → check bottom nav and any tab transitions in both themes.

- [ ] **Step 5: Commit**

```bash
git add lib/core/presentation/screens/main_navigation_screen.dart
git commit -m "theme: migrate main navigation to colorScheme"
```

---

## Task 12: Migrate profile screens

**Files:**
- Modify: `lib/features/profile/presentation/screens/profile_screen.dart`
- Modify: `lib/features/profile/presentation/screens/edit_profile_screen.dart`
- Modify: `lib/features/profile/presentation/widgets/profile_header.dart`
- Modify: `lib/features/profile/presentation/widgets/player_profile_body.dart`
- Modify: `lib/features/profile/presentation/widgets/parent_profile_body.dart`
- Modify: `lib/features/profile/presentation/widgets/coach_profile_body.dart`
- Modify: `lib/features/profile/presentation/widgets/child_player_profile_body.dart`
- Modify: `lib/features/profile/presentation/widgets/manager_profile_body.dart`
- Modify: `lib/features/profile/presentation/widgets/club_owner_profile_body.dart`
- Modify: `lib/features/profile/presentation/widgets/referee_profile_body.dart`

- [ ] **Step 1: Locate hardcoded colors**

```bash
grep -rnE 'Colors\.(white|black)|Color\(0xFF' \
  lib/features/profile/presentation/screens/profile_screen.dart \
  lib/features/profile/presentation/screens/edit_profile_screen.dart \
  lib/features/profile/presentation/widgets/
```

- [ ] **Step 2: Apply replacement rules file by file**

Open each of the 10 files and apply the rules. For role-specific profile bodies (`*_profile_body.dart`), the structure is similar across files — apply the same replacements consistently.

Special attention in `profile_screen.dart`: the `_showProfileMenu` bottom-sheet at line 22 has hardcoded `backgroundColor: Color(0xFF161B22)` and dividers `Colors.white12`. Replace with `PremiumTheme.surfaceCard(context)` and `Theme.of(ctx).dividerColor`. The `_buildMenuItem` helper takes a `Color color` parameter — leave as-is, but call sites should pass theme-aware colors instead of `Colors.white70`.

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/features/profile/
```
Expected: `No issues found!`

- [ ] **Step 4: Visual test in both themes**

```bash
flutter run
```
Open profile for at least these roles (use existing test accounts or admin role-switching if available): player, parent, coach, child, manager, club_owner, referee. Toggle theme, scroll each profile, check edit-profile screen in both themes.

- [ ] **Step 5: Commit**

```bash
git add lib/features/profile/
git commit -m "theme: migrate profile screens to colorScheme"
```

---

## Task 13: Migrate dashboards

**Files:**
- Modify: `lib/features/dashboard/screens/adult_player_dashboard.dart`
- Modify: `lib/features/dashboard/screens/parent_dashboard.dart`
- Modify: `lib/features/dashboard/screens/coach_dashboard_screen.dart`
- Modify: `lib/features/dashboard/screens/child_player_dashboard.dart`
- Modify: `lib/features/dashboard/screens/field_owner_dashboard.dart`

- [ ] **Step 1: Locate hardcoded colors**

```bash
grep -rnE 'Colors\.(white|black)|Color\(0xFF' lib/features/dashboard/screens/
```

- [ ] **Step 2: Apply replacement rules**

Same rules as Task 10 Step 2.

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/features/dashboard/
```
Expected: `No issues found!`

- [ ] **Step 4: Visual test**

```bash
flutter run
```
Log in as each of: adult player, parent, coach, child, field owner. Confirm dashboard appearance in both themes.

- [ ] **Step 5: Commit**

```bash
git add lib/features/dashboard/
git commit -m "theme: migrate dashboards to colorScheme"
```

---

## Task 14: Final verification

- [ ] **Step 1: Full analyzer pass**

```bash
flutter analyze
```
Expected: `No issues found!` (zero new warnings or errors compared to pre-PR state).

- [ ] **Step 2: Full unit test pass**

```bash
flutter test
```
Expected: all tests pass (theme_provider_test + widget_test smoke).

- [ ] **Step 3: End-to-end smoke flow**

```bash
flutter run
```
Walk the full P1 surface in both themes:
1. Splash (cold start) → Login → Register form → Login back
2. Home → bottom-nav between tabs
3. Profile → menu → Settings → toggle System / Light / Dark
4. Background app, kill, cold start → confirm chosen theme persists
5. Hop into each role's dashboard (use multiple test accounts)
6. Edit Profile → enter values, save
7. Logout → back to login

Check at each screen: no white-on-white, no black-on-black, all icons/text legible, brand-green elements still neon-green where intended.

- [ ] **Step 4: Note known visual issues in P2 screens (out-of-scope)**

When toggling to Light, screens deferred to P2 (tournaments, matches, academies, teams, clubs, onboarding, notifications, media, lineups, bookings, children, player-stats, admin) will show direct-hardcoded `Colors.white` / hex literals that aren't theme-correct. This is expected per spec — they remain functional and visible, just not visually polished. Do not block this PR on those.

- [ ] **Step 5: Final commit (if any cleanup needed)**

If any tweaks emerged during smoke testing, commit them:
```bash
git add -p
git commit -m "theme: address smoke-test findings"
```

If nothing remains:
```bash
git status
# expect: working tree clean
```
