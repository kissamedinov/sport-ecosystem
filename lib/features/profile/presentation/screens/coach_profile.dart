import 'package:flutter/material.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:mobile/features/auth/data/models/user.dart';
import 'package:mobile/features/profile/presentation/widgets/profile_header.dart';
import 'package:mobile/features/profile/presentation/widgets/coach_profile_body.dart';
import 'package:mobile/core/theme/premium_theme.dart';

class CoachProfile extends StatelessWidget {
  final User user;

  const CoachProfile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.deepNavy,
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileHeader(
              user: user,
              canPop: Navigator.canPop(context),
              onEdit: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ),
            ),
            CoachProfileBody(coachId: user.id),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
              child: GestureDetector(
                onTap: () {
                  context.read<AuthProvider>().logout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'LOGOUT',
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
          ],
        ),
      ),
    );
  }
}
