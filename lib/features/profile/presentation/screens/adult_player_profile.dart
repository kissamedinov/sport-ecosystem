import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/data/models/user.dart';
import '../../../player_stats/providers/player_stats_provider.dart';

class AdultPlayerProfile extends StatelessWidget {
  final User user;
  const AdultPlayerProfile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
          const SizedBox(height: 16),
          Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(user.email, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          _buildStatsRow(context),
          const SizedBox(height: 24),
          _buildTeamList(),
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

  Widget _buildStatsRow(BuildContext context) {
    final stats = context.watch<PlayerStatsProvider>().getCareerStats(user.id);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Matches', stats.matchesPlayed.toString()),
        _buildStatItem('Goals', stats.totalGoals.toString()),
        _buildStatItem('Assists', stats.totalAssists.toString()),
        _buildStatItem('MVP', stats.totalMvpAwards.toString()),
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

  Widget _buildTeamList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('My Teams', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.group),
          title: const Text('Sunday Warriors'),
          subtitle: const Text('Position: Midfielder'),
        ),
      ],
    );
  }
}
