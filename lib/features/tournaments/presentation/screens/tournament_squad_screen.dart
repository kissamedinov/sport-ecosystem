import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_squad_provider.dart';
import '../../../teams/providers/team_provider.dart';
import '../../../players/presentation/screens/player_profile_screen.dart';

class TournamentSquadScreen extends StatefulWidget {
  final String tournamentTeamId;
  final String teamId;

  const TournamentSquadScreen({
    super.key,
    required this.tournamentTeamId,
    required this.teamId,
  });

  @override
  State<TournamentSquadScreen> createState() => _TournamentSquadScreenState();
}

class _TournamentSquadScreenState extends State<TournamentSquadScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TournamentSquadProvider>().fetchSquad(widget.tournamentTeamId);
      context.read<TeamProvider>().fetchTeamById(widget.teamId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MANAGE TOURNAMENT SQUAD'),
        elevation: 0,
      ),
      body: Consumer2<TournamentSquadProvider, TeamProvider>(
        builder: (context, squadProvider, teamProvider, _) {
          if (squadProvider.isLoading || teamProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (squadProvider.error != null) {
            return Center(child: Text('Error: ${squadProvider.error}'));
          }

          // We need to find the specific team to get its players
          // Since TeamProvider.fetchTeamById doesn't update a common list, 
          // we might need to handle the result differently.
          // For now, let's assume we can find it in 'myTeams' or just await the result.
          // Better: update TeamProvider to store a 'currentTeam' or similar if needed.
          // Let's use a FutureBuilder or just rely on the fact that fetchTeamById might return it.
          
          return FutureBuilder(
            future: teamProvider.fetchTeamById(widget.teamId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final team = snapshot.data;
              if (team == null) {
                return const Center(child: Text('Failed to load team players.'));
              }

              final allPlayers = team.players;
              final squadMembers = squadProvider.squad;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: allPlayers.length,
                itemBuilder: (context, index) {
                  final playerTeam = allPlayers[index];
                  final player = playerTeam.player;
                  if (player == null) return const SizedBox.shrink();

                  final isInSquad = squadMembers.any((m) => m.playerProfileId == playerTeam.playerId);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(player.name[0].toUpperCase()),
                      ),
                      title: Text(player.name),
                      subtitle: Text(player.email),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlayerProfileScreen(
                              userId: playerTeam.playerId,
                              displayName: player.name,
                            ),
                          ),
                        );
                      },
                      trailing: isInSquad
                          ? IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => _removeFromSquad(playerTeam.playerId),
                            )
                          : IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.green),
                              onPressed: () => _addToSquad(playerTeam.playerId),
                            ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _addToSquad(String playerProfileId) {
    // Backend expects list of {player_profile_id, jersey_number, position}
    context.read<TournamentSquadProvider>().addToSquad(
      widget.tournamentTeamId,
      [
        {'player_profile_id': playerProfileId}
      ],
    );
  }

  void _removeFromSquad(String playerProfileId) {
    context.read<TournamentSquadProvider>().removeFromSquad(
      widget.tournamentTeamId,
      playerProfileId,
    );
  }
}
