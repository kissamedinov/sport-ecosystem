import 'package:flutter/material.dart';
import '../../../../core/theme/premium_theme.dart';

class MatchEventDialog extends StatefulWidget {
  final String matchId;
  final String homeTeamId;
  final String awayTeamId;
  final String homeTeamName;
  final String awayTeamName;

  const MatchEventDialog({
    super.key,
    required this.matchId,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeTeamName,
    required this.awayTeamName,
  });

  @override
  State<MatchEventDialog> createState() => _MatchEventDialogState();
}

class _MatchEventDialogState extends State<MatchEventDialog> {
  String _selectedType = 'GOAL';
  String? _selectedTeamId;
  final _minuteController = TextEditingController();
  final _playerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTeamId = widget.homeTeamId;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: PremiumTheme.surfaceCard(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('RECORD EVENT', style: TextStyle(color: Colors.white, letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              dropdownColor: PremiumTheme.surfaceCard(context),
              initialValue: _selectedType,
              style: const TextStyle(color: Colors.white),
              decoration: PremiumTheme.inputDecorationOf(context, 'Event Type'),
              items: const [
                DropdownMenuItem(value: 'GOAL', child: Text('⚽ GOAL')),
                DropdownMenuItem(value: 'YELLOW_CARD', child: Text('🟨 YELLOW CARD')),
                DropdownMenuItem(value: 'RED_CARD', child: Text('🟥 RED CARD')),
                DropdownMenuItem(value: 'SUBSTITUTION', child: Text('🔄 SUBSTITUTION')),
              ],
              onChanged: (val) => setState(() => _selectedType = val!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              dropdownColor: PremiumTheme.surfaceCard(context),
              initialValue: _selectedTeamId,
              style: const TextStyle(color: Colors.white),
              decoration: PremiumTheme.inputDecorationOf(context, 'Team'),
              items: [
                DropdownMenuItem(value: widget.homeTeamId, child: Text(widget.homeTeamName)),
                DropdownMenuItem(value: widget.awayTeamId, child: Text(widget.awayTeamName)),
              ],
              onChanged: (val) => setState(() => _selectedTeamId = val!),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _minuteController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: PremiumTheme.inputDecorationOf(context, 'Minute'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _playerController,
                    style: const TextStyle(color: Colors.white),
                    decoration: PremiumTheme.inputDecorationOf(context, 'Player Name/ID'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white38))),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'type': _selectedType,
              'team_id': _selectedTeamId,
              'minute': int.tryParse(_minuteController.text) ?? 0,
              'player_name': _playerController.text,
            });
          },
          style: ElevatedButton.styleFrom(backgroundColor: PremiumTheme.neonGreen, foregroundColor: Colors.black),
          child: const Text('SAVE EVENT'),
        ),
      ],
    );
  }
}
