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
import 'package:mobile/features/clubs/presentation/screens/invite_member_screen.dart';
import 'package:mobile/features/clubs/presentation/screens/create_child_profile_screen.dart';
import 'package:mobile/features/clubs/providers/club_provider.dart';
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

    if (role == 'COACH') {
      return const RoleRouter();
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
            children: List.generate(tabs.length, (i) =>
              _buildNavItem(i, tabs[i].icon, tabs[i].activeIcon, tabs[i].label.toUpperCase()),
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
      const SizedBox.shrink(),
      const NotificationScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: safeIndex,
        children: clubScreens,
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.fromLTRB(16, 0, 16, 10 + bottomPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark
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
                    color: isDark
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
                  Expanded(child: _buildChildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'nav.home'.tr().toUpperCase())),
                  Expanded(child: _buildChildNavItem(1, Icons.business_center_outlined, Icons.business_center_rounded, 'nav.manage'.tr().toUpperCase())),
                  _buildClubAddFab(),
                  Expanded(child: _buildChildNavItem(3, Icons.notifications_outlined, Icons.notifications_rounded, 'nav.inbox'.tr().toUpperCase())),
                  Expanded(child: _buildChildNavItem(4, Icons.person_outline_rounded, Icons.person_rounded, 'nav.profile'.tr().toUpperCase())),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClubAddFab() {
    return Transform.translate(
      offset: const Offset(0, -14),
      child: GestureDetector(
        onTap: _showQuickActions,
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF00E676), Color(0xFF00C853)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF00E676), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E676).withValues(alpha: 0.55),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, color: Colors.black, size: 24),
              const SizedBox(height: 1),
              Text(
                'nav.add'.tr().toUpperCase(),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 8,
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

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
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
              color: isSelected ? PremiumTheme.accent(context) : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? PremiumTheme.accent(context) : Theme.of(context).colorScheme.onSurfaceVariant,
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
      body: IndexedStack(
        index: safeIndex,
        children: childScreens,
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.fromLTRB(16, 0, 16, 10 + bottomPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark
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
                    color: isDark
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
                  Expanded(child: _buildChildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'nav.home'.tr().toUpperCase())),
                  Expanded(child: _buildChildNavItem(1, Icons.emoji_events_outlined, Icons.emoji_events_rounded, 'nav.cup'.tr().toUpperCase())),
                  _buildChildHubFab(),
                  Expanded(child: _buildChildNavItem(3, Icons.notifications_outlined, Icons.notifications_rounded, 'nav.inbox'.tr().toUpperCase())),
                  Expanded(child: _buildChildNavItem(4, Icons.person_outline_rounded, Icons.person_rounded, 'nav.profile'.tr().toUpperCase())),
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
              colors: isSelected
                  ? [accent, const Color(0xFF00C853)]
                  : isDark
                      ? [const Color(0xFF1A3A1A), const Color(0xFF0F250F)]
                      : [accent.withValues(alpha: 0.12), accent.withValues(alpha: 0.06)],
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
              Icon(Icons.hub_rounded, color: isSelected ? Colors.black : accent, size: 22),
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
      body: IndexedStack(
        index: safeIndex,
        children: parentScreens,
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.fromLTRB(16, 0, 16, 10 + bottomPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark
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
                    color: isDark
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
                  Expanded(child: _buildChildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'nav.home'.tr().toUpperCase())),
                  Expanded(child: _buildChildNavItem(1, Icons.emoji_events_outlined, Icons.emoji_events_rounded, 'nav.cup'.tr().toUpperCase())),
                  _buildParentFamilyFab(),
                  Expanded(child: _buildChildNavItem(3, Icons.notifications_outlined, Icons.notifications_rounded, 'nav.inbox'.tr().toUpperCase())),
                  Expanded(child: _buildChildNavItem(4, Icons.person_outline_rounded, Icons.person_rounded, 'nav.profile'.tr().toUpperCase())),
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
              colors: isSelected
                  ? [accent, const Color(0xFFFF6F00)]
                  : isDark
                      ? [const Color(0xFF2A1800), const Color(0xFF1A1000)]
                      : [accent.withValues(alpha: 0.15), accent.withValues(alpha: 0.07)],
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
              Icon(Icons.family_restroom_rounded, color: isSelected ? Colors.black : accent, size: 22),
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
      body: IndexedStack(
        index: safeIndex,
        children: fieldOwnerScreens,
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.fromLTRB(16, 0, 16, 10 + bottomPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark
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
                    color: isDark
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
                  Expanded(child: _buildChildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'nav.home'.tr().toUpperCase())),
                  Expanded(child: _buildChildNavItem(1, Icons.calendar_month_outlined, Icons.calendar_month, 'nav.schedule'.tr().toUpperCase())),
                  _buildFieldOwnerAnalyticsFab(),
                  Expanded(child: _buildChildNavItem(3, Icons.business_outlined, Icons.business, 'nav.management'.tr().toUpperCase())),
                  Expanded(child: _buildChildNavItem(4, Icons.person_outline_rounded, Icons.person_rounded, 'nav.profile'.tr().toUpperCase())),
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
              colors: isSelected
                  ? [accent, const Color(0xFF00C853)]
                  : isDark
                      ? [const Color(0xFF1A3A1A), const Color(0xFF0F250F)]
                      : [accent.withValues(alpha: 0.12), accent.withValues(alpha: 0.06)],
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
            child: Icon(Icons.insights_rounded, color: isSelected ? Colors.black : accent, size: 26),
          ),
        ),
      ),
    );
  }

  Widget _buildChildNavItem(int index, IconData icon, IconData activeIcon, String label) {
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
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActions() {
    final clubId = context.read<ClubProvider>().dashboard?.club.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PremiumTheme.surfaceCard(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: 32 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'nav.quick_actions'.tr().toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                _buildQuickAction(
                  ctx,
                  Icons.group_add_outlined,
                  'nav.invite_member'.tr(),
                  PremiumTheme.electricBlue,
                  () {
                    Navigator.pop(ctx);
                    if (clubId != null) {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => InviteMemberScreen(clubId: clubId),
                      ));
                    }
                  },
                ),
                _buildQuickAction(
                  ctx,
                  Icons.sports_soccer_outlined,
                  'nav.add_player_profile'.tr(),
                  PremiumTheme.neonGreen,
                  () {
                    Navigator.pop(ctx);
                    if (clubId != null) {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => CreateChildProfileScreen(clubId: clubId),
                      ));
                    }
                  },
                ),
                _buildQuickAction(
                  ctx,
                  Icons.shield_outlined,
                  'nav.create_team'.tr(),
                  Colors.tealAccent,
                  () {
                    Navigator.pop(ctx);
                    _showCreateTeamDialog();
                  },
                ),
                _buildQuickAction(
                  ctx,
                  Icons.account_balance_outlined,
                  'nav.add_academy'.tr(),
                  Colors.amber,
                  () {
                    Navigator.pop(ctx);
                    _showCreateAcademyDialog();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateTeamDialog() {
    final nameController = TextEditingController();
    final birthYearController = TextEditingController(text: '2015');
    String? selectedAcademyId;
    final academies = context.read<ClubProvider>().dashboard?.academies ?? [];
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: PremiumTheme.surfaceCard(dialogContext),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('club.create_team_title'.tr(), style: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurface, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (academies.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_rounded, color: Colors.amber, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'club.create_team_academy_warning'.tr(),
                            style: const TextStyle(color: Colors.amber, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  DropdownButtonFormField<String>(
                    dropdownColor: PremiumTheme.surfaceCard(dialogContext),
                    style: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'club.academy_required'.tr(),
                      labelStyle: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurfaceVariant),
                    ),
                    items: academies.map((a) => DropdownMenuItem(
                      value: a.id.toString(),
                      child: Text(a.name),
                    )).toList(),
                    onChanged: (val) => setDialogState(() => selectedAcademyId = val),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'club.team_name_required'.tr(),
                      labelStyle: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurfaceVariant),
                      hintText: 'club.team_name_hint'.tr(),
                      hintStyle: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: birthYearController,
                    style: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'club.birth_year'.tr(),
                      labelStyle: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurfaceVariant),
                      hintText: '2015',
                      hintStyle: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('club.cancel'.tr(), style: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurfaceVariant)),
            ),
            ElevatedButton(
              onPressed: isLoading || academies.isEmpty
                  ? null
                  : () async {
                      if (selectedAcademyId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('club.please_select_academy'.tr())),
                        );
                        return;
                      }
                      if (nameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('club.please_enter_team_name'.tr())),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      final success = await context.read<ClubProvider>().createTeam(
                        selectedAcademyId!,
                        nameController.text,
                        int.tryParse(birthYearController.text) ?? 2015,
                        '',
                      );

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }

                      if (success) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('club.team_created'.tr(namedArgs: {'name': nameController.text})),
                              backgroundColor: PremiumTheme.neonGreen,
                            ),
                          );
                          context.read<ClubProvider>().fetchClubDashboard();
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('club.team_create_failed'.tr()),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: PremiumTheme.accent(dialogContext),
                foregroundColor: Theme.of(dialogContext).colorScheme.onPrimary,
              ),
              child: isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(dialogContext).colorScheme.onPrimary),
                    )
                  : Text('club.create'.tr(), style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateAcademyDialog() {
    final nameController = TextEditingController();
    final cityController = TextEditingController();
    final addressController = TextEditingController();
    final clubId = context.read<ClubProvider>().dashboard?.club.id;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: PremiumTheme.surfaceCard(dialogContext),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('club.add_academy_title'.tr(), style: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurface, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'club.academy_name_required'.tr(),
                  labelStyle: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurfaceVariant),
                  hintText: 'club.academy_name_hint'.tr(),
                  hintStyle: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cityController,
                style: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'club.city_required'.tr(),
                  labelStyle: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurfaceVariant),
                  hintText: 'club.city_hint'.tr(),
                  hintStyle: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                style: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'club.address'.tr(),
                  labelStyle: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurfaceVariant),
                  hintText: 'club.address_hint'.tr(),
                  hintStyle: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('club.cancel'.tr(), style: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurfaceVariant)),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('club.please_enter_academy_name'.tr())),
                        );
                        return;
                      }
                      if (cityController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('club.please_enter_city'.tr())),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      final success = await context.read<ClubProvider>().createAcademy(
                        clubId!, nameController.text, cityController.text, addressController.text,
                      );

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }

                      if (success) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('club.academy_created'.tr(namedArgs: {'name': nameController.text})),
                              backgroundColor: Colors.amber,
                            ),
                          );
                          context.read<ClubProvider>().fetchClubDashboard();
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('club.academy_create_failed'.tr()),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : Text('club.create'.tr(), style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12), size: 14),
            ],
          ),
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
