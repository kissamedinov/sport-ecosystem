import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/features/auth/data/models/user.dart';
import 'package:mobile/features/academies/presentation/screens/academy_dashboard_screen.dart';
import 'package:mobile/features/clubs/presentation/screens/player_career_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFILE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              auth.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildProfileHeader(context, user),
            const SizedBox(height: 32),
            _buildStatGrid(),
            const SizedBox(height: 32),
            _buildProfileMenu(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, User? user) {
    return Column(
      children: [
        Stack(
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white10,
              child: Icon(Icons.person, size: 60, color: Colors.white30),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF00E676),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, size: 20, color: Colors.black),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          user?.name ?? 'Guest User',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          user?.email ?? '',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            if (user != null) {
              final ids = '${user.id}${user.playerProfileId != null ? ' | ${user.playerProfileId}' : ''}';
              Clipboard.setData(ClipboardData(text: ids));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('IDs copied to clipboard'), behavior: SnackBarBehavior.floating),
              );
            }
          },
          child: Text(
            'User ID: ${user?.id.substring(0, 8)}... | Prof: ${user?.playerProfileId?.substring(0, 8) ?? 'N/A'}...',
            style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('MATCHES', '24'),
        _buildStatItem('GOALS', '12'),
        _buildStatItem('ASSISTS', '8'),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00E676)),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildProfileMenu(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Column(
      children: [
        _buildMenuItem(Icons.person_outline, 'Personal Info'),
        _buildMenuItem(Icons.shield_outlined, 'My Teams'),
        if (auth.user?.playerProfileId != null)
          _buildMenuItem(
            Icons.history,
            'Career History',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlayerCareerScreen(profileId: auth.user!.playerProfileId!),
                ),
              );
            },
          ),
        _buildMenuItem(Icons.history, 'Match History'),
        if (auth.user?.roles?.contains('coach') == true || auth.user?.roles?.contains('admin') == true)
          _buildMenuItem(
            Icons.school_outlined,
            'Academy Management',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AcademyDashboardScreen()),
              );
            },
          ),
        _buildMenuItem(Icons.settings_outlined, 'Settings'),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {VoidCallback? onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(title),
        onTap: onTap ?? () {},
      ),
    );
  }
}
