import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';

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
  DateTime _regOpen = DateTime.now();
  DateTime _regClose = DateTime.now().add(const Duration(days: 5));

  String _selectedFormat = 'LEAGUE';
  String _selectedAge = 'U11';
  String _selectedSurface = 'NATURAL_GRASS';

  int _numFields = 1;
  int _matchHalf = 20;
  int _halfBreak = 5;
  int _matchBreak = 10;

  bool _isLoading = false;

  final List<String> _formats = ['LEAGUE', 'KNOCKOUT', 'GROUP_STAGE'];
  final List<String> _ages = ['U7', 'U9', 'U11', 'U13', 'U15', 'U17', 'ADULT'];
  final List<String> _surfaces = ['NATURAL_GRASS', 'ARTIFICIAL_TURF', 'INDOOR', 'CLAY'];

  Future<void> _pickDate(String label, DateTime initial, Function(DateTime) onPicked) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: PremiumTheme.neonGreen,
              onPrimary: Colors.black,
              surface: PremiumTheme.cardNavy,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: PremiumTheme.deepNavy,
          ),
          child: child!,
        );
      },
    );
    if (date != null) onPicked(date);
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'name': _nameController.text,
      'location': _locationController.text,
      'start_date': _startDate.toIso8601String().split('T')[0],
      'end_date': _endDate.toIso8601String().split('T')[0],
      'registration_open': _regOpen.toIso8601String().split('T')[0],
      'registration_close': _regClose.toIso8601String().split('T')[0],
      'format': _selectedFormat,
      'age_category': _selectedAge,
      'surface_type': _selectedSurface,
      'num_fields': _numFields,
      'match_half_duration': _matchHalf,
      'halftime_break_duration': _halfBreak,
      'break_between_matches': _matchBreak,
    };

    final success = await context.read<TournamentProvider>().createTournament(data);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tournament Created!'), backgroundColor: PremiumTheme.neonGreen),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${context.read<TournamentProvider>().error}'), backgroundColor: PremiumTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.deepNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('NEW TOURNAMENT', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PremiumHeader(title: 'Create', subtitle: 'Event Setup'),
              
              _buildSectionTitle('BASIC INFORMATION', Icons.info_outline),
              PremiumCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: PremiumTheme.inputDecoration('Tournament Name', prefixIcon: Icons.emoji_events),
                      validator: (v) => v!.isEmpty ? 'Name required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      style: const TextStyle(color: Colors.white),
                      decoration: PremiumTheme.inputDecoration('Location / Stadium', prefixIcon: Icons.location_on),
                      validator: (v) => v!.isEmpty ? 'Location required' : null,
                    ),
                  ],
                ),
              ),

              _buildSectionTitle('CONFIGURATION', Icons.settings),
              PremiumCard(
                child: Column(
                  children: [
                    _buildDropdown('Format', _selectedFormat, _formats, (v) => setState(() => _selectedFormat = v!)),
                    const SizedBox(height: 16),
                    _buildDropdown('Age Category', _selectedAge, _ages, (v) => setState(() => _selectedAge = v!)),
                    const SizedBox(height: 16),
                    _buildDropdown('Surface', _selectedSurface, _surfaces, (v) => setState(() => _selectedSurface = v!)),
                  ],
                ),
              ),

              _buildSectionTitle('DATES', Icons.calendar_month),
              PremiumCard(
                child: Column(
                  children: [
                    _buildDateTile('Starts', _startDate, (d) => setState(() => _startDate = d)),
                    _buildDateTile('Ends', _endDate, (d) => setState(() => _endDate = d)),
                    const Divider(color: Colors.white10, height: 24),
                    _buildDateTile('Reg. Opens', _regOpen, (d) => setState(() => _regOpen = d)),
                    _buildDateTile('Reg. Closes', _regClose, (d) => setState(() => _regClose = d)),
                  ],
                ),
              ),

              _buildSectionTitle('MATCH SETTINGS', Icons.timer),
              PremiumCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildNumberField('Fields', _numFields, (v) => _numFields = v)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildNumberField('Half (min)', _matchHalf, (v) => _matchHalf = v)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildNumberField('Break (min)', _halfBreak, (v) => _halfBreak = v)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildNumberField('Between (min)', _matchBreak, (v) => _matchBreak = v)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              PremiumButton(
                text: 'PUBLISH TOURNAMENT',
                icon: Icons.check_circle_outline,
                isLoading: _isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: PremiumTheme.neonGreen),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: PremiumTheme.cardNavy,
      style: const TextStyle(color: Colors.white),
      decoration: PremiumTheme.inputDecoration(label),
      items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDateTile(String label, DateTime date, Function(DateTime) onPicked) {
    return InkWell(
      onTap: () => _pickDate(label, date, onPicked),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                date.toIso8601String().split('T')[0],
                style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField(String label, int initial, Function(int) onChanged) {
    return TextFormField(
      initialValue: initial.toString(),
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: PremiumTheme.inputDecoration(label),
      onChanged: (v) => onChanged(int.tryParse(v) ?? initial),
    );
  }
}
