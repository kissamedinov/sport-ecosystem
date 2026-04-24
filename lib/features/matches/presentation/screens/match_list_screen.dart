import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../lineups/providers/lineup_provider.dart';
import '../../../tournaments/data/models/tournament_match.dart';
import 'match_details_screen.dart';

class MatchListScreen extends StatelessWidget {
  const MatchListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final role = user?.roles?.first.toUpperCase() ?? 'PLAYER_ADULT';
    final lineupProvider = context.watch<LineupProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(_getTitleForRole(role))),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          final matchId = 'match_$index';
          
          // Parent Eligibility Check
          bool showForParent = false;
          if (role == 'PARENT' && user?.childIds != null) {
            final lineup = lineupProvider.getLineupForMatch(matchId, 'team_red'); // Mock team
            if (lineup != null) {
              for (final childId in user!.childIds!) {
                if (lineup.players.any((p) => p.playerId == childId)) {
                  showForParent = true;
                  break;
                }
              }
            }
          }

          if (role == 'PARENT' && !showForParent) return const SizedBox.shrink();

          final isChildMatch = role == 'PARENT'; // If we are here, it's a child match
          final isMyTeamMatch = (role == 'COACH' || role == 'PLAYER_ADULT' || role == 'PLAYER_CHILD') && index % 2 == 0;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MatchDetailsScreen(
                    match: TournamentMatch(
                      id: matchId,
                      tournamentId: 'tournament_1',
                      homeTeamId: 'team_red',
                      awayTeamId: 'team_blue',
                      status: 'SCHEDULED',
                      homeScore: 2,
                      awayScore: 1,
                      matchDate: DateTime.now().add(const Duration(hours: 2)),
                    ),
                    homeTeamName: 'RED DRAGONS',
                    awayTeamName: 'BLUE WOLVES',
                  ),
                ),
              );
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  if (isChildMatch)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: const Text(
                        "YOUR CHILD'S MATCH",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                  if (isMyTeamMatch && role != 'PARENT')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: const Text(
                        "MY TEAM",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildTeamColumn('RED DRAGONS', Icons.shield, Colors.red),
                            Column(
                              children: [
                                const Text('2 - 1', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                Text('65\'', style: TextStyle(color: Theme.of(context).primaryColor)),
                              ],
                            ),
                            _buildTeamColumn('BLUE WOLVES', Icons.shield, Colors.blue),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('PREMIER LEAGUE - WEEK 12', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getTitleForRole(String role) {
    switch (role) {
      case 'PARENT':
        return 'CHILDREN MATCHES';
      case 'COACH':
        return 'TEAM FIXTURES';
      case 'FIELD_OWNER':
        return 'FIELD SCHEDULE';
      default:
        return 'LIVE MATCHES';
    }
  }

  Widget _buildTeamColumn(String name, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 40, color: color),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
