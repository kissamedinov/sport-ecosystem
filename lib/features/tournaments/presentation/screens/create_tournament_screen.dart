import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
import '../../data/models/tournament.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';

class CreateTournamentScreen extends StatefulWidget {
  final Tournament? initialTournament;
  const CreateTournamentScreen({super.key, this.initialTournament});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _whatsappController;
  late TextEditingController _phoneController;
  late TextEditingController _allowedAgesController;

  late DateTime _startDate;
  late DateTime _endDate;
  late DateTime _regOpen;
  late DateTime _regClose;

  late String _selectedFormat;
  late String _selectedAge;
  late String _selectedSurface;
  late String _selectedSeason;
  late int _selectedYear;

  late int _numFields;
  late int _matchHalf;
  late int _halfBreak;
  late int _matchBreak;
  late int _minRest;

  late int _ptsWin;
  late int _ptsDraw;
  late int _ptsLoss;

  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 21, minute: 0);

  bool _isLoading = false;

  final List<String> _formats = ['LEAGUE', 'KNOCKOUT', 'GROUP_STAGE'];
  final List<String> _ages = [
    '2005', '2006', '2007', '2008', '2009', '2010', '2011', '2012',
    '2013', '2014', '2015', '2016', '2017', '2018', '2019', '2020', 
    'U8', 'U9', 'U10', 'U11', 'U12', 'U13', 'U14', 'U15', 'U16', 'U17', 'U18',
    'ADULT'
  ];
  final List<String> _surfaces = ['NATURAL_GRASS', 'ARTIFICIAL_TURF', 'INDOOR', 'OTHER'];
  final List<String> _seasons = ['SPRING', 'SUMMER', 'AUTUMN', 'WINTER'];

  @override
  void initState() {
    super.initState();
    final t = widget.initialTournament;
    
    _nameController = TextEditingController(text: t?.name ?? '');
    _locationController = TextEditingController(text: t?.location ?? '');
    _whatsappController = TextEditingController(text: t?.whatsapp ?? '');
    _phoneController = TextEditingController(text: t?.phone ?? '');
    _allowedAgesController = TextEditingController(text: t?.allowedAgeCategories ?? '');

    _startDate = t != null ? DateTime.parse(t.startDate) : DateTime.now();
    _endDate = t != null ? DateTime.parse(t.endDate) : DateTime.now().add(const Duration(days: 7));
    
    final regOpenStr = t?.registrationOpen;
    _regOpen = regOpenStr != null ? DateTime.parse(regOpenStr) : DateTime.now();
    
    final regCloseStr = t?.registrationClose;
    _regClose = regCloseStr != null ? DateTime.parse(regCloseStr) : DateTime.now().add(const Duration(days: 5));

    _selectedFormat = t?.format ?? 'LEAGUE';
    _selectedAge = t?.ageCategory ?? '2013';
    
    // Defensive check for Dropdown values
    if (!_ages.contains(_selectedAge)) {
      _ages.add(_selectedAge);
    }

    _selectedSurface = t?.surfaceType ?? 'NATURAL_GRASS';
    if (!_surfaces.contains(_selectedSurface)) {
      _surfaces.add(_selectedSurface);
    }
    _selectedSeason = t?.season ?? 'SUMMER';
    _selectedYear = t?.year ?? DateTime.now().year;

    _numFields = t?.numFields ?? 1;
    _matchHalf = t?.matchHalfDuration ?? 20;
    _halfBreak = t?.halftimeBreakDuration ?? 5;
    _matchBreak = t?.breakBetweenMatches ?? 10;
    _minRest = t?.minimumRestSlots ?? 1;

    _ptsWin = t?.pointsForWin ?? 3;
    _ptsDraw = t?.pointsForDraw ?? 1;
    _ptsLoss = t?.pointsForLoss ?? 0;

    final startStr = t?.startTime;
    if (startStr != null) {
        final dt = DateTime.parse(startStr);
        _startTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }
    final endStr = t?.endTime;
    if (endStr != null) {
        final dt = DateTime.parse(endStr);
        _endTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }
  }

  Future<void> _pickDate(String label, DateTime initial, Function(DateTime) onPicked) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: PremiumTheme.neonGreen,
            onPrimary: Colors.black,
            surface: PremiumTheme.surfaceCard(context),
            onSurface: Colors.white,
          ),
          dialogBackgroundColor: PremiumTheme.surfaceBase(context),
        ),
        child: child!,
      ),
    );
    if (date != null) onPicked(date);
  }

  Future<void> _pickTime(String label, TimeOfDay initial, Function(TimeOfDay) onPicked) async {
    final time = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: PremiumTheme.neonGreen,
            onPrimary: Colors.black,
            surface: PremiumTheme.surfaceCard(context),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (time != null) onPicked(time);
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Format times for backend (today's date with chosen time)
    final now = DateTime.now();
    final startDT = DateTime(now.year, now.month, now.day, _startTime.hour, _startTime.minute);
    final endDT = DateTime(now.year, now.month, now.day, _endTime.hour, _endTime.minute);

    final data = {
      'name': _nameController.text,
      'location': _locationController.text,
      'start_date': _startDate.toIso8601String().split('T')[0],
      'end_date': _endDate.toIso8601String().split('T')[0],
      'registration_open': _regOpen.toIso8601String().split('T')[0],
      'registration_close': _regClose.toIso8601String().split('T')[0],
      'format': _selectedFormat,
      'age_category': _selectedAge,
      'allowed_age_categories': _allowedAgesController.text,
      'surface_type': _selectedSurface,
      'season': _selectedSeason,
      'year': _selectedYear,
      'num_fields': _numFields,
      'match_half_duration': _matchHalf,
      'halftime_break_duration': _halfBreak,
      'break_between_matches': _matchBreak,
      'minimum_rest_slots': _minRest,
      'points_for_win': _ptsWin,
      'points_for_draw': _ptsDraw,
      'points_for_loss': _ptsLoss,
      'start_time': startDT.toIso8601String(),
      'end_time': endDT.toIso8601String(),
      'whatsapp': _whatsappController.text,
      'phone': _phoneController.text,
    };

    bool success;
    if (widget.initialTournament != null) {
      success = await context.read<TournamentProvider>().updateTournament(widget.initialTournament!.id, data);
    } else {
      success = await context.read<TournamentProvider>().createTournament(data);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.initialTournament != null ? 'Tournament Updated!' : 'Tournament Created!'), 
            backgroundColor: PremiumTheme.neonGreen
          ),
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
    final isEdit = widget.initialTournament != null;

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(isEdit ? 'EDIT TOURNAMENT' : 'NEW TOURNAMENT', 
          style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PremiumHeader(
                title: isEdit ? 'Update' : 'Create', 
                subtitle: isEdit ? 'Tournament Details' : 'Event Setup'
              ),
              
              _buildSectionTitle('BASIC INFORMATION', Icons.info_outline),
              PremiumCard(
                child: Column(
                  children: [
                    PremiumTextField(
                      controller: _nameController,
                      label: 'Tournament Name',
                      icon: Icons.emoji_events,
                    ),
                    const SizedBox(height: 16),
                    PremiumTextField(
                      controller: _locationController,
                      label: 'Location / Stadium',
                      icon: Icons.location_on,
                    ),
                    const SizedBox(height: 16),
                    Row(
                        children: [
                            Expanded(child: _buildDropdown('Year', _selectedYear.toString(), 
                                List.generate(5, (i) => (DateTime.now().year - 2 + i).toString()), 
                                (v) => setState(() => _selectedYear = int.parse(v!)))),
                            const SizedBox(width: 12),
                            Expanded(child: _buildDropdown('Season', _selectedSeason, _seasons, 
                                (v) => setState(() => _selectedSeason = v!))),
                        ]
                    )
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle('ORGANIZER CONTACTS', Icons.contact_phone),
              PremiumCard(
                child: Column(
                  children: [
                    PremiumTextField(
                      controller: _whatsappController,
                      label: 'WhatsApp (e.g. +7...)',
                      icon: Icons.message,
                    ),
                    const SizedBox(height: 16),
                    PremiumTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('CONFIGURATION', Icons.settings),
              PremiumCard(
                child: Column(
                  children: [
                    _buildDropdown('Format', _selectedFormat, _formats, (v) => setState(() => _selectedFormat = v!)),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    _buildDropdown('Age Category (Main)', _selectedAge, _ages, (v) => setState(() => _selectedAge = v!)),
                    const SizedBox(height: 16),
                    PremiumTextField(
                      controller: _allowedAgesController,
                      label: 'Allowed Age Categories (Optional)',
                      icon: Icons.people_outline,
                      hintText: 'e.g. 2013, 2014, 2015',
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown('Surface', _selectedSurface, _surfaces, (v) => setState(() => _selectedSurface = v!)),
                  ],
                ),
              ),

              const SizedBox(height: 24),
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

              const SizedBox(height: 24),
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
                    const SizedBox(height: 16),
                    _buildNumberField('Min Rest Slots', _minRest, (v) => _minRest = v),
                    const Divider(color: Colors.white10, height: 32),
                    _buildTimeTile('Day Starts', _startTime, (t) => setState(() => _startTime = t)),
                    _buildTimeTile('Day Ends', _endTime, (t) => setState(() => _endTime = t)),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('POINTS SYSTEM', Icons.score),
              PremiumCard(
                child: Row(
                  children: [
                    Expanded(child: _buildNumberField('Win', _ptsWin, (v) => _ptsWin = v)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildNumberField('Draw', _ptsDraw, (v) => _ptsDraw = v)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildNumberField('Loss', _ptsLoss, (v) => _ptsLoss = v)),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              PremiumButton(
                text: isEdit ? 'SAVE CHANGES' : 'PUBLISH TOURNAMENT',
                icon: isEdit ? Icons.save : Icons.check_circle_outline,
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
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 12),
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
      dropdownColor: PremiumTheme.surfaceCard(context),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: PremiumTheme.inputDecorationOf(context, label),
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
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                date.toIso8601String().split('T')[0],
                style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTile(String label, TimeOfDay time, Function(TimeOfDay) onPicked) {
    return InkWell(
      onTap: () => _pickTime(label, time, onPicked),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                time.format(context),
                style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.bold, fontSize: 13),
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
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: PremiumTheme.inputDecorationOf(context, label),
      onChanged: (v) => onChanged(int.tryParse(v) ?? initial),
    );
  }
}
