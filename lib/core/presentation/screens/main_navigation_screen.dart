import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/features/dashboard/screens/role_router.dart';
import 'package:mobile/features/tournaments/presentation/screens/tournament_list_screen.dart';
import 'package:mobile/features/matches/presentation/screens/match_list_screen.dart';
import 'package:mobile/features/bookings/presentation/screens/booking_screen.dart';
import 'package:mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:mobile/features/football_hub/presentation/screens/football_hub_screen.dart';
import 'package:mobile/features/tournaments/presentation/screens/tournament_announcements_screen.dart';
import 'package:mobile/features/children/presentation/screens/children_activity_screen.dart';
import 'package:mobile/features/fields/presentation/screens/field_management_screen.dart';
import 'package:mobile/features/clubs/presentation/screens/club_dashboard_screen.dart';
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

    final tabs = _getTabsByRole(role);
    final safeIndex = _selectedIndex.clamp(0, tabs.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: tabs.map((t) {
          return BottomNavigationBarItem(
            icon: Icon(t.icon),
            activeIcon: Icon(t.activeIcon),
            label: t.label,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildClubNav(BuildContext context) {
    final safeIndex = _selectedIndex.clamp(0, 3);

    final clubScreens = [
      const RoleRouter(),
      const ClubDashboardScreen(isHome: false),
      const NotificationScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: clubScreens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickActions,
        backgroundColor: PremiumTheme.neonGreen,
        foregroundColor: Colors.black,
        elevation: 6,
        child: const Icon(Icons.add, size: 28, weight: 700),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF0D1117),
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildClubNavItem(0, Icons.home_outlined, Icons.home_rounded, 'HOME'),
              _buildClubNavItem(1, Icons.business_center_outlined, Icons.business_center_rounded, 'MANAGE'),
              const SizedBox(width: 56),
              _buildClubNavItem(2, Icons.notifications_outlined, Icons.notifications_rounded, 'INBOX'),
              _buildClubNavItem(3, Icons.person_outline_rounded, Icons.person_rounded, 'PROFILE'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClubNavItem(int index, IconData icon, IconData activeIcon, String label) {
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
              color: isSelected ? PremiumTheme.neonGreen : Colors.white38,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? PremiumTheme.neonGreen : Colors.white38,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'QUICK ACTIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.white38,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickAction(Icons.group_add_outlined, 'Invite Member', Colors.blue),
            _buildQuickAction(Icons.sports_soccer_outlined, 'Add Player Profile', PremiumTheme.neonGreen),
            _buildQuickAction(Icons.shield_outlined, 'Create Team', PremiumTheme.neonGreen),
            _buildQuickAction(Icons.account_balance_outlined, 'Add Academy', Colors.amber),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context),
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
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white12, size: 14),
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
      label: 'Home',
    );

    final tournamentTab = _TabItem(
      screen: const TournamentListScreen(),
      icon: Icons.emoji_events_outlined,
      activeIcon: Icons.emoji_events,
      label: 'Tournaments',
    );

    final matchTab = _TabItem(
      screen: const MatchListScreen(),
      icon: Icons.sports_soccer_outlined,
      activeIcon: Icons.sports_soccer,
      label: 'Matches',
    );

    final profileTab = _TabItem(
      screen: const ProfileScreen(),
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    );

    _TabItem dynamicTab;
    switch (role) {
      case 'PLAYER_CHILD':
        dynamicTab = _TabItem(
          screen: const FootballHubScreen(),
          icon: Icons.hub_outlined,
          activeIcon: Icons.hub,
          label: 'Hub',
        );
        break;
      case 'COACH':
        dynamicTab = _TabItem(
          screen: const TournamentAnnouncementsScreen(),
          icon: Icons.campaign_outlined,
          activeIcon: Icons.campaign,
          label: 'Events',
        );
        break;
      case 'PARENT':
        dynamicTab = _TabItem(
          screen: const ChildrenActivityScreen(),
          icon: Icons.child_care_outlined,
          activeIcon: Icons.child_care,
          label: 'Activity',
        );
        break;
      case 'FIELD_OWNER':
        dynamicTab = _TabItem(
          screen: const FieldManagementScreen(),
          icon: Icons.business_outlined,
          activeIcon: Icons.business,
          label: 'Management',
        );
        break;
      default:
        dynamicTab = _TabItem(
          screen: const BookingScreen(),
          icon: Icons.calendar_today_outlined,
          activeIcon: Icons.calendar_today,
          label: 'Booking',
        );
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
