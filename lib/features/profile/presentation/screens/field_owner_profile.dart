import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/data/models/user.dart';
import '../widgets/profile_header.dart';
import '../widgets/field_owner_profile_body.dart';
import 'edit_profile_screen.dart';

class FieldOwnerProfile extends StatelessWidget {
  final User user;
  const FieldOwnerProfile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'PROFILE',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 16,
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
        color: PremiumTheme.surfaceBase(context),
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
                color: PremiumTheme.surfaceBase(context),
                child: const Column(
                  children: [
                    SizedBox(height: 4),
                    FieldOwnerProfileBody(),
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
