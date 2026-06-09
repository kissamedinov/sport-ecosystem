import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/features/dashboard/screens/role_router.dart';
import 'package:mobile/features/tournaments/presentation/screens/tournament_list_screen.dart';
import 'package:mobile/features/matches/presentation/screens/match_list_screen.dart';
import 'package:mobile/features/bookings/presentation/screens/booking_screen.dart';
import 'package:mobile/features/bookings/presentation/screens/organizer_logistics_screen.dart';
import 'package:mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:mobile/features/football_hub/presentation/screens/football_hub_screen.dart';
import 'package:mobile/features/tournaments/presentation/screens/tournament_announcements_screen.dart';
import 'package:mobile/features/children/presentation/screens/children_activity_screen.dart';
import 'package:mobile/features/fields/presentation/screens/field_management_screen.dart';
import 'package:mobile/features/fields/presentation/screens/owner_calendar_screen.dart';
import 'package:mobile/features/fields/presentation/screens/owner_analytics_screen.dart';
import 'package:mobile/features/clubs/presentation/screens/club_dashboard_screen.dart';
import 'package:mobile/features/clubs/presentation/screens/club_quick_actions_screen.dart';
import 'package:mobile/features/notifications/presentation/screens/notification_screen.dart';
import 'package:mobile/core/theme/premium_theme.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final role = user?.roles?.first.toUpperCase() ?? 'PLAYER_ADULT';

    if (role == 'CLUB_OWNER' || role == 'CLUB_MANAGER' || role == 'ADMIN') {
      return _buildClubNav(context);
    }

    if (role == 'PLAYER_CHILD') {
      return _buildChildNav(context);
    }

    if (role == 'PARENT') {
      return _buildParentNav(context);
    }

    if (role == 'FIELD_OWNER') {
      return _buildFieldOwnerNav(context);
    }

    if (role == 'PLAYER_ADULT' || role == 'PLAYER_YOUTH') {
      return _buildAdultPlayerNav(context);
    }

    if (role == 'COACH') {
      return const RoleRouter();
    }

    if (role == 'REFEREE') {
      return _buildRefereeNav(context);
    }

    final tabs = _getTabsByRole(role);
    final safeIndex = _selectedIndex.clamp(0, tabs.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: BottomAppBar(
        color: PremiumTheme.surfaceCard(context),
        elevation: 0,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              tabs.length,
              (i) => _buildNavItem(
                i,
                tabs[i].icon,
                tabs[i].activeIcon,
                tabs[i].label.toUpperCase(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClubNav(BuildContext context) {
    final safeIndex = _selectedIndex.clamp(0, 4);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final clubScreens = [
      const RoleRouter(),
      const ClubDashboardScreen(isHome: false),
      const ClubQuickActionsScreen(),
      const NotificationScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: safeIndex, children: clubScreens),
      bottomNavigationBar: Container(
        margin: EdgeInsets.fromLTRB(16, 0, 16, 10 + bottomPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.07),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    color:
                        isDark
                            ? const Color(0xFF161B22).withValues(alpha: 0.62)
                            : Colors.white.withValues(alpha: 0.68),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildChildNavItem(
                      0,
                      Icons.home_outlined,
                      Icons.home_rounded,
                      'nav.home'.tr().toUpperCase(),
                    ),
                  ),
                  Expanded(
                    child: _buildChildNavItem(
                      1,
                      Icons.business_center_outlined,
                      Icons.business_center_rounded,
                      'nav.manage'.tr().toUpperCase(),
                    ),
                  ),
                  _buildClubAddFab(),
                  Expanded(
                    child: _buildChildNavItem(
                      3,
                      Icons.notifications_outlined,
                      Icons.notifications_rounded,
                      'nav.inbox'.tr().toUpperCase(),
                    ),
                  ),
                  Expanded(
                    child: _buildChildNavItem(
                      4,
                      Icons.person_outline_rounded,
                      Icons.person_rounded,
                      'nav.profile'.tr().toUpperCase(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClubAddFab() {
    final isSelected = _selectedIndex == 2;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = Color(0xFF00E676);
    return Transform.translate(
      offset: const Offset(0, -12),
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = 2),
        child: Container(
          width: 54,
          height: 54,
          margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF00E676), Color(0xFF00C853)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : isDark
                  ? const Color(0xFF1A3A1A)
                  : accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: accent.withValues(alpha: isSelected ? 1.0 : 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: isSelected ? 0.4 : 0.1),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
          child: Center(
            child: Icon(
              Icons.add_rounded,
              color: isSelected ? Colors.black : accent,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color:
                  isSelected
                      ? PremiumTheme.accent(context)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color:
                    isSelected
                        ? PremiumTheme.accent(context)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildNav(BuildContext context) {
    final safeIndex = _selectedIndex.clamp(0, 4);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final childScreens = [
      const RoleRouter(),
      const TournamentListScreen(),
      const FootballHubScreen(),
      const NotificationScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: safeIndex, children: childScreens),
      bottomNavigationBar: Container(
        margin: EdgeInsets.fromLTRB(16, 0, 16, 10 + bottomPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.07),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    color:
                        isDark
                            ? const Color(0xFF161B22).withValues(alpha: 0.62)
                            : Colors.white.withValues(alpha: 0.68),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildChildNavItem(
                      0,
                      Icons.home_outlined,
                      Icons.home_rounded,
                      'nav.home'.tr().toUpperCase(),
                    ),
                  ),
                  Expanded(
                    child: _buildChildNavItem(
                      1,
                      Icons.emoji_events_outlined,
                      Icons.emoji_events_rounded,
                      'nav.cup'.tr().toUpperCase(),
                    ),
                  ),
                  _buildChildHubFab(),
                  Expanded(
                    child: _buildChildNavItem(
                      3,
                      Icons.notifications_outlined,
                      Icons.notifications_rounded,
                      'nav.inbox'.tr().toUpperCase(),
                    ),
                  ),
                  Expanded(
                    child: _buildChildNavItem(
                      4,
                      Icons.person_outline_rounded,
                      Icons.person_rounded,
                      'nav.profile'.tr().toUpperCase(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildHubFab() {
    final isSelected = _selectedIndex == 2;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = Color(0xFF00E676);
    return Transform.translate(
      offset: const Offset(0, -14),
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = 2),
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  isSelected
                      ? [accent, const Color(0xFF00C853)]
                      : isDark
                      ? [const Color(0xFF1A3A1A), const Color(0xFF0F250F)]
                      : [
                        accent.withValues(alpha: 0.12),
                        accent.withValues(alpha: 0.06),
                      ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: accent.withValues(alpha: isSelected ? 1.0 : 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: isSelected ? 0.55 : 0.15),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hub_rounded,
                color: isSelected ? Colors.black : accent,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                'nav.hub'.tr().toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.black : accent,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParentNav(BuildContext context) {
    final safeIndex = _selectedIndex.clamp(0, 4);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final parentScreens = [
      const RoleRouter(),
      const TournamentListScreen(),
      const ChildrenActivityScreen(),
      const NotificationScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: safeIndex, children: parentScreens),
      bottomNavigationBar: Container(
        margin: EdgeInsets.fromLTRB(16, 0, 16, 10 + bottomPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.07),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    color:
                        isDark
                            ? const Color(0xFF161B22).withValues(alpha: 0.62)
                            : Colors.white.withValues(alpha: 0.68),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildChildNavItem(
                      0,
                      Icons.home_outlined,
                      Icons.home_rounded,
                      'nav.home'.tr().toUpperCase(),
                    ),
                  ),
                  Expanded(
                    child: _buildChildNavItem(
                      1,
                      Icons.emoji_events_outlined,
                      Icons.emoji_events_rounded,
                      'nav.cup'.tr().toUpperCase(),
                    ),
                  ),
                  _buildParentFamilyFab(),
                  Expanded(
                    child: _buildChildNavItem(
                      3,
                      Icons.notifications_outlined,
                      Icons.notifications_rounded,
                      'nav.inbox'.tr().toUpperCase(),
                    ),
                  ),
                  Expanded(
                    child: _buildChildNavItem(
                      4,
                      Icons.person_outline_rounded,
                      Icons.person_rounded,
                      'nav.profile'.tr().toUpperCase(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParentFamilyFab() {
    final isSelected = _selectedIndex == 2;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = Color(0xFFFFA726);
    return Transform.translate(
      offset: const Offset(0, -14),
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = 2),
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  isSelected
                      ? [accent, const Color(0xFFFF6F00)]
                      : isDark
                      ? [const Color(0xFF2A1800), const Color(0xFF1A1000)]
                      : [
                        accent.withValues(alpha: 0.15),
                        accent.withValues(alpha: 0.07),
                      ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: accent.withValues(alpha: isSelected ? 1.0 : 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: isSelected ? 0.55 : 0.15),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.family_restroom_rounded,
                color: isSelected ? Colors.black : accent,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                'nav.family'.tr().toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.black : accent,
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldOwnerNav(BuildContext context) {
    final safeIndex = _selectedIndex.clamp(0, 4);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fieldOwnerScreens = [
      const RoleRouter(),
      const OwnerCalendarScreen(),
      const OwnerAnalyticsScreen(),
      const FieldManagementScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: safeIndex, children: fieldOwnerScreens),
      bottomNavigationBar: Container(
        margin: EdgeInsets.fromLTRB(16, 0, 16, 10 + bottomPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.07),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    color:
                        isDark
                            ? const Color(0xFF161B22).withValues(alpha: 0.62)
                            : Colors.white.withValues(alpha: 0.68),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildChildNavItem(
                      0,
                      Icons.home_outlined,
                      Icons.home_rounded,
                      'nav.home'.tr().toUpperCase(),
                    ),
                  ),
                  Expanded(
                    child: _buildChildNavItem(
                      1,
                      Icons.calendar_month_outlined,
                      Icons.calendar_month,
                      'nav.schedule'.tr().toUpperCase(),
                    ),
                  ),
                  _buildFieldOwnerAnalyticsFab(),
                  Expanded(
                    child: _buildChildNavItem(
                      3,
                      Icons.business_outlined,
                      Icons.business,
                      'nav.management'.tr().toUpperCase(),
                    ),
                  ),
                  Expanded(
                    child: _buildChildNavItem(
                      4,
                      Icons.person_outline_rounded,
                      Icons.person_rounded,
                      'nav.profile'.tr().toUpperCase(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldOwnerAnalyticsFab() {
    final isSelected = _selectedIndex == 2;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = Color(0xFF00E676);
    return Transform.translate(
      offset: const Offset(0, -14),
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = 2),
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  isSelected
                      ? [accent, const Color(0xFF00C853)]
                      : isDark
                      ? [const Color(0xFF1A3A1A), const Color(0xFF0F250F)]
                      : [
                        accent.withValues(alpha: 0.12),
                        accent.withValues(alpha: 0.06),
                      ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: accent.withValues(alpha: isSelected ? 1.0 : 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: isSelected ? 0.55 : 0.15),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.insights_rounded,
              color: isSelected ? Colors.black : accent,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdultMatchFab() {
    final isSelected = _selectedIndex == 2;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = Color(0xFF00E676);
    return Transform.translate(
      offset: const Offset(0, -14),
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = 2),
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  isSelected
                      ? [accent, const Color(0xFF00C853)]
                      : isDark
                      ? [const Color(0xFF1A3A1A), const Color(0xFF0F250F)]
                      : [
                        accent.withValues(alpha: 0.12),
                        accent.withValues(alpha: 0.06),
                      ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: accent.withValues(alpha: isSelected ? 1.0 : 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: isSelected ? 0.55 : 0.15),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.sports_soccer_rounded,
              color: isSelected ? Colors.black : accent,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRefereeNav(BuildContext context) {
    final safeIndex = _selectedIndex.clamp(0, 2);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final refereeScreens = [
      const RoleRouter(),
      const TournamentListScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: safeIndex, children: refereeScreens),
      bottomNavigationBar: Container(
        margin: EdgeInsets.fromLTRB(16, 0, 16, 10 + bottomPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.07),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    color: isDark
                        ? const Color(0xFF161B22).withValues(alpha: 0.62)
                        : Colors.white.withValues(alpha: 0.68),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildRefereeNavItem(
                      0,
                      Icons.home_outlined,
                      Icons.home_rounded,
                      'nav.home'.tr().toUpperCase(),
                    ),
                  ),
                  _buildRefereeTournamentFab(),
                  Expanded(
                    child: _buildRefereeNavItem(
                      2,
                      Icons.person_outline_rounded,
                      Icons.person_rounded,
                      'nav.profile'.tr().toUpperCase(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefereeNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _selectedIndex == index;
    const activeColor = Color(0xFF00E676);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? Colors.white60 : Colors.black54;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : icon, color: isSelected ? activeColor : inactiveColor, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefereeTournamentFab() {
    final isSelected = _selectedIndex == 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = Color(0xFF00E676);
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = 1),
      child: Container(
        width: 58,
        height: 58,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [accent, const Color(0xFF00C853)]
                : isDark
                    ? [const Color(0xFF1A3A1A), const Color(0xFF0F250F)]
                    : [accent.withValues(alpha: 0.12), accent.withValues(alpha: 0.06)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: accent.withValues(alpha: isSelected ? 1.0 : 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: isSelected ? 0.4 : 0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.emoji_events_rounded,
            color: isSelected ? Colors.black : accent,
            size: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildAdultPlayerNav(BuildContext context) {
    final safeIndex = _selectedIndex.clamp(0, 4);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final adultScreens = [
      const RoleRouter(),
      const TournamentListScreen(),
      const MatchListScreen(),
      const BookingScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: safeIndex, children: adultScreens),
      bottomNavigationBar: Container(
        margin: EdgeInsets.fromLTRB(16, 0, 16, 10 + bottomPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.07),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    color:
                        isDark
                            ? const Color(0xFF161B22).withValues(alpha: 0.62)
                            : Colors.white.withValues(alpha: 0.68),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildChildNavItem(
                      0,
                      Icons.home_outlined,
                      Icons.home_rounded,
                      'nav.home'.tr().toUpperCase(),
                    ),
                  ),
                  Expanded(
                    child: _buildChildNavItem(
                      1,
                      Icons.emoji_events_outlined,
                      Icons.emoji_events_rounded,
                      'nav.cup'.tr().toUpperCase(),
                    ),
                  ),
                  _buildAdultMatchFab(),
                  Expanded(
                    child: _buildChildNavItem(
                      3,
                      Icons.stadium_outlined,
                      Icons.stadium_rounded,
                      'nav.booking'.tr().toUpperCase(),
                    ),
                  ),
                  Expanded(
                    child: _buildChildNavItem(
                      4,
                      Icons.person_outline_rounded,
                      Icons.person_rounded,
                      'nav.profile'.tr().toUpperCase(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = _selectedIndex == index;
    final activeColor = const Color(0xFF00E676);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? Colors.white38 : Colors.black45;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }


  List<_TabItem> _getTabsByRole(String role) {
    final homeTab = _TabItem(
      screen: const RoleRouter(),
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'nav.home'.tr(),
    );

    final tournamentTab = _TabItem(
      screen: const TournamentListScreen(),
      icon: Icons.emoji_events_outlined,
      activeIcon: Icons.emoji_events,
      label: 'nav.tournaments'.tr(),
    );

    final matchTab = _TabItem(
      screen: const MatchListScreen(),
      icon: Icons.sports_soccer_outlined,
      activeIcon: Icons.sports_soccer,
      label: 'nav.matches'.tr(),
    );

    final profileTab = _TabItem(
      screen: const ProfileScreen(),
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'nav.profile'.tr(),
    );

    _TabItem dynamicTab;
    switch (role) {
      case 'PLAYER_CHILD':
        dynamicTab = _TabItem(
          screen: const FootballHubScreen(),
          icon: Icons.hub_outlined,
          activeIcon: Icons.hub,
          label: 'nav.hub'.tr(),
        );
        break;
      case 'COACH':
        dynamicTab = _TabItem(
          screen: const TournamentAnnouncementsScreen(),
          icon: Icons.campaign_outlined,
          activeIcon: Icons.campaign,
          label: 'nav.events'.tr(),
        );
        break;
      case 'PARENT':
        dynamicTab = _TabItem(
          screen: const ChildrenActivityScreen(),
          icon: Icons.child_care_outlined,
          activeIcon: Icons.child_care,
          label: 'nav.activity'.tr(),
        );
        break;
      case 'FIELD_OWNER':
        dynamicTab = _TabItem(
          screen: const FieldManagementScreen(),
          icon: Icons.business_outlined,
          activeIcon: Icons.business,
          label: 'nav.management'.tr(),
        );
        break;
      case 'TOURNAMENT_ORGANIZER':
        dynamicTab = _TabItem(
          screen: const OrganizerLogisticsScreen(),
          icon: Icons.inventory_2_outlined,
          activeIcon: Icons.inventory_2,
          label: 'nav.logistics'.tr(),
        );
        break;
      default:
        dynamicTab = _TabItem(
          screen: const BookingScreen(),
          icon: Icons.calendar_today_outlined,
          activeIcon: Icons.calendar_today,
          label: 'nav.booking'.tr(),
        );
    }

    if (role == 'FIELD_OWNER') {
      return [
        homeTab,
        _TabItem(
          screen: const OwnerCalendarScreen(),
          icon: Icons.calendar_month_outlined,
          activeIcon: Icons.calendar_month,
          label: 'nav.schedule'.tr(),
        ),
        _TabItem(
          screen: const OwnerAnalyticsScreen(),
          icon: Icons.insights_outlined,
          activeIcon: Icons.insights,
          label: 'nav.analytics'.tr(),
        ),
        dynamicTab,
        profileTab,
      ];
    }

    return [homeTab, tournamentTab, matchTab, dynamicTab, profileTab];
  }
}

class _TabItem {
  final Widget screen;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  _TabItem({
    required this.screen,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
