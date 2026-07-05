import os

def main():
    filepath = 'lib/features/tournaments/presentation/screens/assign_match_details_screen.dart'
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Add API client import
    import_target = "import '../../providers/tournament_provider.dart';"
    import_replacement = """import '../../providers/tournament_provider.dart';
import '../../../../core/api/api_client.dart';"""
    if import_target in content and 'api_client.dart' not in content:
        content = content.replace(import_target, import_replacement)
        print("API import added!")

    # 2. Modify State class structure
    state_target = """class _AssignMatchDetailsScreenState extends State<AssignMatchDetailsScreen> {
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
  }"""

    state_replacement = """class _AssignMatchDetailsScreenState extends State<AssignMatchDetailsScreen> {
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
  }"""

    if state_target in content:
        content = content.replace(state_target, state_replacement)
        print("State variables & fetch functions replaced!")
    else:
        print("State target not found!")

    # 3. Replace _save method to send selected field ID or name
    save_target = """    final success = await context.read<TournamentProvider>().updateMatchDetails(
      widget.tournamentId,
      widget.match.id,
      {
        'field_id': _fieldController.text,
        'match_date': finalDateTime?.toIso8601String(),
        'referee_name': _refereeController.text, // Mocking referee assignment
      },
    );"""

    save_replacement = """    final success = await context.read<TournamentProvider>().updateMatchDetails(
      widget.tournamentId,
      widget.match.id,
      {
        'field_id': _selectedFieldIdOrName,
        'match_date': finalDateTime?.toIso8601String(),
        'referee_name': _refereeController.text, // Mocking referee assignment
      },
    );"""

    if save_target in content:
        content = content.replace(save_target, save_replacement)
        print("_save method updated!")
    else:
        print("Save target not found!")

    # 4. Replace manual text field with DropdownButtonFormField in build method
    build_target = """            _buildSectionLabel('tournament.logistics'.tr()),
            const SizedBox(height: 16),
            PremiumTextField(
              controller: _fieldController,
              label: 'tournament.field_court_name'.tr(),
              icon: Icons.stadium_rounded,
            ),"""

    build_replacement = """            _buildSectionLabel('tournament.logistics'.tr()),
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
            ),"""

    if build_target in content:
        content = content.replace(build_target, build_replacement)
        print("Manual text field replaced with dropdown picker!")
    else:
        print("Build target not found!")

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Done editing assign match screen!")

if __name__ == '__main__':
    main()
