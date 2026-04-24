import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_squad_provider.dart';
import '../../data/models/tournament_squad_member.dart';
import '../../../lineups/providers/lineup_provider.dart';
import '../../../lineups/models/lineup.dart';

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
  // Maps player_profile_id -> {is_starting, position}
  final Map<String, bool> _starters = {};
  final Map<String, String> _positions = {};
  final List<String> _positionOptions = ['GK', 'DF', 'MF', 'FW'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TournamentSquadProvider>().fetchSquad(widget.tournamentTeamId);
    });
  }

  int get _startingCount => _starters.values.where((v) => v).length;

  void _toggleSelection(TournamentSquadMember member) {
    setState(() {
      if (_starters.containsKey(member.childProfileId)) {
        _starters.remove(member.childProfileId);
        _positions.remove(member.childProfileId);
      } else {
        _starters[member.childProfileId] = _startingCount < 11;
        _positions[member.childProfileId] = member.position ?? 'MF';
      }
    });
  }

  void _toggleStarting(String childProfileId) {
    setState(() {
      if (_starters.containsKey(childProfileId)) {
        _starters[childProfileId] = !(_starters[childProfileId]!);
      }
    });
  }

  Future<void> _submit() async {
    if (_starters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one player.')),
      );
      return;
    }

    final lineupPlayers = _starters.keys.map((pid) => LineupPlayer(
      childProfileId: pid,
      isStarting: _starters[pid]!,
      position: _positions[pid],
    )).toList();

    final lineupRequest = MatchLineup(
      id: '',
      matchId: widget.matchId,
      teamId: widget.teamId,
      status: LineupStatus.SUBMITTED,
      createdAt: DateTime.now(),
      players: lineupPlayers,
    );

    try {
      await context.read<LineupProvider>().submitLineup(
            widget.matchId,
            lineupRequest,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lineup submitted successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lineupProvider = context.watch<LineupProvider>();
    
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
          if (provider.isLoading || lineupProvider.isLoading) {
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
                    final isSelected = _starters.containsKey(member.childProfileId);
                    final isStarting = isSelected && _starters[member.childProfileId]!;

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
                          member.childProfileId.substring(0, 8).toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Row(
                          children: [
                             Text(
                              isStarting
                                  ? 'Starting'
                                  : isSelected
                                      ? 'Substitute'
                                      : 'Not selected',
                              style: TextStyle(
                                color: isStarting
                                    ? Colors.green
                                    : isSelected
                                        ? Colors.orange
                                        : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              const Text('| Port: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              DropdownButton<String>(
                                value: _positions[member.playerProfileId],
                                isDense: true,
                                style: const TextStyle(fontSize: 12, color: Colors.white),
                                items: _positionOptions.map((pos) => DropdownMenuItem(
                                  value: pos,
                                  child: Text(pos),
                                )).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _positions[member.childProfileId] = val!;
                                  });
                                },
                              ),
                            ]
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              IconButton(
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
                                    _toggleStarting(member.childProfileId),
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
                    onPressed: (provider.isLoading || lineupProvider.isLoading) ? null : _submit,
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
