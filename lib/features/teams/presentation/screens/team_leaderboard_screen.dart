import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/team_provider.dart';
import '../../data/models/team.dart';
import 'team_details_screen.dart';

class TeamLeaderboardScreen extends StatefulWidget {
  const TeamLeaderboardScreen({super.key});

  @override
  State<TeamLeaderboardScreen> createState() => _TeamLeaderboardScreenState();
}

class _TeamLeaderboardScreenState extends State<TeamLeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeamProvider>().fetchTeamRankings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GLOBAL RANKINGS'),
        elevation: 0,
      ),
      body: Consumer<TeamProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.rankings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.rankings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.error_outline, size: 48, color: Colors.red),
                   const SizedBox(height: 16),
                   Text('Error: ${provider.error}'),
                   ElevatedButton(
                     onPressed: () => provider.fetchTeamRankings(),
                     child: const Text('Retry'),
                   ),
                ],
              ),
            );
          }

          if (provider.rankings.isEmpty) {
            return const Center(child: Text('No team rankings available.'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchTeamRankings(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.rankings.length,
              itemBuilder: (context, index) {
                final team = provider.rankings[index];
                return _buildLeaderboardTile(team, index + 1);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardTile(Team team, int rank) {
    final color = _getRankColor(rank);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeamDetailsScreen(teamId: team.id),
            ),
          );
        },
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          team.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.location_on, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(team.city, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(width: 12),
            const Icon(Icons.groups, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(team.ageCategory ?? 'Open', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${team.rating}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.orangeAccent[400],
              ),
            ),
            const Text(
              'ELO RATING',
              style: TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.grey[400]!;
    if (rank == 3) return Colors.brown[300]!;
    return Colors.blueGrey[400]!;
  }
}
