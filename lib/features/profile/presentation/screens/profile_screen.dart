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
import 'package:mobile/core/theme/premium_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        backgroundColor: PremiumTheme.deepNavy,
        body: Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen)),
      );
    }

    final roles = user.roles ?? [];

    return Scaffold(
      backgroundColor: PremiumTheme.deepNavy,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'PROFILE',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white70),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20, color: Colors.white70),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            onPressed: () {
              auth.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      // KEY FIX: Wrap entire scrollable area with deep navy background
      body: Container(
        color: PremiumTheme.deepNavy,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileHeader(user: user),
              // Dark background container wrapping the body content
              Container(
                color: PremiumTheme.deepNavy,
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    _buildRoleSpecificBody(user, roles),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSpecificBody(User user, List<String> roles) {
    if (roles.contains('CLUB_OWNER')) {
      return const ClubOwnerProfileBody();
    } else if (roles.contains('MANAGER') || roles.contains('CLUB_MANAGER')) {
      return const ManagerProfileBody();
    } else if (roles.contains('COACH')) {
      return CoachProfileBody(coachId: user.id);
    } else if (roles.contains('PARENT')) {
      return const ParentProfileBody();
    } else if (user.playerProfileId != null &&
               (roles.contains('PLAYER_ADULT') || roles.contains('PLAYER_CHILD') || roles.contains('PLAYER_YOUTH'))) {
      return PlayerProfileBody(playerProfileId: user.playerProfileId!);
    } else {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            "Account setup in progress. Please contact your club administrator.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38),
          ),
        ),
      );
    }
  }
}
