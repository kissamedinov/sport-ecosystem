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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white60, size: 20),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
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
            children: [
              ProfileHeader(
                user: user,
                onEdit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                  );
                },
              ),
              Container(
                color: PremiumTheme.deepNavy,
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    CoachProfileBody(coachId: user.id),
                    const SizedBox(height: 24),
                    
                    // Prominent Logout Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GestureDetector(
                        onTap: () {
                          context.read<AuthProvider>().logout();
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                              const SizedBox(width: 12),
                              const Text(
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
}
