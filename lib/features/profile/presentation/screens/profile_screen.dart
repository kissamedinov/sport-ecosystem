import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/features/auth/data/models/user.dart';
import 'package:mobile/features/profile/presentation/widgets/profile_header.dart';
import 'package:mobile/features/profile/presentation/widgets/player_profile_body.dart';
import 'package:mobile/features/profile/presentation/widgets/parent_profile_body.dart';
import 'package:mobile/features/profile/presentation/widgets/coach_profile_body.dart';
import 'package:mobile/features/profile/presentation/widgets/club_owner_profile_body.dart';
import 'package:mobile/features/profile/presentation/widgets/manager_profile_body.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final roles = user.roles ?? [];
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('PROFILE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () {
              auth.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileHeader(user: user),
            const SizedBox(height: 16),
            _buildRoleSpecificBody(user, roles),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSpecificBody(User user, List<String> roles) {
    // Priority: CLUB_OWNER > MANAGER > COACH > PARENT > PLAYER
    if (roles.contains('CLUB_OWNER')) {
      return const ClubOwnerProfileBody();
    } else if (roles.contains('MANAGER')) {
      return const ManagerProfileBody();
    } else if (roles.contains('COACH')) {
      return CoachProfileBody(coachId: user.id);
    } else if (roles.contains('PARENT')) {
      return const ParentProfileBody();
    } else if (user.playerProfileId != null) {
      return PlayerProfileBody(playerProfileId: user.playerProfileId!);
    } else {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            "Account setup in progress. Please contact your club administrator.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
  }
}
