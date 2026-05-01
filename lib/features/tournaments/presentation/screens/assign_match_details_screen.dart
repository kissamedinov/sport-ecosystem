import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';
import '../../data/models/tournament_match.dart';
import '../../providers/tournament_provider.dart';

class AssignMatchDetailsScreen extends StatefulWidget {
  final TournamentMatch match;
  final String tournamentId;

  const AssignMatchDetailsScreen({
    super.key,
    required this.match,
    required this.tournamentId,
  });

  @override
  State<AssignMatchDetailsScreen> createState() => _AssignMatchDetailsScreenState();
}

class _AssignMatchDetailsScreenState extends State<AssignMatchDetailsScreen> {
  late TextEditingController _fieldController;
  late TextEditingController _refereeController;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _fieldController = TextEditingController(text: widget.match.fieldId ?? '');
    _refereeController = TextEditingController(); // Assuming no referee_id in model yet
    _selectedDate = widget.match.matchDate;
    _selectedTime = widget.match.matchDate != null ? TimeOfDay.fromDateTime(widget.match.matchDate!) : null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: PremiumTheme.neonGreen,
            onPrimary: Colors.black,
            surface: Color(0xFF1A1A1A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: PremiumTheme.neonGreen,
            onPrimary: Colors.black,
            surface: Color(0xFF1A1A1A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _save() async {
    HapticFeedback.heavyImpact();
    
    DateTime? finalDateTime;
    if (_selectedDate != null && _selectedTime != null) {
      finalDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    }

    final success = await context.read<TournamentProvider>().updateMatchDetails(
      widget.tournamentId,
      widget.match.id,
      {
        'field_id': _fieldController.text,
        'match_date': finalDateTime?.toIso8601String(),
        'referee_name': _refereeController.text, // Mocking referee assignment
      },
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'MATCH DETAILS UPDATED' : 'ERROR UPDATING MATCH'),
          backgroundColor: success ? PremiumTheme.neonGreen : PremiumTheme.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('ASSIGN MATCH DETAILS', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMatchSummary(),
            const SizedBox(height: 32),
            _buildSectionLabel("LOGISTICS"),
            const SizedBox(height: 16),
            PremiumTextField(
              controller: _fieldController,
              label: "FIELD / COURT NAME",
              icon: Icons.stadium_rounded,
            ),
            const SizedBox(height: 16),
            PremiumTextField(
              controller: _refereeController,
              label: "ASSIGN REFEREE",
              icon: Icons.sports_rounded,
            ),
            const SizedBox(height: 32),
            _buildSectionLabel("SCHEDULE"),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPickerTile(
                    "DATE",
                    _selectedDate != null ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}" : "SELECT",
                    Icons.calendar_month_rounded,
                    _pickDate,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPickerTile(
                    "TIME",
                    _selectedTime != null ? _selectedTime!.format(context) : "SELECT",
                    Icons.access_time_filled_rounded,
                    _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            PremiumButton(
              text: "SAVE ASSIGNMENTS",
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: PremiumTheme.glassDecorationOf(context, radius: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTeamInfo(widget.match.homeTeamId, "HOME"),
          const Column(
            children: [
              Text("VS", style: TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 2)),
            ],
          ),
          _buildTeamInfo(widget.match.awayTeamId, "AWAY"),
        ],
      ),
    );
  }

  Widget _buildTeamInfo(String teamId, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white10),
          ),
          child: const Center(child: Icon(Icons.shield_rounded, color: Colors.white24, size: 30)),
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(teamId.substring(0, 8).toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(color: PremiumTheme.neonGreen, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white54, letterSpacing: 2)),
      ],
    );
  }

  Widget _buildPickerTile(String label, String value, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: PremiumTheme.neonGreen),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
