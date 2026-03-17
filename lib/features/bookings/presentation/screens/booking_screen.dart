import 'package:flutter/material.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FIELD BOOKING')),
      body: Column(
        children: [
          _buildCalendarStrip(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.stadium, color: Color(0xFF00E676)),
                    ),
                    title: Text('ARENA ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Available: 18:00 - 22:00'),
                    trailing: ElevatedButton(
                      onPressed: () {},
                      child: const Text('BOOK'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarStrip() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2C),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 7,
        itemBuilder: (context, index) {
          final isToday = index == 0;
          return Container(
            width: 60,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isToday ? const Color(0xFF00E676) : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][index],
                  style: TextStyle(
                    fontSize: 10,
                    color: isToday ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${12 + index}',
                  style: TextStyle(
                    fontSize: 18,
                    color: isToday ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
