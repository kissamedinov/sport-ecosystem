import 'package:flutter/material.dart';
import '../../models/player_lineup_model.dart';

class PlayerCard extends StatelessWidget {
  final PlayerLineupModel player;
  final ValueChanged<bool> onStartingChanged;
  final ValueChanged<String?> onPositionChanged;

  const PlayerCard({
    super.key,
    required this.player,
    required this.onStartingChanged,
    required this.onPositionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> positions = ['GK', 'DF', 'MF', 'FW'];

    return Card(
      elevation: player.isStarting ? 4 : 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: player.isStarting 
          ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
          : BorderSide.none,
      ),
      color: player.isStarting 
        ? Theme.of(context).primaryColor.withOpacity(0.05)
        : null,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: player.isStarting 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey.shade300,
                  child: Icon(
                    Icons.person,
                    color: player.isStarting ? Colors.white : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        player.isStarting ? 'Starting Lineup' : 'Substitute',
                        style: TextStyle(
                          fontSize: 12,
                          color: player.isStarting 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: player.isStarting,
                  onChanged: onStartingChanged,
                  activeThumbColor: Theme.of(context).primaryColor,
                ),
              ],
            ),
            if (player.isStarting) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Position on Field:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: player.position,
                        hint: const Text('Select'),
                        items: positions.map((String pos) {
                          return DropdownMenuItem<String>(
                            value: pos,
                            child: Text(pos),
                          );
                        }).toList(),
                        onChanged: onPositionChanged,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
