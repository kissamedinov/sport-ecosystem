import 'package:flutter/material.dart';
import 'package:mobile/core/theme/premium_theme.dart';

class CoachPlannerScreen extends StatefulWidget {
  const CoachPlannerScreen({super.key});

  @override
  State<CoachPlannerScreen> createState() => _CoachPlannerScreenState();
}

class _CoachPlannerScreenState extends State<CoachPlannerScreen> {
  DateTime _selected = DateTime.now();
  final Map<String, List<_Task>> _tasks = {};

  String get _key => '${_selected.year}-${_selected.month}-${_selected.day}';

  List<_Task> get _dayTasks => _tasks[_key] ?? [];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('PLANNER', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: cs.surface,
        elevation: 0,
        foregroundColor: cs.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            color: Colors.amber,
            onPressed: _showAddTaskDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildWeekStrip(),
          const SizedBox(height: 8),
          _buildDayHeader(),
          Expanded(child: _buildTaskList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildWeekStrip() {
    final now = DateTime.now();
    final start = _selected.subtract(Duration(days: _selected.weekday - 1));
    final days = List.generate(7, (i) => start.add(Duration(days: i)));
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      height: 72,
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
          final key = '${day.year}-${day.month}-${day.day}';
          final hasTasks = (_tasks[key] ?? []).isNotEmpty;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selected = day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.amber
                      : isToday
                          ? Colors.amber.withValues(alpha: 0.12)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.amber
                        : isToday
                            ? Colors.amber.withValues(alpha: 0.4)
                            : Colors.transparent,
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
                    if (hasTasks)
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 3),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.black54 : Colors.amber,
                          shape: BoxShape.circle,
                        ),
                      ),
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
          Container(width: 3, height: 18, color: Colors.amber, margin: const EdgeInsets.only(right: 8)),
          Text(
            '${weekdays[_selected.weekday - 1]}, ${months[_selected.month - 1]} ${_selected.day}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: cs.onSurface, letterSpacing: 0.3),
          ),
          const Spacer(),
          Text(
            '${_dayTasks.length} tasks',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    if (_dayTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note_rounded, size: 48, color: Colors.amber.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'NO TASKS FOR THIS DAY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add a task',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: _dayTasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildTaskCard(_dayTasks[i], i),
    );
  }

  Widget _buildTaskCard(_Task task, int index) {
    final cs = Theme.of(context).colorScheme;
    final color = _categoryColor(task.category);

    return Dismissible(
      key: Key('$_key-$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
      ),
      onDismissed: (_) {
        setState(() {
          _tasks[_key]!.removeAt(index);
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: task.done
              ? cs.onSurface.withValues(alpha: 0.03)
              : color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: task.done
                ? cs.onSurface.withValues(alpha: 0.08)
                : color.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _tasks[_key]![index] = task.copyWith(done: !task.done)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: task.done ? color : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: task.done ? color : cs.onSurface.withValues(alpha: 0.25), width: 2),
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
                      color: task.done ? cs.onSurfaceVariant : cs.onSurface,
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text('ADD TASK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2, color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Task title...',
                  prefixIcon: const Icon(Icons.edit_rounded, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeCtrl,
                decoration: InputDecoration(
                  hintText: 'Time (e.g. 10:00)',
                  prefixIcon: const Icon(Icons.access_time_rounded, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: categories.map((cat) {
                  final active = cat == category;
                  final color = _categoryColor(cat);
                  return GestureDetector(
                    onTap: () => setSheet(() => category = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? color : color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withValues(alpha: active ? 1 : 0.3)),
                      ),
                      child: Text(cat, style: TextStyle(color: active ? Colors.white : color, fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    setState(() {
                      _tasks.putIfAbsent(_key, () => []);
                      _tasks[_key]!.add(_Task(
                        title: titleCtrl.text.trim(),
                        time: timeCtrl.text.trim().isEmpty ? null : timeCtrl.text.trim(),
                        category: category,
                      ));
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('ADD TASK', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
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
      case 'MATCH': return Colors.redAccent;
      case 'MEETING': return PremiumTheme.electricBlue;
      case 'RECOVERY': return Colors.tealAccent.shade400;
      default: return Colors.amber;
    }
  }
}

class _Task {
  final String title;
  final String? time;
  final String category;
  final bool done;

  const _Task({required this.title, this.time, required this.category, this.done = false});

  _Task copyWith({bool? done}) => _Task(title: title, time: time, category: category, done: done ?? this.done);
}
