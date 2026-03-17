import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_squad_provider.dart';
import '../../data/models/tournament_squad_member.dart';

class MatchLineupScreen extends StatefulWidget {
  final String matchId;
  final String tournamentTeamId;
  final String teamId;
  final bool isHomeTeam;

  const MatchLineupScreen({
    super.key,
    required this.matchId,
    required this.tournamentTeamId,
    required this.teamId,
    this.isHomeTeam = true,
  });

  @override
  State<MatchLineupScreen> createState() => _MatchLineupScreenState();
}

class _MatchLineupScreenState extends State<MatchLineupScreen> {
  // Maps player_profile_id -> {is_starting, jersey_number}
  final Map<String, Map<String, dynamic>> _selections = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TournamentSquadProvider>().fetchSquad(widget.tournamentTeamId);
    });
  }

  int get _startingCount =>
      _selections.values.where((s) => s['is_starting'] == true).length;

  void _toggleSelection(TournamentSquadMember member) {
    setState(() {
      if (_selections.containsKey(member.playerProfileId)) {
        _selections.remove(member.playerProfileId);
      } else {
        _selections[member.playerProfileId] = {
          'player_profile_id': member.playerProfileId,
          'jersey_number': member.jerseyNumber,
          'is_starting': _startingCount < 11,
        };
      }
    });
  }

  void _toggleStarting(String playerId) {
    setState(() {
      if (_selections.containsKey(playerId)) {
        _selections[playerId]!['is_starting'] =
            !(_selections[playerId]!['is_starting'] as bool);
      }
    });
  }

  Future<void> _submit() async {
    if (_selections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one player.')),
      );
      return;
    }

    final players = _selections.values.toList();
    final success = await context.read<TournamentSquadProvider>().submitLineup(
          widget.matchId,
          widget.teamId,
          players,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Lineup submitted!' : 'Failed to submit lineup.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MATCH LINEUP'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Text(
                '$_startingCount / 11 Starting',
                style: TextStyle(
                  color: _startingCount == 11 ? Colors.green : Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<TournamentSquadProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          if (provider.squad.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No squad members found. Please add players to the tournament squad first.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: provider.squad.length,
                  itemBuilder: (context, index) {
                    final member = provider.squad[index];
                    final isSelected = _selections.containsKey(member.playerProfileId);
                    final isStarting = isSelected &&
                        (_selections[member.playerProfileId]!['is_starting'] as bool);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isStarting
                          ? Colors.green.withOpacity(0.15)
                          : isSelected
                              ? Colors.orange.withOpacity(0.10)
                              : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isStarting
                              ? Colors.green
                              : isSelected
                                  ? Colors.orange
                                  : Colors.grey.shade700,
                          child: Text(
                            member.jerseyNumber?.toString() ??
                                (index + 1).toString(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          member.playerProfileId.substring(0, 8).toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          isStarting
                              ? 'Starting XI'
                              : isSelected
                                  ? 'Substitute'
                                  : member.position ?? 'Not selected',
                          style: TextStyle(
                            color: isStarting
                                ? Colors.green
                                : isSelected
                                    ? Colors.orange
                                    : Colors.grey,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              Tooltip(
                                message: isStarting
                                    ? 'Move to bench'
                                    : 'Set as starter',
                                child: IconButton(
                                  icon: Icon(
                                    isStarting
                                        ? Icons.sports_soccer
                                        : Icons.airline_seat_recline_normal,
                                    color: isStarting
                                        ? Colors.green
                                        : Colors.orange,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      _toggleStarting(member.playerProfileId),
                                ),
                              ),
                            Checkbox(
                              value: isSelected,
                              activeColor: Colors.orangeAccent,
                              onChanged: (_) => _toggleSelection(member),
                            ),
                          ],
                        ),
                        onTap: () => _toggleSelection(member),
                      ),
                    );
                  },
                ),
              ),
              _buildLegend(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: provider.isLoading ? null : _submit,
                    icon: const Icon(Icons.send),
                    label: const Text('SUBMIT LINEUP'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _legendItem(Colors.green, 'Starting XI'),
          const SizedBox(width: 16),
          _legendItem(Colors.orange, 'Substitute'),
          const SizedBox(width: 16),
          _legendItem(Colors.grey, 'Not selected'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
