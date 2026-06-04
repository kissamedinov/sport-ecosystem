import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/premium_theme.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _selectedDateIndex = 0;

  final List<Map<String, dynamic>> _arenas = [
    {
      'name': 'ARENA 1',
      'type': 'Indoor / 5x5',
      'price': '15,000 ₸',
      'surface': 'Artificial Turf',
      'hours': '18:00 - 22:00',
    },
    {
      'name': 'ARENA 2',
      'type': 'Outdoor / 6x6',
      'price': '12,000 ₸',
      'surface': 'Natural Grass',
      'hours': '10:00 - 00:00',
    },
    {
      'name': 'ELITE ARENA',
      'type': 'Indoor / 7x7',
      'price': '25,000 ₸',
      'surface': 'Hybrid Pro',
      'hours': '08:00 - 23:00',
    },
    {
      'name': 'TRAINING HUB',
      'type': 'Covered / 5x5',
      'price': '10,000 ₸',
      'surface': 'Rubber Multi',
      'hours': '12:00 - 22:00',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        title: Text(
          'field.book_field'.tr(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _arenas.length,
              itemBuilder: (context, index) {
                return _buildArenaCard(_arenas[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      height: 110,
      margin: const EdgeInsets.only(top: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 14, // 2 weeks
        itemBuilder: (context, index) {
          final isSelected = _selectedDateIndex == index;
          final date = DateTime.now().add(Duration(days: index));
          final dayName = _getDayName(date.weekday);
          
          return GestureDetector(
            onTap: () => setState(() => _selectedDateIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 65,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: isSelected ? PremiumTheme.primaryGradient : null,
                color: isSelected ? null : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(18),
                boxShadow: isSelected ? PremiumTheme.neonShadow(color: PremiumTheme.neonGreen.withValues(alpha: 0.3)) : null,
                border: Border.all(
                  color: isSelected ? Colors.transparent : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.black : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.black : Theme.of(context).colorScheme.onSurface,
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

  Widget _buildArenaCard(Map<String, dynamic> arena) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.stadium_rounded, color: PremiumTheme.neonGreen, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      arena['name'],
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: onSurface, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      arena['type'],
                      style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  arena['price'],
                  style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoChip(Icons.grass_rounded, arena['surface']),
              _buildInfoChip(Icons.access_time_filled_rounded, arena['hours']),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: PremiumTheme.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: PremiumTheme.neonShadow(),
              ),
              child: Center(
                child: Text(
                  'field.book_field'.tr(),
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _getDayName(int day) {
    return ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][day - 1];
  }
}
