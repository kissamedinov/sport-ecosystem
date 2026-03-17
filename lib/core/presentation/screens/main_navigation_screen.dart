import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/features/dashboard/screens/role_router.dart';
import 'package:mobile/features/tournaments/presentation/screens/tournament_list_screen.dart';
import 'package:mobile/features/matches/presentation/screens/match_list_screen.dart';
import 'package:mobile/features/bookings/presentation/screens/booking_screen.dart';
import 'package:mobile/features/profile/presentation/screens/profile_router.dart';
import 'package:mobile/features/football_hub/presentation/screens/football_hub_screen.dart';
import 'package:mobile/features/tournaments/presentation/screens/tournament_announcements_screen.dart';
import 'package:mobile/features/children/presentation/screens/children_activity_screen.dart';
import 'package:mobile/features/fields/presentation/screens/field_management_screen.dart';
import 'package:mobile/features/clubs/presentation/screens/club_dashboard_screen.dart';
import 'package:mobile/features/clubs/providers/club_provider.dart';

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

    final tabs = _getTabsByRole(role);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: tabs.map((t) {
          String label = t.label;
          if (t.label == 'Club') {
            final clubProvider = context.read<ClubProvider>();
            if (clubProvider.dashboard != null) {
              label = clubProvider.dashboard!.club.name;
            }
          }
          return BottomNavigationBarItem(
            icon: Icon(t.icon),
            activeIcon: Icon(t.activeIcon),
            label: label,
          );
        }).toList(),
      ),
    );
  }

  List<_TabItem> _getTabsByRole(String role) {
    // Shared tabs
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
      screen: const ProfileRouter(),
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    );

    // Dynamic 4th tab
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
      case 'CLUB_OWNER':
      case 'CLUB_MANAGER':
        dynamicTab = _TabItem(
          screen: const ClubDashboardScreen(),
          icon: Icons.business_outlined,
          activeIcon: Icons.business,
          label: 'Club',
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
