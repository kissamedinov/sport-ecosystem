import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/match_report.dart';
import '../../providers/match_report_provider.dart';
import '../../../lineups/models/lineup.dart';

class MatchStatsEntryScreen extends StatefulWidget {
  final MatchLineup lineup;

  const MatchStatsEntryScreen({
    super.key,
    required this.lineup,
  });

  @override
  State<MatchStatsEntryScreen> createState() => _MatchStatsEntryScreenState();
}

class _MatchStatsEntryScreenState extends State<MatchStatsEntryScreen> {
  final Map<String, MatchPlayerStats> _playerStats = {};
  int _homeScore = 0;
  int _awayScore = 0;

  @override
  void initState() {
    super.initState();
    for (final lp in widget.lineup.players) {
      final key = lp.playerId ?? lp.childProfileId ?? '';
      _playerStats[key] = MatchPlayerStats(
        id: DateTime.now().millisecondsSinceEpoch.toString() + key,
        matchId: widget.lineup.matchId,
        playerId: lp.playerId,
        childProfileId: lp.childProfileId,
        teamId: widget.lineup.teamId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ENTER MATCH STATISTICS'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildScoreControl('Home', _homeScore, (val) => setState(() => _homeScore = val)),
                const Text(' - ', style: TextStyle(fontSize: 32)),
                _buildScoreControl('Away', _awayScore, (val) => setState(() => _awayScore = val)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: widget.lineup.players.length,
              itemBuilder: (context, index) {
                final lp = widget.lineup.players[index];
                final key = lp.playerId ?? lp.childProfileId ?? '';
                final stats = _playerStats[key]!;

                return ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: lp.isStarting ? Colors.green : Colors.grey,
                    child: Text(lp.isStarting ? 'S' : 'B'),
                  ),
                  title: Text('Player ${key.length > 8 ? key.substring(0, 8) : key}'),
                  subtitle: Text('Goals: ${stats.goals} | Assists: ${stats.assists} | MVP: ${stats.isMvp ? "YES" : "NO"}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          _buildStatCounter('Goals', stats.goals, (v) => _updateStats(key, goals: v)),
                          _buildStatCounter('Assists', stats.assists, (v) => _updateStats(key, assists: v)),
                          CheckboxListTile(
                            title: const Text('MVP'),
                            value: stats.isMvp,
                            onChanged: (v) => _updateStats(key, isMvp: v ?? false),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () async {
            final report = MatchReport(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              matchId: widget.lineup.matchId,
              managerId: 'current_manager_id',
              submittedAt: DateTime.now(),
              homeScore: _homeScore,
              awayScore: _awayScore,
              playerStats: _playerStats.values.toList(),
            );

            await context.read<MatchReportProvider>().submitReport(report);
            if (mounted) Navigator.pop(context);
          },
          child: const Text('SUBMIT MATCH REPORT'),
        ),
      ),
    );
  }

  void _updateStats(String key, {int? goals, int? assists, bool? isMvp}) {
    setState(() {
      final old = _playerStats[key]!;
      _playerStats[key] = MatchPlayerStats(
        id: old.id,
        matchId: old.matchId,
        playerId: old.playerId,
        childProfileId: old.childProfileId,
        teamId: old.teamId,
        goals: goals ?? old.goals,
        assists: assists ?? old.assists,
        isMvp: isMvp ?? old.isMvp,
      );

      // Ensure only one MVP
      if (isMvp == true) {
        for (final k in _playerStats.keys) {
          if (k != key) {
            final st = _playerStats[k]!;
            _playerStats[k] = MatchPlayerStats(
              id: st.id,
              matchId: st.matchId,
              playerId: st.playerId,
              childProfileId: st.childProfileId,
              teamId: st.teamId,
              goals: st.goals,
              assists: st.assists,
              isMvp: false,
            );
          }
        }
      }
    });
  }

  Widget _buildScoreControl(String label, int value, ValueChanged<int> onChanged) {
    return Column(
      children: [
        Text(label),
        Row(
          children: [
            IconButton(icon: const Icon(Icons.remove), onPressed: () => value > 0 ? onChanged(value - 1) : null),
            Text('$value', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.add), onPressed: () => onChanged(value + 1)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCounter(String label, int value, ValueChanged<int> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Row(
          children: [
            IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => value > 0 ? onChanged(value - 1) : null),
            Text('$value'),
            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => onChanged(value + 1)),
          ],
        ),
      ],
    );
  }
}
