import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';
import '../../data/models/tournament_match.dart';
import '../../providers/tournament_provider.dart';
import '../../../../core/api/api_client.dart';

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
  late TextEditingController _refereeController;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  List<Map<String, dynamic>> _fields = [];
  bool _loadingFields = false;
  String? _selectedFieldIdOrName;

  @override
  void initState() {
    super.initState();
    _refereeController = TextEditingController(); // Assuming no referee_id in model yet
    _selectedDate = widget.match.matchDate;
    _selectedTime = widget.match.matchDate != null ? TimeOfDay.fromDateTime(widget.match.matchDate!) : null;
    
    // Resolve initial field selection
    _selectedFieldIdOrName = widget.match.fieldId;
    if (_selectedFieldIdOrName == null || _selectedFieldIdOrName!.isEmpty) {
      _selectedFieldIdOrName = widget.match.fieldName;
    }
    
    _fetchFields();
  }

  Future<void> _fetchFields() async {
    setState(() => _loadingFields = true);
    try {
      final response = await context.read<ApiClient>().get('/fields');
      final List<dynamic> data = response.data;
      setState(() {
        _fields = data.map((e) => Map<String, dynamic>.from(e)).toList();
        
        // Ensure initial selection is matched if found in DB fields by name
        if (_selectedFieldIdOrName != null) {
          final foundDbField = _fields.firstWhere(
            (f) => f['id'].toString() == _selectedFieldIdOrName || f['name'] == _selectedFieldIdOrName,
            orElse: () => {},
          );
          if (foundDbField.isNotEmpty) {
            _selectedFieldIdOrName = foundDbField['id'].toString();
          }
        }
      });
    } catch (e) {
      print("Error fetching fields: $e");
    } finally {
      setState(() => _loadingFields = false);
    }
  }

  List<DropdownMenuItem<String>> _buildFieldDropdownItems(List<Map<String, dynamic>> dbFields, int numFields) {
    final List<DropdownMenuItem<String>> items = [];
    
    // Add DB fields
    for (var f in dbFields) {
      items.add(
        DropdownMenuItem(
          value: f['id'].toString(),
          child: Text(f['name'] ?? 'Поле', style: const TextStyle(fontSize: 14)),
        ),
      );
    }
    
    // Add default fields if they aren't already represented
    for (int i = 1; i <= numFields; i++) {
      final defaultFieldName = "Поле $i";
      final exists = dbFields.any((f) => (f['name'] as String?)?.toLowerCase() == defaultFieldName.toLowerCase());
      if (!exists) {
        items.add(
          DropdownMenuItem(
            value: defaultFieldName,
            child: Text(defaultFieldName, style: const TextStyle(fontSize: 14)),
          ),
        );
      }
    }
    
    return items;
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
        'field_id': _selectedFieldIdOrName,
        'match_date': finalDateTime?.toIso8601String(),
        'referee_name': _refereeController.text, // Mocking referee assignment
      },
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'tournament.match_details_updated'.tr() : 'tournament.error_updating_match'.tr()),
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
        title: Text('tournament.assign_match_details'.tr(), style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMatchSummary(),
            const SizedBox(height: 32),
            _buildSectionLabel('tournament.logistics'.tr()),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final tournament = context.read<TournamentProvider>().selectedTournament;
                final int numFields = tournament?.numFields ?? 1;
                final cs = Theme.of(context).colorScheme;

                if (_loadingFields) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(color: PremiumTheme.neonGreen),
                  ));
                }

                // If initial selection is not in list of options, we add a fallback option to prevent crash
                final dropdownItems = _buildFieldDropdownItems(_fields, numFields);
                final hasSelected = dropdownItems.any((item) => item.value == _selectedFieldIdOrName);
                if (!hasSelected && _selectedFieldIdOrName != null && _selectedFieldIdOrName!.isNotEmpty) {
                  dropdownItems.add(
                    DropdownMenuItem(
                      value: _selectedFieldIdOrName,
                      child: Text(_selectedFieldIdOrName!, style: const TextStyle(fontSize: 14)),
                    ),
                  );
                }

                return DropdownButtonFormField<String>(
                  value: _selectedFieldIdOrName,
                  dropdownColor: PremiumTheme.surfaceCard(context),
                  style: TextStyle(color: cs.onSurface),
                  decoration: InputDecoration(
                    labelText: 'tournament.field_court_name'.tr(),
                    prefixIcon: const Icon(Icons.stadium_rounded, color: PremiumTheme.neonGreen),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: PremiumTheme.neonGreen),
                    ),
                  ),
                  items: dropdownItems,
                  onChanged: (val) {
                    setState(() {
                      _selectedFieldIdOrName = val;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            PremiumTextField(
              controller: _refereeController,
              label: 'tournament.assign_referee'.tr(),
              icon: Icons.sports_rounded,
            ),
            const SizedBox(height: 32),
            _buildSectionLabel('tournament.schedule_label'.tr()),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPickerTile(
                    'tournament.date_label'.tr(),
                    _selectedDate != null ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}" : 'tournament.select_label'.tr(),
                    Icons.calendar_month_rounded,
                    _pickDate,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPickerTile(
                    'tournament.time_label'.tr(),
                    _selectedTime != null ? _selectedTime!.format(context) : 'tournament.select_label'.tr(),
                    Icons.access_time_filled_rounded,
                    _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            PremiumButton(
              text: 'tournament.save_assignments'.tr(),
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
        _buildTeamInfo(widget.match.homeTeamId, 'tournament.home_label'.tr()),
        const Column(
          children: [
            Text("VS", style: TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 2)),
          ],
        ),
        _buildTeamInfo(widget.match.awayTeamId, 'tournament.away_label'.tr()),
        ],
      ),
    );
  }

  Widget _buildTeamInfo(String? teamId, String label) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.05),
            shape: BoxShape.circle,
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
          ),
          child: Center(child: Icon(Icons.shield_rounded, color: cs.onSurface.withValues(alpha: 0.2), size: 30)),
        ),
        const SizedBox(height: 12),
        Text(label, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(teamId != null ? (teamId.length > 8 ? teamId.substring(0, 8).toUpperCase() : teamId.toUpperCase()) : 'TBD', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 12)),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(color: PremiumTheme.neonGreen, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: cs.onSurface.withValues(alpha: 0.55), letterSpacing: 2)),
      ],
    );
  }

  Widget _buildPickerTile(String label, String value, IconData icon, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: PremiumTheme.neonGreen),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
