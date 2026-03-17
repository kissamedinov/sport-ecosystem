import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/data/models/user.dart';

class CoachProfile extends StatelessWidget {
  final User user;
  const CoachProfile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const CircleAvatar(radius: 50, child: Icon(Icons.sports, size: 50)),
          const SizedBox(height: 16),
          Text('Coach ${user.name}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('COACH / MANAGER', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              final ids = '${user.id}${user.playerProfileId != null ? ' | ${user.playerProfileId}' : ''}';
              Clipboard.setData(ClipboardData(text: ids));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('IDs copied to clipboard'), behavior: SnackBarBehavior.floating),
              );
            },
            child: Text(
              'User ID: ${user.id.substring(0, 8)}... | Prof: ${user.playerProfileId?.substring(0, 8) ?? 'N/A'}...',
              style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: 24),
          _buildStatsRow(),
          const SizedBox(height: 24),
          _buildTeamsManaged(),
          const SizedBox(height: 24),
          _buildLogoutCard(context),
        ],
      ),
    );
  }

  Widget _buildLogoutCard(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        onTap: () async {
          await context.read<AuthProvider>().logout();
        },
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Teams', '3'),
        _buildStatItem('Tournaments', '5'),
        _buildStatItem('Reports', '42'),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTeamsManaged() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Managed Teams', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.shield),
          title: const Text('Tigers U12'),
          subtitle: const Text('Academy: Elite Sports'),
        ),
        ListTile(
          leading: const Icon(Icons.shield),
          title: const Text('Lions U10'),
          subtitle: const Text('Academy: Elite Sports'),
        ),
      ],
    );
  }
}
