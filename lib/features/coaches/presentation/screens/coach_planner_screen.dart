import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/theme/premium_theme.dart';

class CoachPlannerScreen extends StatefulWidget {
  const CoachPlannerScreen({super.key});

  @override
  State<CoachPlannerScreen> createState() => _CoachPlannerScreenState();
}

class _CoachPlannerScreenState extends State<CoachPlannerScreen> {
  final ApiClient _api = ApiClient();
  DateTime _selected = DateTime.now();
  List<_Task> _tasks = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  String _dateParam(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadTasks() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/planner/tasks', queryParameters: {'date': _dateParam(_selected)});
      final list = (res.data as List).map((e) => _Task.fromJson(e)).toList();
      if (mounted) setState(() => _tasks = list);
    } catch (_) {
      if (mounted) setState(() => _tasks = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createTask(String title, String? time, String category) async {
    try {
      final res = await _api.post('/planner/tasks', data: {
        'title': title,
        'time': time,
        'category': category,
        'date': _dateParam(_selected),
      });
      final task = _Task.fromJson(res.data);
      if (mounted) setState(() => _tasks.add(task));
    } catch (_) {}
  }

  Future<void> _toggleTask(_Task task) async {
    // Optimistic update
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx == -1) return;
    final updated = task.copyWith(done: !task.done);
    setState(() => _tasks[idx] = updated);
    try {
      await _api.patch('/planner/tasks/${task.id}', data: {'done': updated.done});
    } catch (_) {
      // Revert on failure
      if (mounted) setState(() => _tasks[idx] = task);
    }
  }

  Future<void> _deleteTask(_Task task) async {
    setState(() => _tasks.removeWhere((t) => t.id == task.id));
    try {
      await _api.delete('/planner/tasks/${task.id}');
    } catch (_) {
      // Revert on failure
      if (mounted) setState(() => _tasks.add(task));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      body: Column(
        children: [
          _buildHeader(),
          _buildWeekStrip(),
          const SizedBox(height: 4),
          _buildDayHeader(),
          const SizedBox(height: 8),
          Expanded(child: _loading ? _buildLoading() : _buildTaskList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showAddTaskDialog();
        },
        backgroundColor: PremiumTheme.neonGreen,
        foregroundColor: Colors.black,
        elevation: 4,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: PremiumTheme.neonGreen, strokeWidth: 2),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            const Color(0xFF0D2A1A),
            const Color(0xFF0A1510),
            PremiumTheme.surfaceBase(context),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 16, 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chevron_left_rounded, color: Colors.white70, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'COACH · PLANNER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white54,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showAddTaskDialog();
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: PremiumTheme.neonGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.add_rounded, color: PremiumTheme.neonGreen, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekStrip() {
    final now = DateTime.now();
    final start = _selected.subtract(Duration(days: _selected.weekday - 1));
    final days = List.generate(7, (i) => start.add(Duration(days: i)));
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: List.generate(7, (i) {
          final day = days[i];
          final isSelected = day.day == _selected.day &&
              day.month == _selected.month &&
              day.year == _selected.year;
          final isToday = day.day == now.day &&
              day.month == now.month &&
              day.year == now.year;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selected = day;
                  _tasks = [];
                });
                _loadTasks();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? PremiumTheme.neonGreen
                      : isToday
                          ? PremiumTheme.neonGreen.withValues(alpha: 0.10)
                          : PremiumTheme.glassDecorationOf(context).color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? PremiumTheme.neonGreen
                        : isToday
                            ? PremiumTheme.neonGreen.withValues(alpha: 0.35)
                            : PremiumTheme.borderSubtle(context),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.black
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isSelected
                            ? Colors.black
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 7),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayHeader() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(width: 3, height: 18, color: PremiumTheme.neonGreen, margin: const EdgeInsets.only(right: 8)),
          Text(
            '${weekdays[_selected.weekday - 1]}, ${months[_selected.month - 1]} ${_selected.day}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: cs.onSurface, letterSpacing: 0.3),
          ),
          const Spacer(),
          if (_tasks.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: PremiumTheme.neonGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.25)),
              ),
              child: Text(
                '${_tasks.length} TASKS',
                style: const TextStyle(fontSize: 9, color: PremiumTheme.neonGreen, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: PremiumTheme.neonGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.15)),
              ),
              child: const Icon(Icons.event_note_rounded, size: 36, color: PremiumTheme.neonGreen),
            ),
            const SizedBox(height: 16),
            Text(
              'NO TASKS FOR THIS DAY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap + to schedule a task',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: _tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildTaskCard(_tasks[i]),
    );
  }

  Widget _buildTaskCard(_Task task) {
    final color = _categoryColor(task.category);

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: PremiumTheme.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PremiumTheme.danger.withValues(alpha: 0.2)),
        ),
        child: Icon(Icons.delete_outline_rounded, color: PremiumTheme.danger),
      ),
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        _deleteTask(task);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: PremiumTheme.glassDecorationOf(context, radius: 16).copyWith(
          color: task.done
              ? PremiumTheme.glassDecorationOf(context).color
              : color.withValues(alpha: 0.05),
          border: Border.all(
            color: task.done
                ? PremiumTheme.borderSubtle(context)
                : color.withValues(alpha: 0.20),
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _toggleTask(task);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: task.done ? color : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: task.done ? color : PremiumTheme.borderSubtle(context),
                    width: 2,
                  ),
                ),
                child: task.done
                    ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: task.done
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.onSurface,
                      decoration: task.done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (task.time != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 11, color: color),
                        const SizedBox(width: 4),
                        Text(task.time!, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Text(
                task.category,
                style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    final titleCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    String category = 'TRAINING';
    final categories = ['TRAINING', 'MATCH', 'MEETING', 'RECOVERY', 'OTHER'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: Color(0xFF0F1720),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 24),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const Text(
                'ADD TASK',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white54),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Task title...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
                  prefixIcon: const Icon(Icons.edit_rounded, size: 18, color: PremiumTheme.neonGreen),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                    borderSide: BorderSide(color: PremiumTheme.neonGreen),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Time (e.g. 10:00)',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
                  prefixIcon: const Icon(Icons.access_time_rounded, size: 18, color: PremiumTheme.neonGreen),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                    borderSide: BorderSide(color: PremiumTheme.neonGreen),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'CATEGORY',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Colors.white38),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final active = cat == category;
                  final color = _categoryColor(cat);
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setSheet(() => category = cat);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? color : color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withValues(alpha: active ? 1 : 0.25)),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: active ? Colors.white : color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PremiumTheme.neonGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    HapticFeedback.mediumImpact();
                    Navigator.pop(ctx);
                    _createTask(
                      titleCtrl.text.trim(),
                      timeCtrl.text.trim().isEmpty ? null : timeCtrl.text.trim(),
                      category,
                    );
                  },
                  child: const Text(
                    'ADD TASK',
                    style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'TRAINING': return PremiumTheme.neonGreen;
      case 'MATCH': return PremiumTheme.danger;
      case 'MEETING': return PremiumTheme.electricBlue;
      case 'RECOVERY': return Colors.tealAccent.shade400;
      default: return Colors.amber;
    }
  }
}

class _Task {
  final String id;
  final String title;
  final String? time;
  final String category;
  final bool done;

  const _Task({required this.id, required this.title, this.time, required this.category, this.done = false});

  factory _Task.fromJson(Map<String, dynamic> json) => _Task(
        id: json['id'].toString(),
        title: json['title'],
        time: json['time'],
        category: json['category'],
        done: json['done'] ?? false,
      );

  _Task copyWith({bool? done}) => _Task(id: id, title: title, time: time, category: category, done: done ?? this.done);
}
