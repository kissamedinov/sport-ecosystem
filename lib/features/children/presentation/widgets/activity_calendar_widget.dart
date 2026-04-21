import 'package:flutter/material.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:intl/intl.dart';

class ActivityCalendarWidget extends StatefulWidget {
  final List<dynamic> activities;
  final Function(DateTime) onDateSelected;

  const ActivityCalendarWidget({
    super.key,
    required this.activities,
    required this.onDateSelected,
  });

  @override
  State<ActivityCalendarWidget> createState() => _ActivityCalendarWidgetState();
}

class _ActivityCalendarWidgetState extends State<ActivityCalendarWidget> {
  DateTime _selectedDate = DateTime.now();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Scroll to center or selected date could be added here
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDateStrip(),
        Expanded(
          child: _buildActivityList(),
        ),
      ],
    );
  }

  Widget _buildDateStrip() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 30, // Show next 30 days
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = DateUtils.isSameDay(date, _selectedDate);
          final dayName = DateFormat('E').format(date).toUpperCase();
          final dayNum = date.day.toString();

          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = date);
              widget.onDateSelected(date);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? PremiumTheme.neonGreen : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? PremiumTheme.neonGreen : Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: PremiumTheme.neonGreen.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ] : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayNum,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityList() {
    final dailyActivities = widget.activities.where((a) {
      // Logic to filter activities by _selectedDate
      // TrainingSession has scheduledAt (ISO string)
      final dateStr = a.scheduledAt ?? a.date;
      if (dateStr == null) return false;
      final activityDate = DateTime.parse(dateStr);
      return DateUtils.isSameDay(activityDate, _selectedDate);
    }).toList();

    if (dailyActivities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, color: Colors.white10, size: 48),
            const SizedBox(height: 16),
            Text(
              'RELAX DAY',
              style: TextStyle(
                color: Colors.white24,
                letterSpacing: 2,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'No activities scheduled',
              style: TextStyle(color: Colors.white10, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dailyActivities.length,
      itemBuilder: (context, index) {
        final activity = dailyActivities[index];
        final isTraining = activity.topic != null || activity.title?.contains('Training') == true;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: PremiumTheme.cardNavy,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: isTraining ? PremiumTheme.electricBlue : Colors.amber,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('HH:mm').format(DateTime.parse(activity.scheduledAt ?? activity.date)),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const Text(
                              'START',
                              style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isTraining ? 'TRAINING' : 'MATCH',
                                style: TextStyle(
                                  color: isTraining ? PremiumTheme.electricBlue : Colors.amber,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                activity.title ?? activity.topic ?? 'Session',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: Colors.white24, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    activity.location ?? 'Main Field',
                                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
