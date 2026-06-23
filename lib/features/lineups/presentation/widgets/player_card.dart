import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../models/player_lineup_model.dart';

class PlayerCard extends StatelessWidget {
  final PlayerLineupModel player;
  final ValueChanged<bool> onStartingChanged;
  final ValueChanged<String?> onPositionChanged;
  final ValueChanged<int?> onJerseyNumberChanged;

  const PlayerCard({
    super.key,
    required this.player,
    required this.onStartingChanged,
    required this.onPositionChanged,
    required this.onJerseyNumberChanged,
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
        ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
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
                        player.isStarting ? 'team.starting_lineup'.tr() : 'team.substitute'.tr(),
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
                  Text(
                    'team.position_on_field'.tr(),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
                        hint: Text('common.select'.tr()),
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
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Номер джерси',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(
                    width: 80,
                    height: 36,
                    child: TextFormField(
                      initialValue: player.jerseyNumber?.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: '#',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      onChanged: (value) {
                        onJerseyNumberChanged(int.tryParse(value));
                      },
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
