import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/academy_provider.dart';
import '../../data/models/academy_team.dart';
import '../../data/models/crm_models.dart';
import '../../../../core/theme/premium_theme.dart';

const _kGreen = Color(0xFF00E676);

TextStyle _t(double size, FontWeight w, Color color, {double ls = 0}) =>
    GoogleFonts.outfit(fontSize: size, fontWeight: w, color: color, letterSpacing: ls);

class AcademyTeamDetailsScreen extends StatefulWidget {
  final AcademyTeam team;
  const AcademyTeamDetailsScreen({super.key, required this.team});

  @override
  State<AcademyTeamDetailsScreen> createState() => _AcademyTeamDetailsScreenState();
}

class _AcademyTeamDetailsScreenState extends State<AcademyTeamDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    Future.microtask(() {
      if (mounted) {
        context.read<AcademyProvider>().fetchTeamPlayers(widget.team.id);
        if (context.read<AcademyProvider>().players.isEmpty) {
          context.read<AcademyProvider>().fetchAcademyPlayers(widget.team.academyId);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isScheduleTab = _tabController.index == 1;

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: PremiumTheme.surfaceCard(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: onSurface, size: 18),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(widget.team.name,
            style: _t(17, FontWeight.w700, onSurface)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildTeamHeader(context),
          Container(
            color: PremiumTheme.surfaceCard(context),
            child: TabBar(
              controller: _tabController,
              indicatorColor: _kGreen,
              indicatorWeight: 2.5,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: _kGreen,
              unselectedLabelColor: onSurface.withValues(alpha: 0.4),
              labelStyle: _t(13, FontWeight.w700, _kGreen),
              unselectedLabelStyle: _t(13, FontWeight.w500, onSurface),
              tabs: [Tab(text: 'academy.players'.tr()), Tab(text: 'academy.training'.tr())],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildPlayersList(context), _buildTrainingSessions(context)],
            ),
          ),
        ],
      ),
      floatingActionButton: isScheduleTab
          ? _buildFab(context)
          : null,
    );
  }

  Widget _buildFab(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kGreen, Color(0xFF00C853)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _kGreen.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _showScheduleSheet,
          child: const Icon(Icons.add_rounded, color: Colors.black, size: 26),
        ),
      ),
    );
  }

  Widget _buildTeamHeader(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      color: PremiumTheme.surfaceCard(context),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_kGreen.withValues(alpha: 0.25), _kGreen.withValues(alpha: 0.08)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: _kGreen.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Text(widget.team.ageGroup,
                  textAlign: TextAlign.center,
                  style: _t(10, FontWeight.w900, _kGreen)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.team.name, style: _t(17, FontWeight.w700, onSurface)),
                const SizedBox(height: 2),
                Text('academy.age_group_header'.tr(namedArgs: {'age': widget.team.ageGroup}),
                    style: _t(12, FontWeight.w400, onSurface.withValues(alpha: 0.45))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Players tab ─────────────────────────────────────────────────────────────
  Widget _buildPlayersList(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Consumer<AcademyProvider>(
      builder: (context, provider, _) {
        final players = provider.teamPlayers.toList();
        if (players.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off_rounded,
                    size: 48, color: onSurface.withValues(alpha: 0.15)),
                const SizedBox(height: 12),
                Text('academy.no_players_in_team'.tr(),
                    style: _t(14, FontWeight.w500, onSurface.withValues(alpha: 0.35))),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: players.length,
          itemBuilder: (context, index) => _buildPlayerTile(context, players[index], index, provider),
        );
      },
    );
  }

  Widget _buildPlayerTile(BuildContext context, AcademyTeamPlayer player, int index, AcademyProvider provider) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    
    // Fallback: try to find the player in the main academy roster to get the real name
    String? resolvedName = player.fullName;
    if (resolvedName == null || resolvedName.startsWith('{')) {
      final rosterMatch = provider.players.where((p) => p.playerProfileId == player.playerProfileId).firstOrNull;
      if (rosterMatch != null) {
        resolvedName = rosterMatch.fullName;
      } else {
        resolvedName = 'academy.unknown_player'.tr();
      }
    }
    if (resolvedName.trim().isEmpty) resolvedName = 'academy.unknown_player'.tr();

    final initials = _initials(resolvedName);
    const palette = [_kGreen, Color(0xFF1E90D4), Color(0xFFF5C518),
                     Color(0xFFB388FF), Color(0xFFFF9800), Color(0xFFFF5252)];
    final accent = palette[index % palette.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: PremiumTheme.surfaceCard(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PremiumTheme.borderSubtle(context).withValues(alpha: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent.withValues(alpha: 0.3), accent.withValues(alpha: 0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: accent.withValues(alpha: 0.4)),
          ),
          child: Center(
            child: Text(initials, style: _t(13, FontWeight.w800, accent)),
          ),
        ),
        title: Text(resolvedName, style: _t(14, FontWeight.w600, onSurface)),
        subtitle: Text(
          player.position ?? 'academy.player_label'.tr(),
          style: _t(11, FontWeight.w400, onSurface.withValues(alpha: 0.45)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF1E90D4), size: 20),
              onPressed: () => _showReassignSheet(context, player),
              tooltip: 'academy.transfer_to_another_team'.tr(),
            ),
            IconButton(
              icon: Icon(Icons.contact_mail_outlined,
                  color: onSurface.withValues(alpha: 0.3), size: 20),
              onPressed: () => _showParentInfoSheet(context, player),
              tooltip: 'academy.contact_parent'.tr(),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    if (name == '?') return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  void _showReassignSheet(BuildContext context, AcademyTeamPlayer player) {
    final provider = context.read<AcademyProvider>();
    final onSurface = Theme.of(context).colorScheme.onSurface;

    showModalBottomSheet(
      context: context,
      backgroundColor: PremiumTheme.surfaceCard(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 20, right: 20, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: onSurface.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('academy.move_player_to_team'.tr(), style: _t(18, FontWeight.w700, onSurface)),
            const SizedBox(height: 16),
            SizedBox(
              height: 260,
              child: ListView.builder(
                itemCount: provider.teams.length,
                itemBuilder: (ctx2, i) {
                  final team = provider.teams[i];
                  if (team.id == widget.team.id) return const SizedBox.shrink();
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _kGreen.withValues(alpha: 0.15),
                      child: Text(team.ageGroup,
                          style: _t(9, FontWeight.w800, _kGreen)),
                    ),
                    title: Text(team.name, style: _t(13, FontWeight.w600, onSurface)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final ok = await provider.reassignPlayer(player.playerProfileId, team.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok
                              ? 'academy.player_moved_to'.tr(namedArgs: {'team': team.name})
                              : 'academy.transfer_error'.tr()),
                          backgroundColor: ok ? _kGreen : Colors.redAccent,
                        ));
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showParentInfoSheet(BuildContext context, AcademyTeamPlayer player) {
    final provider = context.read<AcademyProvider>();
    final onSurface = Theme.of(context).colorScheme.onSurface;

    showModalBottomSheet(
      context: context,
      backgroundColor: PremiumTheme.surfaceCard(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (ctx) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: provider.fetchPlayerParents(player.playerProfileId),
          builder: (context, snapshot) {
            Widget content;
            if (snapshot.connectionState == ConnectionState.waiting) {
              content = const Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: _kGreen),
              ));
            } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              content = Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(Icons.person_off_rounded, size: 48, color: onSurface.withValues(alpha: 0.15)),
                    const SizedBox(height: 12),
                    Text('academy.parent_not_linked'.tr(),
                        style: _t(14, FontWeight.w500, onSurface.withValues(alpha: 0.35))),
                  ],
                ),
              );
            } else {
              content = Column(
                children: snapshot.data!.map((parent) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _kGreen.withValues(alpha: 0.15),
                      child: const Icon(Icons.person, color: _kGreen, size: 20),
                    ),
                    title: Text(parent['name'] ?? 'academy.unknown'.tr(), style: _t(15, FontWeight.w600, onSurface)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(parent['relation_type'] ?? '', style: _t(12, FontWeight.w500, _kGreen)),
                        if (parent['email'] != null) Text(parent['email'], style: _t(13, FontWeight.w400, onSurface)),
                        if (parent['phone'] != null) Text(parent['phone'], style: _t(13, FontWeight.w400, onSurface)),
                      ],
                    ),
                  );
                }).toList(),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                  left: 20, right: 20, top: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: onSurface.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('academy.contact_parent'.tr(), style: _t(18, FontWeight.w700, onSurface)),
                  const SizedBox(height: 16),
                  content,
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Schedule tab ────────────────────────────────────────────────────────────
  Widget _buildTrainingSessions(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Consumer<AcademyProvider>(
      builder: (context, provider, _) {
        final teamSessions = provider.sessions
            .where((s) => s.teamIds.contains(widget.team.id))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        final teamSchedules =
            provider.schedules.where((s) => s.teamIds.contains(widget.team.id)).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (teamSchedules.isNotEmpty) ...[
              Text('academy.recurring_schedule_title'.tr(),
                  style: _t(14, FontWeight.w700, onSurface)),
              const SizedBox(height: 8),
              ...teamSchedules.map((s) => _buildScheduleCard(context, s, provider)),
              Divider(height: 32, color: PremiumTheme.borderSubtle(context).withValues(alpha: 0.5)),
            ],
            Row(
              children: [
                Text('academy.sessions'.tr(), style: _t(14, FontWeight.w700, onSurface)),
                const Spacer(),
                if (teamSchedules.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _generateSessions(provider),
                    icon: const Icon(Icons.autorenew_rounded, size: 14, color: _kGreen),
                    label: Text('academy.refresh'.tr(), style: _t(12, FontWeight.w600, _kGreen)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (teamSessions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.event_busy_rounded,
                        size: 40, color: onSurface.withValues(alpha: 0.15)),
                    const SizedBox(height: 12),
                    Text('academy.no_sessions_created'.tr(),
                        textAlign: TextAlign.center,
                        style: _t(14, FontWeight.w500, onSurface.withValues(alpha: 0.35))),
                    const SizedBox(height: 6),
                    Text('academy.create_schedule_hint'.tr(),
                        textAlign: TextAlign.center,
                        style: _t(12, FontWeight.w400, onSurface.withValues(alpha: 0.25))),
                  ],
                ),
              )
            else
              ...teamSessions.map((s) => _buildSessionCard(context, s)),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _buildScheduleCard(BuildContext context, TrainingSchedule s, AcademyProvider provider) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PremiumTheme.surfaceCard(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kGreen.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.repeat_rounded, color: _kGreen, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_dayLabel(s.dayOfWeek.toShortString())}  ${s.startTime} – ${s.endTime}',
                  style: _t(13, FontWeight.w700, onSurface),
                ),
                if (s.location != null)
                  Text(s.location!,
                      style: _t(11, FontWeight.w400, onSurface.withValues(alpha: 0.45))),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
            onPressed: () => provider.deleteSchedule(widget.team.academyId, s.id),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, TrainingSession session) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isUpcoming = _isUpcoming(session.date);
    final statusColor = isUpcoming ? _kGreen : onSurface.withValues(alpha: 0.35);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PremiumTheme.surfaceCard(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUpcoming
              ? _kGreen.withValues(alpha: 0.3)
              : PremiumTheme.borderSubtle(context).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.sports_soccer_rounded, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.description ?? 'academy.training_fallback'.tr(),
                    style: _t(13, FontWeight.w600, onSurface)),
                Text('${_formatDate(session.date)}  ·  ${session.startTime}–${session.endTime}',
                    style: _t(11, FontWeight.w400, onSurface.withValues(alpha: 0.45))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isUpcoming ? 'academy.upcoming_status'.tr() : 'academy.past_status'.tr(),
              style: _t(9, FontWeight.w900, statusColor, ls: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      final lang = context.locale.languageCode;
      final safeLocale = lang == 'kk' ? 'ru' : lang;
      return DateFormat('EEE, d MMM', safeLocale).format(d);
    } catch (_) {
      return dateStr;
    }
  }

  bool _isUpcoming(String dateStr) {
    try {
      return DateTime.parse(dateStr).isAfter(DateTime.now().subtract(const Duration(hours: 3)));
    } catch (_) {
      return false;
    }
  }

  String _dayLabel(String day) {
    final key = 'academy.day_${day.toLowerCase()}';
    return key.tr();
  }

  void _showScheduleSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: PremiumTheme.surfaceCard(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _ScheduleSheet(
        academyId: widget.team.academyId,
        teamId: widget.team.id,
        onSaved: () => _generateSessions(context.read<AcademyProvider>()),
      ),
    );
  }

  Future<void> _generateSessions(AcademyProvider provider) async {
    await provider.generateSessions(widget.team.academyId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('academy.sessions_updated'.tr()), backgroundColor: _kGreen),
      );
    }
  }
}

