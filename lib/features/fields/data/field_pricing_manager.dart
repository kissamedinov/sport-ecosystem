import 'package:flutter/material.dart';

class FieldPricingManager extends ChangeNotifier {
  static final FieldPricingManager _instance = FieldPricingManager._internal();
  factory FieldPricingManager() => _instance;
  FieldPricingManager._internal();

  // Pricing rule parameters (multipliers)
  double primeTimeMultiplier = 1.20; // +20%
  double weekendMultiplier = 1.30; // +30%
  double nightOwlMultiplier = 0.65; // -35%

  // Business stats
  double todayRevenue = 25000;
  double occupancy = 0.85;

  // Shared Promo Codes
  final List<Map<String, dynamic>> promoCodes = [
    {
      'code': 'SAIRAN10',
      'discount': 10,
      'uses': '14/50',
      'status': 'ACTIVE',
      'expiry': '10 Jun 2026',
    },
    {
      'code': 'NIGHTPLAY30',
      'discount': 30,
      'uses': '8/20',
      'status': 'ACTIVE',
      'expiry': '15 Jun 2026',
    },
    {
      'code': 'SPRING20',
      'discount': 20,
      'uses': '30/30',
      'status': 'EXPIRED',
      'expiry': '01 May 2026',
    },
  ];

  // Blocked slots: "fieldName_dateDay_time" -> e.g. "SAIRAN ARENA_3_18:30 - 20:00"
  final Set<String> blockedSlots = {};

  // Log of client bookings (mock bookings database)
  final List<Map<String, dynamic>> pendingRequests = [
    {
      'id': 'req-org-mock',
      'clientName': 'Tournament Organizer',
      'field': 'SAIRAN ARENA',
      'date': 'WED, 3 June',
      'day': 3,
      'time': '09:00 - 12:00',
      'price': 27000.0,
      'status': 'PENDING',
    },
    {
      'id': 'req-1',
      'clientName': 'Dias Kasimov',
      'field': 'SAIRAN ARENA',
      'date': 'WED, 3 June',
      'day': 3,
      'time': '18:30 - 20:00',
      'price': 18000.0,
      'status': 'PENDING',
    },
    {
      'id': 'req-2',
      'clientName': 'Alisher Karim',
      'field': 'SPORT CITY PITCHES',
      'date': 'FRI, 5 June',
      'day': 5,
      'time': '20:00 - 21:30',
      'price': 14400.0,
      'status': 'PENDING',
    },
    {
      'id': 'req-3',
      'clientName': 'Olzhas Smakov',
      'field': 'ASTANA ARENA',
      'date': 'SAT, 6 June',
      'day': 6,
      'time': '12:00 - 13:30',
      'price': 32500.0,
      'status': 'PENDING',
    },
  ];

  void notify() {
    notifyListeners();
  }

  void blockSlot(String fieldName, int day, String time) {
    blockedSlots.add('${fieldName}_${day}_$time');
    notify();
  }

  void unblockSlot(String fieldName, int day, String time) {
    blockedSlots.remove('${fieldName}_${day}_$time');
    notify();
  }

  bool isSlotBlocked(String fieldName, int day, String time) {
    return blockedSlots.contains('${fieldName}_${day}_$time');
  }
}
