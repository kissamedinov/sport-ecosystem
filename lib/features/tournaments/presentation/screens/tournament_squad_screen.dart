import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_squad_provider.dart';
import '../../../teams/providers/team_provider.dart';
import '../../../players/presentation/screens/player_profile_screen.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';

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
      backgroundColor: PremiumTheme.deepNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('TOURNAMENT SQUAD', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
      body: Consumer2<TournamentSquadProvider, TeamProvider>(
        builder: (context, squadProvider, teamProvider, _) {
          if (squadProvider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen));
          }

          final team = teamProvider.myTeams.firstWhere((t) => t.id == widget.teamId, orElse: () => teamProvider.myTeams.isNotEmpty ? teamProvider.myTeams.first : teamProvider.myTeams.first); 
          
          final allPlayers = teamProvider.myTeams.any((t) => t.id == widget.teamId) 
              ? teamProvider.myTeams.firstWhere((t) => t.id == widget.teamId).players 
              : [];

          if (allPlayers.isEmpty) {
            return const Center(child: Text('No players found in this team', style: TextStyle(color: Colors.white38)));
          }

          final squadMembers = squadProvider.squad;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: allPlayers.length,
            itemBuilder: (context, index) {
              final playerTeam = allPlayers[index];
              final player = playerTeam.player;
              if (player == null) return const SizedBox.shrink();

              final squadMember = squadMembers.where((m) => m.childProfileId == (playerTeam.childProfileId ?? playerTeam.playerId)).firstOrNull;
              final isInSquad = squadMember != null;

              return PremiumCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                      child: Text(player.name[0].toUpperCase(), style: const TextStyle(color: PremiumTheme.neonGreen)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(player.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          if (isInSquad)
                            Text(
                              '#${squadMember.jerseyNumber ?? "???"} | ${squadMember.position ?? "TBD"}',
                              style: const TextStyle(color: PremiumTheme.neonGreen, fontSize: 11, fontWeight: FontWeight.bold),
                            )
                          else
                            const Text('Not in squad', style: TextStyle(color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ),
                    if (isInSquad)
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: PremiumTheme.danger),
                        onPressed: () => _removeFromSquad(playerTeam.childProfileId ?? playerTeam.playerId),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: PremiumTheme.neonGreen),
                        onPressed: () => _showAddDialog(playerTeam.childProfileId ?? playerTeam.playerId, player.name),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddDialog(String childProfileId, String playerName) {
    final numberController = TextEditingController();
    final positionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PremiumTheme.cardNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('ADD $playerName', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PremiumTextField(
              controller: numberController,
              label: 'Jersey Number',
              keyboardType: TextInputType.number,
              icon: Icons.numbers,
            ),
            const SizedBox(height: 16),
            PremiumTextField(
              controller: positionController,
              label: 'Position (e.g. GK, DEF, ST)',
              icon: Icons.sports_soccer,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () {
              _addToSquad(childProfileId, numberController.text, positionController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: PremiumTheme.neonGreen, foregroundColor: Colors.black),
            child: const Text('ADD TO SQUAD'),
          ),
        ],
      ),
    );
  }

  void _addToSquad(String childProfileId, String number, String position) {
    context.read<TournamentSquadProvider>().addToSquad(
      widget.tournamentTeamId,
      [
        {
          'child_profile_id': childProfileId,
          'jersey_number': int.tryParse(number),
          'position': position,
        }
      ],
    );
  }

  void _removeFromSquad(String childProfileId) {
    context.read<TournamentSquadProvider>().removeFromSquad(
      widget.tournamentTeamId,
      childProfileId,
    );
  }
}
