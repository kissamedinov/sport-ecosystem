import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_squad_provider.dart';
import '../../../teams/providers/team_provider.dart';
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
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('TOURNAMENT SQUAD', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
      body: Consumer2<TournamentSquadProvider, TeamProvider>(
        builder: (context, squadProvider, teamProvider, _) {
          if (squadProvider.isLoading || teamProvider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen));
          }

          final team = teamProvider.myTeams.firstWhere(
            (t) => t.id == widget.teamId, 
            orElse: () => teamProvider.myTeams.isNotEmpty ? teamProvider.myTeams.first : throw Exception('Team not found')
          ); 
          
          final allPlayers = team.players;

          if (allPlayers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_rounded, size: 64, color: Colors.white.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  const Text('NO PLAYERS FOUND IN THIS TEAM', style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1)),
                ],
              ),
            );
          }

          final squadMembers = squadProvider.squad;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allPlayers.length,
            itemBuilder: (context, index) {
              final playerTeam = allPlayers[index];
              final player = playerTeam.player;
              if (player == null) return const SizedBox.shrink();

              final squadMember = squadMembers.where((m) => m.childProfileId == (playerTeam.childProfileId ?? playerTeam.playerId)).firstOrNull;
              final isInSquad = squadMember != null;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: PremiumTheme.glassDecorationOf(context, radius: 16).copyWith(
                    border: Border.all(
                      color: isInSquad ? PremiumTheme.neonGreen.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isInSquad ? PremiumTheme.neonGreen.withValues(alpha: 0.1) : Colors.white10,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            player.name[0].toUpperCase(),
                            style: TextStyle(
                              color: isInSquad ? PremiumTheme.neonGreen : Colors.white38,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              player.name.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: isInSquad ? Colors.white : Colors.white54,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (isInSquad)
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '#${squadMember.jerseyNumber ?? "???"}',
                                      style: const TextStyle(color: PremiumTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    squadMember.position ?? "TBD",
                                    style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              )
                            else
                              const Text('NOT IN SQUAD', style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isInSquad)
                        _actionBtn(
                          icon: Icons.remove_circle_outline,
                          color: PremiumTheme.danger,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            _removeFromSquad(playerTeam.childProfileId ?? playerTeam.playerId);
                          },
                        )
                      else
                        _actionBtn(
                          icon: Icons.add_circle_outline,
                          color: PremiumTheme.neonGreen,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _showAddDialog(playerTeam.childProfileId ?? playerTeam.playerId, player.name);
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _actionBtn({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  void _showAddDialog(String childProfileId, String playerName) {
    final numberController = TextEditingController();
    final positionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        decoration: BoxDecoration(
          color: PremiumTheme.surfaceCard(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ADD TO SQUAD: ${playerName.toUpperCase()}',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            const SizedBox(height: 24),
            PremiumTextField(
              controller: numberController,
              label: 'JERSEY NUMBER',
              keyboardType: TextInputType.number,
              icon: Icons.numbers,
            ),
            const SizedBox(height: 16),
            PremiumTextField(
              controller: positionController,
              label: 'POSITION (GK, DF, MF, FW)',
              icon: Icons.sports_soccer,
            ),
            const SizedBox(height: 32),
            PremiumButton(
              text: 'CONFIRM ADDITION',
              onPressed: () {
                HapticFeedback.heavyImpact();
                _addToSquad(childProfileId, numberController.text, positionController.text);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
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
