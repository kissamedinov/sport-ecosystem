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
              tabs: const [Tab(text: 'Игроки'), Tab(text: 'Тренировки')],
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
                Text('Возрастная группа: ${widget.team.ageGroup}',
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
        final players = provider.players.toList();
        if (players.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off_rounded,
                    size: 48, color: onSurface.withValues(alpha: 0.15)),
                const SizedBox(height: 12),
                Text('Нет игроков в команде',
                    style: _t(14, FontWeight.w500, onSurface.withValues(alpha: 0.35))),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: players.length,
          itemBuilder: (context, index) => _buildPlayerTile(context, players[index], index),
        );
      },
    );
  }

  Widget _buildPlayerTile(BuildContext context, AcademyPlayer player, int index) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final initials = _initials(player.fullName);
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
        title: Text(player.fullName, style: _t(14, FontWeight.w600, onSurface)),
        subtitle: Text(
          player.position ?? player.status,
          style: _t(11, FontWeight.w400, onSurface.withValues(alpha: 0.45)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF1E90D4), size: 20),
              onPressed: () => _showReassignSheet(context, player),
              tooltip: 'Перевести в другую команду',
            ),
            IconButton(
              icon: Icon(Icons.feedback_outlined,
                  color: onSurface.withValues(alpha: 0.3), size: 20),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  void _showReassignSheet(BuildContext context, AcademyPlayer player) {
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
            Text('Перевести в команду', style: _t(18, FontWeight.w700, onSurface)),
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
                              ? 'Игрок переведён в ${team.name}'
                              : 'Ошибка перевода'),
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
              Text('Повторяющееся расписание',
                  style: _t(14, FontWeight.w700, onSurface)),
              const SizedBox(height: 8),
              ...teamSchedules.map((s) => _buildScheduleCard(context, s, provider)),
              Divider(height: 32, color: PremiumTheme.borderSubtle(context).withValues(alpha: 0.5)),
            ],
            Row(
              children: [
                Text('Занятия', style: _t(14, FontWeight.w700, onSurface)),
                const Spacer(),
                if (teamSchedules.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _generateSessions(provider),
                    icon: const Icon(Icons.autorenew_rounded, size: 14, color: _kGreen),
                    label: Text('Обновить', style: _t(12, FontWeight.w600, _kGreen)),
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
                    Text('Занятия ещё не созданы',
                        textAlign: TextAlign.center,
                        style: _t(14, FontWeight.w500, onSurface.withValues(alpha: 0.35))),
                    const SizedBox(height: 6),
                    Text('Нажмите + чтобы создать расписание',
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
                Text(session.description ?? 'Тренировка',
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
              isUpcoming ? 'ПРЕДСТОИТ' : 'ПРОШЛО',
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
      const months = ['янв','фев','мар','апр','май','июн','июл','авг','сен','окт','ноя','дек'];
      const days = ['Пн','Вт','Ср','Чт','Пт','Сб','Вс'];
      return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
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
    const map = {
      'MONDAY': 'Понедельник', 'TUESDAY': 'Вторник', 'WEDNESDAY': 'Среда',
      'THURSDAY': 'Четверг', 'FRIDAY': 'Пятница', 'SATURDAY': 'Суббота', 'SUNDAY': 'Воскресенье',
    };
    return map[day] ?? day;
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
        const SnackBar(content: Text('Занятия обновлены'), backgroundColor: _kGreen),
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

  static const _dayNames = {
    DayOfWeek.MONDAY: 'Пн', DayOfWeek.TUESDAY: 'Вт', DayOfWeek.WEDNESDAY: 'Ср',
    DayOfWeek.THURSDAY: 'Чт', DayOfWeek.FRIDAY: 'Пт',
    DayOfWeek.SATURDAY: 'Сб', DayOfWeek.SUNDAY: 'Вс',
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
                Text('Создать расписание', style: _t(18, FontWeight.w700, onSurface)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: onSurface.withValues(alpha: 0.5)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Days
            Text('ДНИ НЕДЕЛИ',
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
                        _dayNames[day]!,
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
                      Text('НАЧАЛО',
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
                      Text('ДЛИТЕЛЬНОСТЬ',
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
                              DropdownMenuItem(value: 60, child: Text('60 мин', style: _t(13, FontWeight.w500, onSurface))),
                              DropdownMenuItem(value: 90, child: Text('90 мин', style: _t(13, FontWeight.w500, onSurface))),
                              DropdownMenuItem(value: 120, child: Text('2 часа', style: _t(13, FontWeight.w500, onSurface))),
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
                Text('Окончание: ${_endTime()}',
                    style: _t(12, FontWeight.w400, onSurface.withValues(alpha: 0.45))),
              ],
            ),
            const SizedBox(height: 20),

            // Location
            Text('МЕСТО (необязательно)',
                style: _t(9, FontWeight.w800, onSurface.withValues(alpha: 0.4), ls: 1.5)),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              style: _t(14, FontWeight.w500, onSurface),
              decoration: InputDecoration(
                hintText: 'Поле, зал, адрес...',
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
            Text('ГЕНЕРИРОВАТЬ НА',
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
                          Text('нед.', style: _t(11, FontWeight.w500,
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
                        'Будет создано ~${_selectedDays.length * _weeksAhead} занятий до $_endDateStr',
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
                          'Создать расписание${_selectedDays.length > 1 ? " (${_selectedDays.length} дня)" : ""}',
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

  String get _endDateStr {
    final end = DateTime.now().add(Duration(days: _weeksAhead * 7));
    const months = ['янв','фев','мар','апр','май','июн','июл','авг','сен','окт','ноя','дек'];
    return '${end.day} ${months[end.month - 1]}';
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
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
