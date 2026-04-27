# Light Theme — Design Spec

**Date:** 2026-04-27
**Project:** sport-ecosystem (Flutter mobile app)
**Status:** Approved for implementation planning

## Goal

Add a fully functional light theme with a user-facing toggle (System / Light / Dark), persisted across app launches. Default on first launch is `ThemeMode.system`.

## Scope

This spec follows a **hybrid strategy**: ship the theme infrastructure plus migration of high-traffic screens in this PR, with deeper feature areas deferred to a follow-up.

**In scope (P1):**
- `ThemeProvider` with `SharedPreferences` persistence
- `AppTheme.light` (new) and refactored `AppTheme.dark` sharing common tokens
- `PremiumTheme` refactored to context-aware getters (covers ~56 files automatically)
- New `SettingsScreen` with appearance toggle
- Direct hardcoded color migration in: auth (3), main navigation (1), profile (10), dashboards (5)
- Wiring into `MaterialApp` via `MultiProvider` in `main.dart`

**Out of scope (deferred to P2 follow-up):**
- Tournament screens (details, list, leaderboard, squad, lineup, match report, announcements, create)
- Match screens (live, lineup, events, details, list, dialogs, awards)
- Academy screens (dashboard, training management, team details)
- Team / Club screens (dashboard, management, invitations, member invite)
- Onboarding flow widgets
- Notifications screen
- Media gallery / upload screens
- Lineups feature screens
- Booking / Field booking screens
- Children flow (list, add, management, profile, activity)
- Player stats screens and widgets
- Admin screens
- `core/presentation/widgets/orleon_widgets.dart`, `premium_widgets.dart`

These remain visually correct in dark mode and inherit the `PremiumTheme` refactor benefit (any usage of `PremiumTheme.deepNavy` etc. becomes theme-aware automatically). Direct `Colors.white` / hex literals in those files will render correctly in dark and need follow-up migration to look correct in light.

## Architecture

### File structure

```
lib/core/theme/
├── app_theme.dart           # MODIFIED: extract base tokens, add AppTheme.light
├── premium_theme.dart       # MODIFIED: context-aware getters
└── theme_provider.dart      # NEW: ChangeNotifier with SharedPreferences

lib/features/settings/
└── presentation/
    └── screens/
        └── settings_screen.dart   # NEW
```

### Provider wiring (`main.dart`)

1. `WidgetsFlutterBinding.ensureInitialized()` before `runApp`.
2. Synchronously load `SharedPreferences` instance, pass to `ThemeProvider` constructor — this avoids any flash of wrong theme at startup.
3. Add `ChangeNotifierProvider(create: (_) => ThemeProvider(prefs))` to the existing `MultiProvider` (placed first so all screens have access).
4. `SportsApp.build` reads `context.watch<ThemeProvider>()` and passes:
   ```dart
   theme: AppTheme.light,
   darkTheme: AppTheme.dark,
   themeMode: themeProvider.themeMode,
   ```

## Components

### `ThemeProvider`

```dart
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
    await _prefs.setString(_key, _encode(mode));
  }

  static String _encode(ThemeMode m) => m.name;
  static ThemeMode? _decode(String? s) =>
      ThemeMode.values.where((m) => m.name == s).firstOrNull;
}
```

- Source of truth is in-memory `_mode`. UI updates immediately on change; persistence is fire-and-forget after `notifyListeners()`. If the write fails, the user still sees the new theme — they just lose the preference on next cold start. This is acceptable for a UI preference.
- Default on first launch (no persisted value): `ThemeMode.system`.

### `AppTheme.light`

ColorScheme:
```dart
ColorScheme.light(
  primary:          Color(0xFF00C853),  // muted neonGreen for contrast on white
  secondary:        Color(0xFF2962FF),
  surface:          Colors.white,
  surfaceTint:      Colors.transparent,
  onPrimary:        Colors.white,
  onSecondary:      Colors.white,
  onSurface:        Color(0xFF1A1A1A),
  onSurfaceVariant: Color(0xFF757575),
  outline:          Color(0xFFE0E0E0),
)
scaffoldBackgroundColor: Color(0xFFF5F5F5)
```

