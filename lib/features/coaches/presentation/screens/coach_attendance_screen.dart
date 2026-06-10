import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/features/academies/providers/academy_provider.dart';
import 'package:mobile/features/academies/data/models/academy_team.dart';
import 'package:mobile/features/teams/providers/team_provider.dart';

class CoachAttendanceScreen extends StatefulWidget {
  final List teams;
  const CoachAttendanceScreen({super.key, this.teams = const []});

  @override
  State<CoachAttendanceScreen> createState() => _CoachAttendanceScreenState();
}

class _CoachAttendanceScreenState extends State<CoachAttendanceScreen> {
  String? _selectedTeamId;
  String? _selectedSessionId;
  
  // map of playerId to status ('PRESENT', 'ABSENT', etc)
  final Map<String, String> _attendanceStatus = {};
  // map of playerId to absent reason
  final Map<String, String> _absentReasons = {};

  @override
  void initState() {
    super.initState();
    if (widget.teams.isNotEmpty) {
      _selectedTeamId = widget.teams.first['id']?.toString();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSessionsForSelectedTeam();
    });
  }

  void _fetchSessionsForSelectedTeam() async {
    if (_selectedTeamId == null) return;
    final selectedTeam = widget.teams.firstWhere(
      (t) => t['id']?.toString() == _selectedTeamId,
      orElse: () => {},
    );
    String? academyId = selectedTeam['academy_id']?.toString();
    
    // Fallback: If academy_id is missing (e.g. from cached dashboard), fetch team details
    if (academyId == null) {
      final teamProvider = context.read<TeamProvider>();
      final fullTeam = await teamProvider.fetchTeamById(_selectedTeamId!);
      academyId = fullTeam?.academyId;
    }

    if (academyId != null && mounted) {
      context.read<AcademyProvider>().fetchSessions(academyId, teamId: _selectedTeamId);
    }
  }

  void _markAll(String status, List players) {
    HapticFeedback.mediumImpact();
    setState(() {
      for (var p in players) {
        final id = p['id']?.toString();
        if (id != null) {
          _attendanceStatus[id] = status;
          if (status == 'PRESENT') {
            _absentReasons.remove(id);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedTeam = widget.teams.firstWhere(
      (t) => t['id']?.toString() == _selectedTeamId,
      orElse: () => {},
    );
    final players = (selectedTeam['players'] as List?) ?? [];

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      body: Consumer<AcademyProvider>(
        builder: (context, academyProvider, _) {
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(child: _buildTeamSelector()),
              if (academyProvider.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen)),
                  ),
                )
              else
                SliverToBoxAdapter(child: _buildSessionSelector(academyProvider)),
              if (!academyProvider.isLoading && _selectedSessionId != null && players.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _markAll('PRESENT', players),
                          icon: const Icon(Icons.check_circle_outline_rounded, color: PremiumTheme.neonGreen, size: 18),
                          label: Text('coach.all_present'.tr(), style: const TextStyle(color: PremiumTheme.neonGreen, fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _markAll('ABSENT', players),
                          icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 18),
                          label: Text('coach.all_absent'.tr(), style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!academyProvider.isLoading)
                if (players.isEmpty)
                  _buildEmptyState()
                else if (_selectedSessionId == null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text('coach.select_session_above'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ),
                  )
                else
                  _buildPlayerList(players),
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          );
        }
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildSubmitBtn(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: PremiumTheme.surfaceBase(context),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          'coach.attendance'.tr().toUpperCase(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        background: Builder(
          builder: (ctx) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: isDark
                      ? [const Color(0xFF0D2A1A), PremiumTheme.surfaceBase(ctx)]
                      : [const Color(0xFFE8F5E9), PremiumTheme.surfaceBase(ctx)],
                ),
              ),
            );
          },
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildTeamSelector() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.teams.length,
        itemBuilder: (context, index) {
          final team = widget.teams[index];
          final id = team['id']?.toString();
          final isSelected = id == _selectedTeamId;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedTeamId = id;
                  _selectedSessionId = null;
                });
                _fetchSessionsForSelectedTeam();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? PremiumTheme.neonGreen : cs.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? PremiumTheme.neonGreen : cs.onSurface.withValues(alpha: 0.08),
                  ),
                ),
                child: Center(
                  child: Text(
                    team['name']?.toString().toUpperCase() ?? 'coach.team'.tr().toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.black : cs.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionSelector(AcademyProvider provider) {
    final cs = Theme.of(context).colorScheme;
    final sessions = provider.sessions.where((s) => s.teamIds.contains(_selectedTeamId)).toList();

    if (sessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text('coach.no_sessions_available'.tr(), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
      );
    }

    return SizedBox(
      height: 75,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          final id = session.id;
          final isSelected = id == _selectedSessionId;

          DateTime? parsedDate;
          try {
            parsedDate = DateTime.parse('${session.date} ${session.startTime}');
          } catch (_) {}
          
          String displayDate = session.date;
          String displayTime = session.startTime.length >= 5 ? session.startTime.substring(0, 5) : session.startTime;
          if (parsedDate != null) {
            displayDate = DateFormat('d MMM').format(parsedDate);
          }

          String topic = session.topic;
          if (topic.toLowerCase().contains('automated session')) {
            topic = 'coach.training'.tr();
          }

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () async {
                HapticFeedback.selectionClick();
                setState(() => _selectedSessionId = id);
                // Pre-fill existing attendance if available
                final attendance = await provider.fetchSessionAttendance(id);
                if (mounted && attendance.isNotEmpty) {
                  setState(() {
                    for (var record in attendance) {
                      _attendanceStatus[record.playerId] = record.status;
                      if (record.note != null) {
                        _absentReasons[record.playerId] = record.note!;
                      }
                    }
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 140,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? PremiumTheme.electricBlue : cs.onSurface.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? PremiumTheme.electricBlue : cs.onSurface.withValues(alpha: 0.08),
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(color: PremiumTheme.electricBlue.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
                  ] : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          displayDate,
                          style: TextStyle(
                            color: isSelected ? Colors.white : cs.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Icon(Icons.schedule_rounded, size: 14, color: isSelected ? Colors.white.withValues(alpha: 0.8) : cs.onSurfaceVariant),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$displayTime • $topic',
                      style: TextStyle(
                        color: isSelected ? Colors.white.withValues(alpha: 0.9) : cs.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final cs = Theme.of(context).colorScheme;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off_rounded, size: 64, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              'coach.no_players_in_team'.tr(),
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerList(List players) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final player = players[index];
            final name = player['name']?.toString() ?? 'coach.player'.tr();
            final id = player['id']?.toString() ?? index.toString();
            final status = _attendanceStatus[id] ?? 'UNKNOWN';
            final isPresent = status == 'PRESENT';
            final isAbsent = status == 'ABSENT';
            final cs = Theme.of(context).colorScheme;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showFeedbackSheet(context, id, name);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: PremiumTheme.glassDecorationOf(context, radius: 16).copyWith(
                  border: Border.all(
                    color: isPresent 
                      ? PremiumTheme.neonGreen.withValues(alpha: 0.4) 
                      : isAbsent 
                        ? Colors.redAccent.withValues(alpha: 0.4)
                        : cs.onSurface.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isPresent ? PremiumTheme.neonGreen : isAbsent ? Colors.redAccent : cs.onSurface.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'P',
                              style: TextStyle(
                                color: isPresent || isAbsent ? Colors.black : cs.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  color: cs.onSurface,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                status == 'UNKNOWN' ? 'coach.not_marked'.tr() : status == 'PRESENT' ? 'coach.present'.tr() : 'coach.absent'.tr(),
                                style: TextStyle(
                                  color: isPresent ? PremiumTheme.neonGreen : isAbsent ? Colors.redAccent : cs.onSurfaceVariant,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() => _attendanceStatus[id] = 'PRESENT');
                          },
                          icon: Icon(Icons.check_circle_rounded, color: isPresent ? PremiumTheme.neonGreen : cs.onSurface.withValues(alpha: 0.2), size: 28),
                        ),
                        IconButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() => _attendanceStatus[id] = 'ABSENT');
                          },
                          icon: Icon(Icons.cancel_rounded, color: isAbsent ? Colors.redAccent : cs.onSurface.withValues(alpha: 0.2), size: 28),
                        ),
                      ],
                    ),
                    if (isAbsent)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextField(
                          onChanged: (val) => _absentReasons[id] = val,
                          controller: TextEditingController(text: _absentReasons[id])..selection = TextSelection.collapsed(offset: _absentReasons[id]?.length ?? 0),
                          decoration: InputDecoration(
                            hintText: 'coach.reason_for_absence'.tr(),
                            hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.1))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.redAccent)),
                          ),
                          style: TextStyle(color: cs.onSurface, fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
          childCount: players.length,
        ),
      ),
    );
  }

  void _showFeedbackSheet(BuildContext context, String playerId, String playerName) {
    if (_selectedSessionId == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoachFeedbackScreen(
          playerId: playerId,
          playerName: playerName,
          sessionId: _selectedSessionId!,
        ),
      ),
    );
  }

  Widget _buildSubmitBtn() {
    if (_selectedSessionId == null) return const SizedBox.shrink();

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        height: 56,
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: PremiumTheme.neonGreen,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            shadowColor: PremiumTheme.neonGreen.withValues(alpha: 0.5),
          ),
          onPressed: _submitAttendance,
          child: Text(
            'coach.save_attendance'.tr().toUpperCase(),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
        ),
      ),
    );
  }

  Future<void> _submitAttendance() async {
    if (_selectedSessionId == null) return;
    HapticFeedback.heavyImpact();

    final selectedTeam = widget.teams.firstWhere(
      (t) => t['id']?.toString() == _selectedTeamId,
      orElse: () => {},
    );
    final players = (selectedTeam['players'] as List?) ?? [];
    
    // prepare attendance records
    final records = <TrainingAttendance>[];
    for (var p in players) {
      final id = p['id']?.toString();
      if (id != null) {
        final status = _attendanceStatus[id] ?? 'ABSENT';
        records.add(TrainingAttendance(
          id: '',
          trainingId: _selectedSessionId!,
          playerId: id,
          status: status,
          note: _absentReasons[id],
        ));
      }
    }

    final provider = context.read<AcademyProvider>();
    final success = await provider.saveSessionAttendance(_selectedSessionId!, records);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('coach.attendance_saved'.tr()),
          backgroundColor: PremiumTheme.neonGreen,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('coach.attendance_error'.tr()),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}

