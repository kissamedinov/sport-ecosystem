import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/lineup.dart';
import '../../providers/lineup_provider.dart';
import '../../../squads/models/squad.dart';

class LineupSubmissionScreen extends StatefulWidget {
  final TournamentSquad squad;
  final String matchId;

  const LineupSubmissionScreen({
    super.key,
    required this.squad,
    required this.matchId,
  });

  @override
  State<LineupSubmissionScreen> createState() => _LineupSubmissionScreenState();
}

class _LineupSubmissionScreenState extends State<LineupSubmissionScreen> {
  final List<String> _starters = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SUBMIT MATCH LINEUP'),
            Text('Squad: ${widget.squad.playerIds.length} players', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: widget.squad.playerIds.length,
        itemBuilder: (context, index) {
          final playerId = widget.squad.playerIds[index];
          final isStarter = _starters.contains(playerId);

          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text('Player $playerId'),
            trailing: Switch(
              value: isStarter,
              onChanged: (value) {
                setState(() {
                  if (value) {
                    _starters.add(playerId);
                  } else {
                    _starters.remove(playerId);
                  }
                });
              },
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () async {
            final players = widget.squad.playerIds.map((id) => LineupPlayer(
              playerId: id,
              isStarting: _starters.contains(id),
            )).toList();

            await context.read<LineupProvider>().submitLineup(
              widget.matchId,
              widget.squad.teamId,
              players,
            );
            if (mounted) Navigator.pop(context);
          },
          child: const Text('SUBMIT LINEUP'),
        ),
      ),
    );
  }
}
