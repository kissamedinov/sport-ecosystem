import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../clubs/presentation/screens/club_dashboard_screen.dart';

import 'adult_player_dashboard.dart';
import 'parent_dashboard.dart';
import 'coach_dashboard_screen.dart';
import 'field_owner_dashboard.dart';
import 'child_player_dashboard.dart';
import 'organizer_dashboard_screen.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final role = user?.roles?.first.toUpperCase() ?? 'PLAYER_ADULT';

    switch (role) {
      case 'ADMIN':
      case 'CLUB_OWNER':
      case 'CLUB_MANAGER':
        return const ClubDashboardScreen(isHome: true);
      case 'COACH':
        return const CoachDashboardScreen();
      case 'PARENT':
        return const ParentDashboard();
      case 'FIELD_OWNER':
        return const FieldOwnerDashboard();
      case 'PLAYER_CHILD':
        return const ChildPlayerDashboard();
      case 'TOURNAMENT_ORGANIZER':
        return const OrganizerDashboardScreen();
      case 'PLAYER_ADULT':
      default:
        return const AdultPlayerDashboard();
    }
  }
}
