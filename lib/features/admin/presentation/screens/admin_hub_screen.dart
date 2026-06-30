import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mobile/features/clubs/presentation/screens/admin_requests_screen.dart';
import 'admin_tournaments_screen.dart';
import 'admin_users_screen.dart';
import 'admin_settings_screen.dart';

class AdminHubScreen extends StatelessWidget {
  const AdminHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('admin.admin_console'.tr()),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: GridView.count(
          padding: const EdgeInsets.all(24),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildAdminCard(
              context,
              'admin.club_requests'.tr(),
              Icons.business_rounded,
              Colors.blue,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminClubRequestsScreen())),
            ),
            _buildAdminCard(
              context,
              'admin.tournament_moderation'.tr(),
              Icons.emoji_events_rounded,
              Colors.orange,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTournamentsScreen())),
            ),
            _buildAdminCard(
              context,
              'admin.user_management'.tr(),
              Icons.people_alt_rounded,
              Colors.green,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen())),
            ),
            _buildAdminCard(
              context,
              'admin.system_settings'.tr(),
              Icons.settings_suggest_rounded,
              Colors.purple,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSettingsScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
