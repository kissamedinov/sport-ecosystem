import 'package:flutter/material.dart';
import 'package:mobile/features/profile/presentation/screens/edit_profile_screen.dart';
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
            fontSize: 14,
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
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [
              PremiumTheme.electricBlue.withOpacity(0.05),
              PremiumTheme.deepNavy,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileHeader(
                user: user,
                onEdit: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen()));
                },
              ),
              Container(
                color: PremiumTheme.deepNavy,
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    _buildRoleSpecificBody(user, roles),
                    const SizedBox(height: 32),
                    
                    // Unified Premium Logout
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GestureDetector(
                        onTap: () {
                          auth.logout();
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.1)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                              SizedBox(width: 12),
                              Text(
                                "LOGOUT / QUIT SESSION",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
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
