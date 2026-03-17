import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/providers/auth_provider.dart';
import 'adult_player_profile.dart';
import 'child_player_profile.dart';
import 'parent_profile.dart';
import 'coach_profile.dart';
import 'field_owner_profile.dart';

class ProfileRouter extends StatelessWidget {
  const ProfileRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const Center(child: Text('Please log in'));

    final role = user.roles?.first.toUpperCase() ?? 'PLAYER_ADULT';

    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFILE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: _getProfileByRole(role, user),
    );
  }

  Widget _getProfileByRole(String role, user) {
    switch (role) {
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
