import 'package:flutter/material.dart';
import 'package:mobile/features/auth/data/models/user.dart';
import 'package:mobile/features/profile/presentation/widgets/profile_header.dart';
import 'package:mobile/features/profile/presentation/widgets/club_owner_profile_body.dart';
import 'package:mobile/core/theme/premium_theme.dart';

class ClubOwnerProfile extends StatelessWidget {
  final User user;

  const ClubOwnerProfile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.deepNavy,
      extendBodyBehindAppBar: false,
      body: Container(
        color: PremiumTheme.deepNavy,
        child: SingleChildScrollView(
          child: Column(
            children: [
              ProfileHeader(user: user),
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
