import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/providers/auth_provider.dart';
import 'club_owner_profile.dart';
import 'adult_player_profile.dart';
import 'child_player_profile.dart';
import 'parent_profile.dart';
import 'coach_profile.dart';
import 'field_owner_profile.dart';
import '../widgets/coach_profile_body.dart';

class ProfileRouter extends StatelessWidget {
  const ProfileRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const Center(child: Text('Please log in'));

    final role = user.roles?.first ?? 'PLAYER_ADULT';

    return Scaffold(
      body: _getProfileByRole(role, user),
    );
  }

  Widget _getProfileByRole(String role, user) {
    switch (role) {
      case 'CLUB_OWNER':
      case 'CLUB_MANAGER':
        return ClubOwnerProfile(user: user);
      case 'COACH':
        return CoachProfile(user: user);
      case 'PARENT':
        return ParentProfile(user: user);
      case 'FIELD_OWNER':
        return FieldOwnerProfile(user: user);
      case 'PLAYER_CHILD':
        return ChildPlayerProfile(user: user);
      case 'PLAYER_ADULT':
      default:
        return AdultPlayerProfile(user: user);
    }
  }
}
