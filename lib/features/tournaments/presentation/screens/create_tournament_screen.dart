import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/tournament_provider.dart';
import '../../data/models/tournament.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';
import '../../../../features/media/data/repositories/media_repository.dart';
import '../../../../features/media/data/models/media_item.dart';
import '../../../../features/fields/data/models/field.dart';
import '../../../../features/fields/data/repositories/field_repository.dart';
import 'dart:convert';
import '../../../../features/auth/providers/auth_provider.dart';

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

  final List<Map<String, dynamic>> _divisions = [];
  final List<String> _deletedDivisionIds = [];
  final TextEditingController _divisionNameController = TextEditingController();
  final TextEditingController _divisionFormatController = TextEditingController(text: '8+1');
  final TextEditingController _divisionFeeController = TextEditingController(text: '0');
  final TextEditingController _divisionMaxTeamsController = TextEditingController(text: '8');
  String _selectedDivisionAge = '2013';

  final List<String> _formats = ['LEAGUE', 'KNOCKOUT', 'GROUP_STAGE'];
  final List<String> _ages = [
    '2005', '2006', '2007', '2008', '2009', '2010', '2011', '2012',
    '2013', '2014', '2015', '2016', '2017', '2018', '2019', '2020', 
    'U8', 'U9', 'U10', 'U11', 'U12', 'U13', 'U14', 'U15', 'U16', 'U17', 'U18',
    'ADULT'
  ];
  final List<String> _surfaces = ['NATURAL_GRASS', 'ARTIFICIAL_TURF', 'INDOOR', 'OTHER'];
  File? _logoFile;
  String? _logoUrl;
  
  List<Field> _availableFields = [];
  List<String> _selectedFieldIds = [];
  bool _useAcademyFields = false;

  final List<String> _seasons = ['SPRING', 'SUMMER', 'AUTUMN', 'WINTER'];

  @override
  void initState() {
    super.initState();
    final t = widget.initialTournament;
    
    _logoUrl = t?.logoUrl;
    if (t?.fieldIds != null && t!.fieldIds!.isNotEmpty) {
      try {
        _selectedFieldIds = List<String>.from(jsonDecode(t.fieldIds!));
        _useAcademyFields = _selectedFieldIds.isNotEmpty;
      } catch (e) {
        print('Error decoding fieldIds: $e');
      }
    }

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
    
    if (widget.initialTournament != null) {
      _loadExistingDivisions();
    }

    _fetchFields();
  }

  Future<void> _loadExistingDivisions() async {
    try {
      final provider = context.read<TournamentProvider>();
      await provider.fetchTournamentDetails(widget.initialTournament!.id);
      setState(() {
        _divisions.clear();
        _divisions.addAll(provider.divisions);
      });
    } catch (e) {
      print('Error loading divisions: $e');
    }
  }

  Future<void> _fetchFields() async {
    try {
      final repo = FieldRepository(context.read<TournamentProvider>().repository.apiClient);
      final fields = await repo.getFields();
      setState(() {
        _availableFields = fields;
      });
    } catch (e) {
      print('Error fetching fields: $e');
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

    String? finalLogoUrl = _logoUrl;

    try {
      if (_logoFile != null) {
        final mediaRepo = context.read<MediaRepository>();
        final authProvider = context.read<AuthProvider>();
        final mediaItem = await mediaRepo.uploadMedia(
          file: _logoFile!,
          type: 'TOURNAMENT_LOGO',
          userId: authProvider.user?.id,
        );
        finalLogoUrl = mediaItem.url;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logo Upload Error: $e'), backgroundColor: PremiumTheme.danger),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

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
      'logo_url': finalLogoUrl,
      'field_ids': jsonEncode(_selectedFieldIds),
    };

    bool success;
    final provider = context.read<TournamentProvider>();
    
    if (widget.initialTournament != null) {
      success = await provider.updateTournament(widget.initialTournament!.id, data);
      if (success) {
        // Handle deleted divisions
        for (final id in _deletedDivisionIds) {
          await provider.deleteDivision(widget.initialTournament!.id, id);
        }
        // Handle divisions for edit: update existing, create new
        for (final div in _divisions) {
          if (div['id'] != null) {
            // Update existing division
            await provider.updateDivision(widget.initialTournament!.id, div['id'], div);
          } else {
            // Create new division
            await provider.createDivision(widget.initialTournament!.id, div);
          }
        }
      }
    } else {
      success = await provider.createTournament(data);
      if (success && _divisions.isNotEmpty) {
        // Create divisions for the new tournament
        final newTournament = provider.tournaments.first;
        for (final div in _divisions) {
          await provider.createDivision(newTournament.id, div);
        }
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.initialTournament != null 
              ? 'Tournament Updated!' 
              : 'Tournament Created with ${_divisions.length} divisions!'), 
            backgroundColor: PremiumTheme.neonGreen
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${provider.error}'), backgroundColor: PremiumTheme.danger),
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
              _buildLogoPicker(),
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
              _buildSectionTitle('AGE DIVISIONS', Icons.groups),
              _buildDivisionsSection(),
              const SizedBox(height: 24),

              _buildSectionTitle('CONFIGURATION', Icons.settings),
              PremiumCard(
                child: Column(
                  children: [
                    _buildDropdown('Format', _selectedFormat, _formats, (v) => setState(() => _selectedFormat = v!)),
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
                    _buildFieldSelectionToggle(),
                    const SizedBox(height: 16),
                    if (!_useAcademyFields)
                      _buildNumberField('Number of Fields', _numFields, (v) => _numFields = v)
                    else
                      _buildFieldsList(),
                    const Divider(color: Colors.white10, height: 32),
                    Row(
                      children: [
                        Expanded(child: _buildNumberField('Half (min)', _matchHalf, (v) => _matchHalf = v)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildNumberField('Break (min)', _halfBreak, (v) => _halfBreak = v)),
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
  void _addDivision() {
    if (_divisionNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a division name')),
      );
      return;
    }
    setState(() {
      _divisions.add({
        'name': _divisionNameController.text,
        'format': _divisionFormatController.text,
        'entry_fee': int.tryParse(_divisionFeeController.text) ?? 0,
        'birth_year': _selectedDivisionAge == 'ADULT' ? 0 : int.parse(_selectedDivisionAge.startsWith('U') ? (DateTime.now().year - int.parse(_selectedDivisionAge.substring(1))).toString() : _selectedDivisionAge),
        'max_teams': int.tryParse(_divisionMaxTeamsController.text) ?? 10,
      });
      _divisionNameController.clear();
      _divisionFormatController.text = '8+1';
      _divisionFeeController.text = '0';
      _divisionMaxTeamsController.text = '8';
    });
  }

  void _removeDivision(int index) {
    setState(() {
      final div = _divisions.removeAt(index);
      if (div['id'] != null) {
        _deletedDivisionIds.add(div['id']);
      }
    });
  }

  Widget _buildDivisionsSection() {
    return Column(
      children: [
        PremiumCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PremiumTextField(
                      controller: _divisionNameController,
                      label: 'Division Name',
                      icon: Icons.label_outline,
                      hintText: 'e.g. U10 Gold',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PremiumTextField(
                      controller: _divisionFormatController,
                      label: 'Format',
                      icon: Icons.grid_view,
                      hintText: 'e.g. 8+1',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdown(
                      'Year',
                      _selectedDivisionAge,
                      _ages,
                      (v) => setState(() => _selectedDivisionAge = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: PremiumTextField(
                      controller: _divisionFeeController,
                      label: 'Entry Fee',
                      icon: Icons.payments_outlined,
                      keyboardType: TextInputType.number,
                      hintText: '0',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PremiumTextField(
                      controller: _divisionMaxTeamsController,
                      label: 'Max Teams',
                      icon: Icons.format_list_numbered,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _addDivision,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PremiumTheme.neonGreen.withValues(alpha: 0.2),
                      foregroundColor: PremiumTheme.neonGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_divisions.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...List.generate(_divisions.length, (index) {
            final div = _divisions[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: PremiumTheme.neonGreen, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(div['name'] ?? 'Division ${div['birth_year']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Format: ${div['format'] ?? 'Standard'} • Fee: ${div['entry_fee'] ?? 0} • Year: ${div['birth_year']} • Max Teams: ${div['max_teams']}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: PremiumTheme.danger, size: 20),
                      onPressed: () => _removeDivision(index),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _logoFile = File(pickedFile.path);
      });
    }
  }
  Widget _buildFieldSelectionToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Use Academy Fields', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        Switch(
          value: _useAcademyFields,
          onChanged: (v) {
            setState(() {
              _useAcademyFields = v;
              if (!v) _selectedFieldIds.clear();
            });
          },
          activeColor: PremiumTheme.neonGreen,
        ),
      ],
    );
  }

  Widget _buildFieldsList() {
    if (_availableFields.isEmpty) {
      return const Text('No fields found in your academy', style: TextStyle(color: Colors.white38, fontSize: 12));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableFields.map((field) {
        final isSelected = _selectedFieldIds.contains(field.id);
        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedFieldIds.remove(field.id);
              } else {
                _selectedFieldIds.add(field.id);
              }
              _numFields = _selectedFieldIds.length;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? PremiumTheme.neonGreen.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? PremiumTheme.neonGreen : Colors.white10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stadium, size: 14, color: isSelected ? PremiumTheme.neonGreen : Colors.white38),
                const SizedBox(width: 8),
                Text(field.name, style: TextStyle(color: isSelected ? PremiumTheme.neonGreen : Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLogoPicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: PremiumTheme.surfaceCard(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.3), width: 2),
                image: _logoFile != null 
                  ? DecorationImage(image: FileImage(_logoFile!), fit: BoxFit.cover)
                  : (_logoUrl != null ? DecorationImage(image: NetworkImage(_logoUrl!), fit: BoxFit.cover) : null),
              ),
              child: (_logoFile == null && _logoUrl == null)
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, color: PremiumTheme.neonGreen.withValues(alpha: 0.5), size: 32),
                      const SizedBox(height: 8),
                      const Text('LOGO', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ],
                  )
                : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: PremiumTheme.neonGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: PremiumTheme.neonGreen.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 2),
                  ],
                ),
                child: const Icon(Icons.edit, color: Colors.black, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
