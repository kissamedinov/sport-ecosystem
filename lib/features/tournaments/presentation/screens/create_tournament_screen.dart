import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';

class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  DateTime _registrationOpenDate = DateTime.now();
  DateTime _registrationCloseDate = DateTime.now().add(const Duration(days: 5));

  String _selectedFormat = 'LEAGUE';
  String _selectedAgeCategory = 'U11';

  int _numFields = 1;
  int _matchHalfDuration = 20;

  bool _isLoading = false;

  final List<String> _formats = ['LEAGUE', 'KNOCKOUT', 'GROUP_STAGE'];
  final List<String> _ageCategories = ['U7', 'U9', 'U11', 'U13', 'U15', 'U17', 'ADULT'];

  Future<void> _selectDate(BuildContext context, DateTime initialDate, Function(DateTime) onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && picked != initialDate) {
      onDateSelected(picked);
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final Map<String, dynamic> tournamentData = {
        'name': _nameController.text,
        'location': _locationController.text,
        'start_date': _startDate.toIso8601String().split('T')[0],
        'end_date': _endDate.toIso8601String().split('T')[0],
        'registration_open': _registrationOpenDate.toIso8601String().split('T')[0],
        'registration_close': _registrationCloseDate.toIso8601String().split('T')[0],
        'format': _selectedFormat,
        'age_category': _selectedAgeCategory,
        'num_fields': _numFields,
        'match_half_duration': _matchHalfDuration,
      };

      final provider = context.read<TournamentProvider>();
      final success = await provider.createTournament(tournamentData);

      setState(() => _isLoading = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tournament created successfully!')),
        );
        Navigator.pop(context); // Go back to the list screen
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Failed to create tournament: ${provider.error}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Tournament'),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Tournament Name'),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                       controller: _locationController,
                       decoration: const InputDecoration(labelText: 'Location'),
                       validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Format Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedFormat,
                      decoration: const InputDecoration(labelText: 'Tournament Format'),
                      items: _formats.map((String format) {
                        return DropdownMenuItem<String>(
                          value: format,
                          child: Text(format),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() { _selectedFormat = newValue!; });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Age Category Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedAgeCategory,
                      decoration: const InputDecoration(labelText: 'Age Category'),
                      items: _ageCategories.map((String age) {
                        return DropdownMenuItem<String>(
                          value: age,
                          child: Text(age),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() { _selectedAgeCategory = newValue!; });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Dates Configuration
                    const Text('Dates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ListTile(
                      title: const Text('Start Date'),
                      trailing: Text("${_startDate.toLocal()}".split(' ')[0]),
                      onTap: () => _selectDate(context, _startDate, (date) => setState(() => _startDate = date)),
                    ),
                    ListTile(
                      title: const Text('End Date'),
                      trailing: Text("${_endDate.toLocal()}".split(' ')[0]),
                      onTap: () => _selectDate(context, _endDate, (date) => setState(() => _endDate = date)),
                    ),
                    ListTile(
                      title: const Text('Registration Open Date'),
                      trailing: Text("${_registrationOpenDate.toLocal()}".split(' ')[0]),
                      onTap: () => _selectDate(context, _registrationOpenDate, (date) => setState(() => _registrationOpenDate = date)),
                    ),
                    ListTile(
                      title: const Text('Registration Close Date'),
                      trailing: Text("${_registrationCloseDate.toLocal()}".split(' ')[0]),
                      onTap: () => _selectDate(context, _registrationCloseDate, (date) => setState(() => _registrationCloseDate = date)),
                    ),
                    const SizedBox(height: 24),

                     // Game Settings configuration
                    const Text('Game Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _numFields.toString(),
                            decoration: const InputDecoration(labelText: 'Number of Fields'),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => _numFields = int.tryParse(val) ?? 1,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            initialValue: _matchHalfDuration.toString(),
                            decoration: const InputDecoration(labelText: 'Half Duration (mins)'),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => _matchHalfDuration = int.tryParse(val) ?? 20,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _submitForm,
                      child: const Text('Create Tournament', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 32), // Bottom spacing
                  ],
                ),
              ),
            ),
    );
  }
}
