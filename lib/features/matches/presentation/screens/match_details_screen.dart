import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../lineups/providers/lineup_provider.dart';
import '../../../lineups/models/lineup.dart';
import '../../../tournaments/data/models/tournament_match.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../lineups/presentation/screens/match_lineup_screen.dart';
import '../../presentation/screens/match_events_screen.dart';
import '../../../player_stats/presentation/screens/player_stats_screen.dart';

class MatchDetailsScreen extends StatefulWidget {
  final TournamentMatch match;
  final String homeTeamName;
  final String awayTeamName;

  const MatchDetailsScreen({
    super.key,
    required this.match,
    required this.homeTeamName,
    required this.awayTeamName,
  });

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LineupProvider>();
      provider.fetchTeamLineup(widget.match.id, widget.match.homeTeamId);
      provider.fetchTeamLineup(widget.match.id, widget.match.awayTeamId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lineupProvider = context.watch<LineupProvider>();
    final user = context.watch<AuthProvider>().user;
    final isCoach = user?.roles?.contains('COACH') ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('MATCH DETAILS')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildScoreBoard(),
            const Divider(),
            _buildLineupSection(
              context,
              widget.homeTeamName,
              widget.match.homeTeamId,
              lineupProvider.getLineupForMatch(widget.match.id, widget.match.homeTeamId),
              isCoach,
            ),
            const Divider(),
            _buildLineupSection(
              context,
              widget.awayTeamName,
              widget.match.awayTeamId,
              lineupProvider.getLineupForMatch(widget.match.id, widget.match.awayTeamId),
              isCoach,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.black12,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTeam(widget.homeTeamName, Colors.red),
              Column(
                children: [
                   Text('${widget.match.homeScore} - ${widget.match.awayScore}', 
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                   Text(widget.match.status, style: const TextStyle(color: Colors.orange)),
                ],
              ),
              _buildTeam(widget.awayTeamName, Colors.blue),
            ],
          ),
          const SizedBox(height: 16),
          Text(widget.match.startTime?.toString().substring(0, 16) ?? 'TBD', 
            style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MatchEventsScreen(matchId: widget.match.id),
                ),
              );
            },
            icon: const Icon(Icons.analytics),
            label: const Text('VIEW STATS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeam(String name, Color color) {
    return Column(
      children: [
        Icon(Icons.shield, size: 60, color: color),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLineupSection(BuildContext context, String teamName, String teamId, MatchLineup? lineup, bool isCoach) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$teamName LINEUP', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (lineup != null)
                const Icon(Icons.check_circle, color: Colors.green)
              else
                const Text('NOT SUBMITTED', style: TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          if (lineup == null) ...[
            const Center(child: Text('No lineup submitted yet.')),
            if (isCoach) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MatchLineupScreen(
                          matchId: widget.match.id,
                          teamId: teamId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('SUBMIT LINEUP'),
                ),
              ),
            ],
          ] else
            _buildLineupList(lineup),
        ],
      ),
    );
  }

  Widget _buildLineupList(MatchLineup lineup) {
    final starters = lineup.players.where((p) => p.isStarting).toList();
    final bench = lineup.players.where((p) => !p.isStarting).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Starting XI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ...starters.map((p) => _buildPlayerTile(p)),
        const SizedBox(height: 12),
        const Text('Substitutes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ...bench.map((p) => _buildPlayerTile(p)),
      ],
    );
  }

  Widget _buildPlayerTile(LineupPlayer p) {
    final id = p.playerId ?? p.childProfileId ?? 'Unknown';
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerStatsScreen(playerId: id),
          ),
        );
      },
      dense: true,
      leading: CircleAvatar(radius: 12, child: Text(p.position ?? '?', style: const TextStyle(fontSize: 10))),
      title: Text('Player ${id.length > 8 ? id.substring(0, 8) : id}'),
      trailing: p.jerseyNumber != null ? Text('#${p.jerseyNumber}') : null,
    );
  }
}
