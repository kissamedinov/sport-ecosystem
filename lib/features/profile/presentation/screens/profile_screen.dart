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
import 'package:mobile/features/profile/presentation/widgets/child_player_profile_body.dart';
import 'package:mobile/features/profile/presentation/widgets/referee_profile_body.dart';
import 'package:mobile/features/notifications/providers/notification_provider.dart';
import 'package:mobile/features/notifications/presentation/screens/notification_screen.dart';
import 'package:mobile/features/settings/presentation/screens/settings_screen.dart';
import 'package:mobile/features/clubs/providers/club_provider.dart';
import 'package:mobile/core/theme/premium_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showProfileMenu(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildMenuItem(Icons.edit_rounded, 'Edit Profile', Colors.white70, () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen()));
            }),
            _buildMenuItem(Icons.notifications_outlined, 'Notifications', Colors.white70, () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
            }),
            _buildMenuItem(Icons.settings_outlined, 'Settings', Colors.white70, () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            }),
            const Divider(color: Colors.white12, height: 24),
            _buildMenuItem(Icons.logout_rounded, 'Logout', Colors.redAccent, () async {
              Navigator.pop(ctx);
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final clubProvider = context.watch<ClubProvider>();
    final clubName = clubProvider.dashboard?.club.name;

    if (user == null) {
      return Scaffold(
        backgroundColor: PremiumTheme.surfaceBase(context),
        body: const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen)),
      );
    }

    final roles = user.roles ?? [];

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileHeader(
              user: user,
              clubName: clubName,
              canPop: Navigator.canPop(context),
              onNotification: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              ),
              onMenu: () => _showProfileMenu(context, auth),
            ),
            _buildRoleSpecificBody(user, roles),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSpecificBody(User user, List<String> roles) {
    if (roles.contains('REFEREE')) {
      return const RefereeProfileBody();
    } else if (roles.contains('CLUB_OWNER')) {
      return const ClubOwnerProfileBody();
    } else if (roles.contains('MANAGER') || roles.contains('CLUB_MANAGER')) {
      return const ManagerProfileBody();
    } else if (roles.contains('COACH')) {
      return CoachProfileBody(coachId: user.id);
    } else if (roles.contains('TOURNAMENT_ORGANIZER')) {
      return CoachProfileBody(coachId: user.id); // Reusing coach body for now as it has dashboard structure
    } else if (roles.contains('PARENT')) {
      return const ParentProfileBody();
    } else if (roles.contains('PLAYER_CHILD')) {
      return ChildPlayerProfileBody(user: user);
    } else if (user.playerProfileId != null &&
               (roles.contains('PLAYER_ADULT') || roles.contains('PLAYER_YOUTH'))) {
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
