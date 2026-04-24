import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/auth/data/models/user.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/features/profile/presentation/widgets/profile_header.dart';
import 'package:mobile/features/profile/presentation/widgets/club_owner_profile_body.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/features/profile/presentation/screens/edit_profile_screen.dart';

class ClubOwnerProfile extends StatelessWidget {
  final User user;  

  const ClubOwnerProfile({super.key, required this.user});

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
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
            tooltip: 'Quit',
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        color: PremiumTheme.deepNavy,
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
                child: const Column(
                  children: [
                    SizedBox(height: 4),
                    ClubOwnerProfileBody(),
                    SizedBox(height: 40),
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
