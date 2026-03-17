import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/squad_provider.dart';

class SquadSelectionScreen extends StatefulWidget {
  final String tournamentId;
  final String teamId;

  const SquadSelectionScreen({
    super.key,
    required this.tournamentId,
    required this.teamId,
  });

  @override
  State<SquadSelectionScreen> createState() => _SquadSelectionScreenState();
}

class _SquadSelectionScreenState extends State<SquadSelectionScreen> {
  final List<String> _selectedPlayerIds = [];
  static const int maxSquadSize = 15;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SELECT TOURNAMENT SQUAD'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(child: Text('${_selectedPlayerIds.length}/$maxSquadSize')),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: 20, // Mock player count for the team
        itemBuilder: (context, index) {
          final playerId = 'player_$index';
          final isSelected = _selectedPlayerIds.contains(playerId);

          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text('Player $index'),
            subtitle: const Text('Team Player'),
            trailing: Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    if (_selectedPlayerIds.length < maxSquadSize) {
                      _selectedPlayerIds.add(playerId);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Squad limit reached (15 players)')),
                      );
                    }
                  } else {
                    _selectedPlayerIds.remove(playerId);
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
          onPressed: _selectedPlayerIds.isEmpty
              ? null
              : () async {
                  await context.read<SquadProvider>().buildSquad(
                        widget.tournamentId,
                        widget.teamId,
                        _selectedPlayerIds,
                      );
                  if (mounted) Navigator.pop(context);
                },
          child: const Text('SUBMIT SQUAD'),
        ),
      ),
    );
  }
}
