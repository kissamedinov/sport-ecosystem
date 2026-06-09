import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/academy_provider.dart';
import '../../data/models/academy_team.dart';
import '../../data/models/crm_models.dart';

const _kGreen  = Color(0xFF00E676);
const _kCard   = Color(0xFF161B22);
const _kNavy   = Color(0xFF0A0E12);

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kNavy,
      appBar: AppBar(
        backgroundColor: _kNavy,
        title: Text(widget.team.name),
      ),
      body: Column(
        children: [
          _buildTeamHeader(),
          TabBar(
            controller: _tabController,
            indicatorColor: _kGreen,
            labelColor: _kGreen,
            unselectedLabelColor: Colors.white54,
            tabs: [
              const Tab(text: 'Игроки'),
              const Tab(text: 'Тренировки'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPlayersList(),
                _buildTrainingSessions(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: _kGreen,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildTeamHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white.withValues(alpha: 0.05),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: _kGreen,
            child: Text(widget.team.ageGroup,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.team.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('Возрастная группа: ${widget.team.ageGroup}',
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersList() {
    return Consumer<AcademyProvider>(
      builder: (context, provider, child) {
        final teamPlayers = provider.players.toList();

        if (teamPlayers.isEmpty) {
          return Center(
            child: Text('Нет игроков в команде',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: teamPlayers.length,
          itemBuilder: (context, index) {
            final player = teamPlayers[index];
            final initials = _initials(player.fullName);
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _kGreen.withValues(alpha: 0.15),
                child: Text(initials,
                    style: const TextStyle(color: _kGreen, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              title: Text(player.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                player.position != null ? player.position! : player.status,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.swap_horiz, color: Colors.blue, size: 20),
                    onPressed: () => _showReassignSheet(player),
                    tooltip: 'Перевести в другую команду',
                  ),
                  IconButton(
                    icon: Icon(Icons.feedback_outlined,
                        color: Colors.white.withValues(alpha: 0.4), size: 20),
                    onPressed: () => _showFeedbackDialog(player),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  void _showReassignSheet(AcademyPlayer player) {
    final provider = context.read<AcademyProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Перевести игрока в команду',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Выберите команду'),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: provider.teams.length,
                itemBuilder: (context, index) {
                  final team = provider.teams[index];
                  if (team.id == widget.team.id) return const SizedBox.shrink();

                  return ListTile(
                    leading: CircleAvatar(child: Text(team.ageGroup)),
                    title: Text(team.name),
                    onTap: () async {
                      final success =
                          await provider.reassignPlayer(player.playerProfileId, team.id);
                      if (success && context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Игрок переведён в ${team.name}')),
                        );
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

  Widget _buildTrainingSessions() {
    return Consumer<AcademyProvider>(
      builder: (context, provider, child) {
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
              const Text('Повторяющееся расписание',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              ...teamSchedules.map((s) => _buildScheduleCard(s, provider)),
              const Divider(height: 32),
            ],
            Row(
              children: [
                const Text('Занятия',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const Spacer(),
                if (teamSchedules.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _generateSessions(provider),
                    icon: const Icon(Icons.autorenew, size: 16, color: _kGreen),
                    label: const Text('Обновить', style: TextStyle(color: _kGreen, fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (teamSessions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.event_busy_rounded,
                          size: 40, color: Colors.white.withValues(alpha: 0.2)),
                      const SizedBox(height: 12),
                      const Text('Занятия ещё не созданы',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text('Нажмите + чтобы создать расписание',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
                    ],
                  ),
                ),
              )
            else
              ...teamSessions.map((session) => _buildSessionCard(session, provider)),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _buildScheduleCard(TrainingSchedule s, AcademyProvider provider) {
    final dayLabel = _dayLabel(s.dayOfWeek.toShortString());
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard,
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
                Text('$dayLabel  ${s.startTime} – ${s.endTime}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                if (s.location != null)
                  Text(s.location!,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
            onPressed: () async {
              await provider.deleteSchedule(widget.team.academyId, s.id);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(TrainingSession session, AcademyProvider provider) {
    final date = _formatDate(session.date);
    final isUpcoming = _isUpcoming(session.date);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUpcoming
              ? _kGreen.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (isUpcoming ? _kGreen : Colors.grey).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.sports_soccer_rounded,
                color: isUpcoming ? _kGreen : Colors.grey, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.description ?? 'Тренировка',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('$date  ·  ${session.startTime}–${session.endTime}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (isUpcoming ? _kGreen : Colors.grey).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isUpcoming ? 'ПРЕДСТОИТ' : 'ПРОШЛО',
              style: TextStyle(
                  color: isUpcoming ? _kGreen : Colors.grey,
                  fontSize: 9,
                  fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      const months = ['янв','фев','мар','апр','май','июн','июл','авг','сен','окт','ноя','дек'];
      const days = ['Пн','Вт','Ср','Чт','Пт','Сб','Вс'];
      final dow = days[d.weekday - 1];
      return '$dow, ${d.day} ${months[d.month - 1]}';
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

  // ── Add dialog routing ─────────────────────────────────────────────────────

  void _showAddDialog() {
    if (_tabController.index == 1) {
      _showScheduleSheet();
    }
    // Players tab: + button not needed for now
  }

  // ── Schedule creation sheet ────────────────────────────────────────────────

  void _showScheduleSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _ScheduleSheet(
        academyId: widget.team.academyId,
        teamId: widget.team.id,
        onSaved: () {
          final provider = context.read<AcademyProvider>();
          _generateSessions(provider);
        },
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

  void _showFeedbackDialog(AcademyPlayer player) {}
}

// ── Schedule creation sheet widget ────────────────────────────────────────────

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
    DayOfWeek.MONDAY: 'Пн',
    DayOfWeek.TUESDAY: 'Вт',
    DayOfWeek.WEDNESDAY: 'Ср',
    DayOfWeek.THURSDAY: 'Чт',
    DayOfWeek.FRIDAY: 'Пт',
    DayOfWeek.SATURDAY: 'Сб',
    DayOfWeek.SUNDAY: 'Вс',
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Создать расписание',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Days of week ─────────────────────────────────
            const Text('ДНИ НЕДЕЛИ',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                    letterSpacing: 1.5, color: Colors.grey)),
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
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: selected
                          ? _kGreen
                          : Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? _kGreen : Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _dayNames[day]!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: selected ? Colors.black : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Time & Duration ──────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('НАЧАЛО',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                              letterSpacing: 1.5, color: Colors.grey)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: _startTime,
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(primary: _kGreen, onPrimary: Colors.black),
                              ),
                              child: child!,
                            ),
                          );
                          if (t != null) setState(() => _startTime = t);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded, color: _kGreen, size: 18),
                              const SizedBox(width: 8),
                              Text(_startTimeStr(),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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
                      const Text('ДЛИТЕЛЬНОСТЬ',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                              letterSpacing: 1.5, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _durationMinutes,
                            dropdownColor: const Color(0xFF1E2530),
                            items: const [
                              DropdownMenuItem(value: 60, child: Text('60 мин')),
                              DropdownMenuItem(value: 90, child: Text('90 мин')),
                              DropdownMenuItem(value: 120, child: Text('2 часа')),
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
            const SizedBox(height: 16),

            // ── End time preview ─────────────────────────────
            Row(
              children: [
                const Icon(Icons.schedule_rounded, color: Colors.grey, size: 14),
                const SizedBox(width: 6),
                Text('Окончание: ${_endTime()}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 20),

            // ── Location ─────────────────────────────────────
            const Text('МЕСТО (необязательно)',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                    letterSpacing: 1.5, color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Поле, зал, адрес...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.07),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kGreen, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),

            // ── Period ───────────────────────────────────────
            const Text('ГЕНЕРИРОВАТЬ НА',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                    letterSpacing: 1.5, color: Colors.grey)),
            const SizedBox(height: 10),
            Row(
              children: [4, 8, 12].map((w) {
                final selected = _weeksAhead == w;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _weeksAhead = w),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? _kGreen : Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? _kGreen : Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text('$w',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: selected ? Colors.black : Colors.white)),
                          Text('нед.',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: selected ? Colors.black87 : Colors.white54)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            // ── Sessions preview ─────────────────────────────
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
                        'Будет создано ~${_estimatedSessions()} занятий до ${_endDateStr()}',
                        style: const TextStyle(color: _kGreen, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Save button ──────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedDays.isEmpty || _saving) ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : Text(
                        'Создать расписание${_selectedDays.length > 1 ? ' (${_selectedDays.length} дня)' : ''}',
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w900, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _estimatedSessions() => _selectedDays.length * _weeksAhead;

  String _endDateStr() {
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
      final end = now.add(Duration(days: _weeksAhead * 7));
      await provider.triggerGenerateSessions(widget.academyId, now, end);
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