// ── Schedule creation sheet ────────────────────────────────────────────────────
class _ScheduleSheet extends StatefulWidget {
  final String academyId;
  final String teamId;
  final VoidCallback onSaved;

  const _ScheduleSheet({
    required this.academyId,
    required this.teamId,
    required this.onSaved,
  });

  @override
  State<_ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<_ScheduleSheet> {
  final Set<DayOfWeek> _selectedDays = {};
  TimeOfDay _startTime = const TimeOfDay(hour: 16, minute: 0);
  int _durationMinutes = 90;
  final _locationController = TextEditingController();
  int _weeksAhead = 4;
  bool _saving = false;

  static const _dayKeys = {
    DayOfWeek.MONDAY: 'academy.day_mon_short',
    DayOfWeek.TUESDAY: 'academy.day_tue_short',
    DayOfWeek.WEDNESDAY: 'academy.day_wed_short',
    DayOfWeek.THURSDAY: 'academy.day_thu_short',
    DayOfWeek.FRIDAY: 'academy.day_fri_short',
    DayOfWeek.SATURDAY: 'academy.day_sat_short',
    DayOfWeek.SUNDAY: 'academy.day_sun_short',
  };

  String _endTime() {
    final total = _startTime.hour * 60 + _startTime.minute + _durationMinutes;
    final h = (total ~/ 60) % 24;
    final m = total % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String _startTimeStr() =>
      '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final borderColor = PremiumTheme.borderSubtle(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: onSurface.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('academy.create_schedule'.tr(), style: _t(18, FontWeight.w700, onSurface)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: onSurface.withValues(alpha: 0.5)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Days
            Text('academy.days_of_week_label'.tr(),
                style: _t(9, FontWeight.w800, onSurface.withValues(alpha: 0.4), ls: 1.5)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: DayOfWeek.values.map((day) {
                final selected = _selectedDays.contains(day);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedDays.remove(day);
                    } else {
                      _selectedDays.add(day);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: selected ? _kGreen : onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? _kGreen : borderColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _dayKeys[day]!.tr(),
                        style: _t(12, FontWeight.w800,
                            selected ? Colors.black : onSurface.withValues(alpha: 0.7)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Time & Duration
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('academy.start_time_label'.tr(),
                          style: _t(9, FontWeight.w800, onSurface.withValues(alpha: 0.4), ls: 1.5)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: _startTime,
                          );
                          if (t != null) setState(() => _startTime = t);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: onSurface.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _kGreen.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded, color: _kGreen, size: 18),
                              const SizedBox(width: 8),
                              Text(_startTimeStr(), style: _t(18, FontWeight.w800, onSurface)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('academy.duration_label'.tr(),
                          style: _t(9, FontWeight.w800, onSurface.withValues(alpha: 0.4), ls: 1.5)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: onSurface.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor.withValues(alpha: 0.5)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _durationMinutes,
                            dropdownColor: PremiumTheme.surfaceCard(context),
                            style: _t(14, FontWeight.w500, onSurface),
                            items: [
                              DropdownMenuItem(value: 60, child: Text('academy.duration_60'.tr(), style: _t(13, FontWeight.w500, onSurface))),
                              DropdownMenuItem(value: 90, child: Text('academy.duration_90'.tr(), style: _t(13, FontWeight.w500, onSurface))),
                              DropdownMenuItem(value: 120, child: Text('academy.duration_120'.tr(), style: _t(13, FontWeight.w500, onSurface))),
                            ],
                            onChanged: (v) => setState(() => _durationMinutes = v!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.schedule_rounded, color: onSurface.withValues(alpha: 0.35), size: 14),
                const SizedBox(width: 6),
                Text('academy.end_time_info'.tr(namedArgs: {'time': _endTime()}),
                    style: _t(12, FontWeight.w400, onSurface.withValues(alpha: 0.45))),
              ],
            ),
            const SizedBox(height: 20),

            // Location
            Text('academy.location_optional_label'.tr(),
                style: _t(9, FontWeight.w800, onSurface.withValues(alpha: 0.4), ls: 1.5)),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              style: _t(14, FontWeight.w500, onSurface),
              decoration: InputDecoration(
                hintText: 'academy.location_hint_text'.tr(),
                hintStyle: _t(13, FontWeight.w400, onSurface.withValues(alpha: 0.3)),
                filled: true,
                fillColor: onSurface.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor.withValues(alpha: 0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor.withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kGreen, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),

            // Period
            Text('academy.generate_for_label'.tr(),
                style: _t(9, FontWeight.w800, onSurface.withValues(alpha: 0.4), ls: 1.5)),
            const SizedBox(height: 10),
            Row(
              children: [4, 8, 12].map((w) {
                final sel = _weeksAhead == w;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _weeksAhead = w),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: sel ? _kGreen : onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel ? _kGreen : borderColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text('$w', style: _t(20, FontWeight.w900,
                              sel ? Colors.black : onSurface)),
                          Text('academy.weeks_abbr'.tr(), style: _t(11, FontWeight.w500,
                              sel ? Colors.black87 : onSurface.withValues(alpha: 0.45))),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            if (_selectedDays.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kGreen.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: _kGreen, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'academy.sessions_preview'.tr(namedArgs: {
                          'count': '${_selectedDays.length * _weeksAhead}',
                          'date': _getEndDateStr(context),
                        }),
                        style: _t(12, FontWeight.w400, _kGreen),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: _selectedDays.isNotEmpty
                      ? const LinearGradient(colors: [_kGreen, Color(0xFF00C853)])
                      : null,
                  color: _selectedDays.isEmpty ? onSurface.withValues(alpha: 0.08) : null,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _selectedDays.isNotEmpty
                      ? [BoxShadow(color: _kGreen.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))]
                      : null,
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: (_selectedDays.isEmpty || _saving) ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text(
                          _selectedDays.length > 1
                              ? 'academy.create_schedule_days'.tr(namedArgs: {'count': '${_selectedDays.length}'})
                              : 'academy.create_schedule'.tr(),
                          style: _t(15, FontWeight.w900,
                              _selectedDays.isNotEmpty ? Colors.black : onSurface.withValues(alpha: 0.3)),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEndDateStr(BuildContext context) {
    final end = DateTime.now().add(Duration(days: _weeksAhead * 7));
    final lang = context.locale.languageCode;
    final safeLocale = lang == 'kk' ? 'ru' : lang;
    return DateFormat('d MMM', safeLocale).format(end);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final provider = context.read<AcademyProvider>();
    try {
      for (final day in _selectedDays) {
        await provider.createSchedule(widget.academyId, {
          'team_ids': [widget.teamId],
          'day_of_week': day.toShortString(),
          'start_time': _startTimeStr(),
          'end_time': _endTime(),
          'location': _locationController.text.isEmpty ? null : _locationController.text,
        });
      }
      final now = DateTime.now();
      await provider.triggerGenerateSessions(widget.academyId, now, now.add(Duration(days: _weeksAhead * 7)));
      await provider.fetchSchedules(widget.academyId);
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('academy.save_error'.tr(namedArgs: {'error': '$e'})), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