class CoachFeedbackScreen extends StatefulWidget {
  final String playerId;
  final String playerName;
  final String sessionId;

  const CoachFeedbackScreen({
    super.key,
    required this.playerId,
    required this.playerName,
    required this.sessionId,
  });

  @override
  State<CoachFeedbackScreen> createState() => _CoachFeedbackScreenState();
}

class _CoachFeedbackScreenState extends State<CoachFeedbackScreen> {
  double technical = 0;
  double tactical = 0;
  double physical = 0;
  double discipline = 0;
  late final TextEditingController textController;
  late final FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
    focusNode = FocusNode();
  }

  @override
  void dispose() {
    textController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  Widget _buildSlider(BuildContext ctx, String label, double value, ValueChanged<double> onChanged, Color color) {
    final cs = Theme.of(ctx).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.1),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 10,
              divisions: 10,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: PremiumTheme.surfaceBase(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Feedback for ${widget.playerName}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: cs.onSurface),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSlider(context, 'Technical', technical, (v) => setState(() => technical = v), const Color(0xFF42A5F5)),
              _buildSlider(context, 'Tactical', tactical, (v) => setState(() => tactical = v), PremiumTheme.neonGreen),
              _buildSlider(context, 'Physical', physical, (v) => setState(() => physical = v), Colors.amber),
              _buildSlider(context, 'Discipline', discipline, (v) => setState(() => discipline = v), const Color(0xFFB490D0)),
              
              const SizedBox(height: 24),
              TextField(
                key: const ValueKey('feedback_textfield'),
                controller: textController,
                focusNode: focusNode,
                maxLines: 5,
                minLines: 3,
                decoration: InputDecoration(
                  hintText: 'Message to parent...',
                  hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                  filled: true,
                  fillColor: cs.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(color: cs.onSurface, fontSize: 14),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PremiumTheme.neonGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    final provider = context.read<AcademyProvider>();
                    final success = await provider.submitCoachFeedback(
                      widget.playerId, 
                      widget.sessionId, 
                      technical.toInt(), 
                      tactical.toInt(), 
                      physical.toInt(), 
                      discipline.toInt(), 
                      textController.text
                    );
                    if (!mounted) return;
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Feedback sent to parent' : 'Failed to send feedback'),
                          backgroundColor: success ? PremiumTheme.neonGreen : Colors.red,
                        )
                      );
                  },
                  child: const Text('SEND FEEDBACK', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 40), // extra padding at the bottom
            ],
          ),
        ),
      ),
    );
  }
}