Component themes (light-specific overrides):
- `appBarTheme` — `backgroundColor: Colors.white`, `foregroundColor: 0xFF1A1A1A`, `elevation: 0`, `centerTitle: true`.
- `cardTheme` — `color: Colors.white`, `surfaceTintColor: Colors.transparent`, `elevation: 0`, radius 12, **add 1px outline border** via shape (cards on `0xFFF5F5F5` background lose definition without it).
- `bottomNavigationBarTheme` — `backgroundColor: Colors.white`, `selectedItemColor: primary`, `unselectedItemColor: 0xFF757575`.
- `elevatedButtonTheme` — `backgroundColor: primary`, `foregroundColor: Colors.white` (in dark it's `Colors.black`; on the muted green of light theme white reads better).
- `inputDecorationTheme` — `fillColor: Colors.white`, `enabledBorder` with `0xFFE0E0E0`, `focusedBorder` with primary.
- `dividerTheme` — `color: 0xFFE0E0E0`.
- `listTileTheme` — `tileColor: Colors.transparent`, `textColor: 0xFF1A1A1A`, `iconColor: 0xFF757575`.
- `textTheme` — `GoogleFonts.outfitTextTheme()` without hardcoded `color:` so M3 picks up `colorScheme.onSurface` per theme.

### `AppTheme` refactor

Extract a private `_buildTheme(ColorScheme cs, {required Brightness brightness})` so `light` and `dark` differ only by `ColorScheme` and a few component overrides — avoids duplicating ~80 lines. Existing dark theme behavior is preserved bit-for-bit.

### `PremiumTheme` — context-aware

Brand constants stay constants (theme-independent):
- `neonGreen`, `electricBlue`, `danger`, `amber`, `gold`, `silver`, `bronze`
- All gradients (`primaryGradient`, `secondaryGradient`, `liveRedGradient`, `pitchGradient`)

Theme-dependent values become **methods taking `BuildContext`**:

```dart
class PremiumTheme {
  // Theme-aware accent green — matches AppTheme primary per brightness.
  // Use this for UI accents (focus borders, input icons, link text) so that
  // they stay visually consistent with the ColorScheme's primary in both themes.
  // The raw `neonGreen` constant remains for fixed brand uses (gradients, brand marks).
  static Color accent(BuildContext c) =>
      _isDark(c) ? neonGreen : const Color(0xFF00C853);

  static Color surfaceBase(BuildContext c) =>
      _isDark(c) ? const Color(0xFF0A0E12) : const Color(0xFFF5F5F5);

  static Color surfaceCard(BuildContext c) =>
      _isDark(c) ? const Color(0xFF161B22) : Colors.white;

  static Color borderSubtle(BuildContext c) =>
      _isDark(c) ? const Color(0xFF30363D) : const Color(0xFFE0E0E0);

  static List<BoxShadow> softShadow(BuildContext c) {
    final dark = _isDark(c);
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? 0.20 : 0.08),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static BoxDecoration glassDecoration(BuildContext c, {double radius = 16}) {
    final dark = _isDark(c);
    final tint = dark ? Colors.white : Colors.black;
    return BoxDecoration(
      color: tint.withValues(alpha: dark ? 0.05 : 0.04),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: tint.withValues(alpha: dark ? 0.10 : 0.08)),
    );
  }

  static InputDecoration inputDecoration(BuildContext c, String label, {IconData? prefixIcon}) {
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

  static bool _isDark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;
}
```

**Old constants removed:** `deepNavy`, `cardNavy`, `borderGrey`. The compiler error becomes the migration checklist for the 56 files using them.

`glassEffect` (the `BackdropFilter` wrapper) is unchanged — it's a structural wrapper; the visual effect comes from the child decoration.

### `SettingsScreen`

```dart
Scaffold(
  appBar: AppBar(title: const Text('Settings')),
  body: ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _SectionHeader(label: 'Appearance'),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Theme'),
            const SizedBox(height: 12),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.phone_android), label: Text('System')),
                ButtonSegment(value: ThemeMode.light,  icon: Icon(Icons.light_mode),    label: Text('Light')),
                ButtonSegment(value: ThemeMode.dark,   icon: Icon(Icons.dark_mode),     label: Text('Dark')),
              ],
              selected: {context.watch<ThemeProvider>().themeMode},
              onSelectionChanged: (set) => context.read<ThemeProvider>().setThemeMode(set.first),
            ),
            const SizedBox(height: 8),
            Text('Choose how the app looks. "System" follows your device.', style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      ),
    ],
  ),
)
```

Navigation: in `lib/features/profile/presentation/screens/profile_screen.dart`, the dead `Settings` item (line 51) becomes `Navigator.push(MaterialPageRoute(builder: (_) => const SettingsScreen()))`.

## Migration Plan (P1 files)

### Replacement rules

| Pattern | Replacement |
|---|---|
| `Colors.white` (background/surface) | `Theme.of(context).colorScheme.surface` |
| `Colors.white` (text on brand-colored buttons) | `Theme.of(context).colorScheme.onPrimary` (or keep literal if on a fixed brand color) |
| `Colors.white70` (secondary text) | `Theme.of(context).colorScheme.onSurfaceVariant` |
| `Colors.white12` / `Colors.white24` (dividers) | `Theme.of(context).dividerColor` or `colorScheme.outline.withValues(alpha: 0.12)` |
| `Colors.black` (text) | `Theme.of(context).colorScheme.onSurface` |
| `Color(0xFF1C1C1E)`, `0xFF161B22`, `0xFF0A0E12` (surfaces) | `PremiumTheme.surfaceCard(context)` / `surfaceBase(context)` |
| `Color(0xFF30363D)` (borders) | `PremiumTheme.borderSubtle(context)` |

**Untouched:**
- Brand colors: `neonGreen`, `electricBlue`, `gold`, `silver`, `bronze`, `danger`, `amber`.
- Icons and image assets.
- Gradients on accent elements.

### File list (in commit order)

1. **Auth** — `splash_screen.dart`, `login_screen.dart`, `register_screen.dart`
2. **Main navigation** — `core/presentation/screens/main_navigation_screen.dart`
3. **Profile** — `profile_screen.dart`, `profile_header.dart`, all 7 role-specific `*_profile_body.dart` files, `edit_profile_screen.dart`
4. **Dashboards** — `adult_player_dashboard.dart`, `parent_dashboard.dart`, `coach_dashboard_screen.dart`, `child_player_dashboard.dart`, `field_owner_dashboard.dart`

### Commit blocks

1. `theme: extract base theme tokens, add AppTheme.light`
2. `theme: add ThemeProvider with SharedPreferences persistence`
3. `theme: wire ThemeMode into MaterialApp`
4. `theme: refactor PremiumTheme to context-aware getters`
5. `feat(settings): add SettingsScreen with appearance toggle`
6. `theme: migrate auth screens to colorScheme`
7. `theme: migrate main navigation`
8. `theme: migrate profile screens`
9. `theme: migrate dashboards`

Each commit must end with a clean `flutter analyze`.

## Error Handling

- **`SharedPreferences` write failure:** silently log via `debugPrint`, keep in-memory state. User sees correct theme this session; preference is lost on cold start. No user-facing error — preference toggles are not critical-path.
- **Missing/corrupt persisted value:** `_decode` returns `null` → falls back to `ThemeMode.system`.
- **`ThemeProvider` not found in tree:** standard Provider error. Mitigated by registering it as the first provider in the `MultiProvider`.

## Testing

- `flutter analyze` clean after every commit (no new warnings).
- Manual smoke flow in **both themes** end-to-end: splash → login → register → home (bottom nav) → each role's dashboard → profile → settings → toggle each of System / Light / Dark → verify persistence via app restart → logout.
- Each P1 screen visually inspected in both themes for: white-on-white text, illegible borders, broken contrast on disabled states, surface tint regressions on cards.
- Unit test for `ThemeProvider`: encode/decode round-trip, default fallback to `system`, `setThemeMode` notifies listeners and writes to mock `SharedPreferences`. (Single test file, no widget tests — project has no widget test setup.)

## Risks

- **Local `Theme(data: ...)` overrides** in some screens may hardcode dark values; surface during the visual review pass.
- **M3 surface tint** can paint cards with primary tint unexpectedly. Already disabled in dark via `surfaceTint: Colors.transparent`; replicate in light theme component overrides.
- **Explicit `Text(style: TextStyle(color: ...))`** is common in this codebase. Where the literal color is theme-dependent (white/black), prefer dropping the explicit color and letting M3 inherit from `colorScheme.onSurface`. Where it's a brand color (e.g. accent text), keep the literal.
- **Out-of-scope screens in light mode** will visibly clash if a user toggles to Light and navigates into them. This is accepted — they remain functional and readable, just not visually polished. Documented in P2 follow-up.

## Out-of-Scope Follow-Up (P2)

A separate spec/plan will cover migration of:
- Tournament feature (8 screens)
- Match feature (5+ screens, dialogs)
- Academy feature (3+ screens)
- Team / Club feature (5+ screens)
- Onboarding (5 widgets)
- Notifications, media gallery, lineups, bookings, children, player stats, admin
- Shared widgets in `core/presentation/widgets/` (`orleon_widgets.dart`, `premium_widgets.dart`)

After this spec ships, P2 work can proceed file-by-file using the same replacement rules and commit discipline established here.
