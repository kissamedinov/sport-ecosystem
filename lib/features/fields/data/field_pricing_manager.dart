import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Load blocked slots
      final savedBlocked = prefs.getStringList('blocked_slots');
      debugPrint("FieldPricingManager: Loading blocked slots from SharedPreferences: $savedBlocked");
      if (savedBlocked != null) {
        blockedSlots.clear();
        blockedSlots.addAll(savedBlocked);
      }

      // 2. Load pending/manual bookings list
      final savedRequests = prefs.getString('pending_requests');
      debugPrint("FieldPricingManager: Loading pending requests from SharedPreferences: $savedRequests");
      if (savedRequests != null) {
        final List<dynamic> decoded = jsonDecode(savedRequests);
        pendingRequests.clear();
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            pendingRequests.add(item);
          }
        }
      }

      // 3. Load promo codes
      final savedPromo = prefs.getString('promo_codes');
      if (savedPromo != null) {
        final List<dynamic> decoded = jsonDecode(savedPromo);
        promoCodes.clear();
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            promoCodes.add(item);
          }
        }
      }

      // 4. Load stats
      todayRevenue = prefs.getDouble('today_revenue') ?? todayRevenue;
      occupancy = prefs.getDouble('occupancy') ?? occupancy;
      debugPrint("FieldPricingManager: Load completed. blockedSlots count: ${blockedSlots.length}, pendingRequests count: ${pendingRequests.length}");
    } catch (e) {
      debugPrint("Error initializing FieldPricingManager: $e");
    }
    notifyListeners();
  }

  Future<void> saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      debugPrint("FieldPricingManager: Saving blocked slots to SharedPreferences: ${blockedSlots.toList()}");
      await prefs.setStringList('blocked_slots', blockedSlots.toList());
      debugPrint("FieldPricingManager: Saving pending requests to SharedPreferences: ${jsonEncode(pendingRequests)}");
      await prefs.setString('pending_requests', jsonEncode(pendingRequests));
      await prefs.setString('promo_codes', jsonEncode(promoCodes));
      await prefs.setDouble('today_revenue', todayRevenue);
      await prefs.setDouble('occupancy', occupancy);
    } catch (e) {
      debugPrint("Error saving FieldPricingManager state: $e");
    }
  }

  void notify() {
    saveToPrefs();
    notifyListeners();
  }

  void blockSlot(String fieldName, dynamic dateVal, String time) {
    final String dateStr = dateVal is DateTime 
        ? dateVal.toLocal().toIso8601String().split('T')[0] 
        : dateVal.toString();
    final String key = '${fieldName.trim().toUpperCase()}_${dateStr.trim()}_$time';
    blockedSlots.add(key);
    debugPrint("FieldPricingManager: Blocking slot: $key. Total blocked slots: ${blockedSlots.toList()}");
    notify();
  }

  void unblockSlot(String fieldName, dynamic dateVal, String time) {
    final String dateStr = dateVal is DateTime 
        ? dateVal.toLocal().toIso8601String().split('T')[0] 
        : dateVal.toString();
    final String key = '${fieldName.trim().toUpperCase()}_${dateStr.trim()}_$time';
    blockedSlots.remove(key);
    debugPrint("FieldPricingManager: Unblocking slot: $key. Total blocked slots: ${blockedSlots.toList()}");
    notify();
  }

  bool isSlotBlocked(String fieldName, dynamic dateVal, String time) {
    final String dateStr = dateVal is DateTime 
        ? dateVal.toLocal().toIso8601String().split('T')[0] 
        : dateVal.toString();
    
    final String queryKey = '${fieldName.trim().toUpperCase()}_${dateStr.trim()}_$time';
    debugPrint("FieldPricingManager: Checking if slot is blocked. Query key: $queryKey. All blocked: ${blockedSlots.toList()}");

    // Check with the formatted dateStr (e.g. SAIRAN ARENA_2026-06-06_12:00 - 13:30)
    if (blockedSlots.contains(queryKey)) {
      debugPrint("FieldPricingManager: Slot IS blocked (found by standard key)!");
      return true;
    }
    
    // Fallback if dateVal is day int (for legacy keys if any, e.g. SAIRAN ARENA_6_12:00 - 13:30)
    if (dateVal is int) {
      final String fallbackKey1 = '${fieldName.trim().toUpperCase()}_${dateVal}_$time';
      if (blockedSlots.contains(fallbackKey1)) {
        debugPrint("FieldPricingManager: Slot IS blocked (found by fallback key 1: $fallbackKey1)!");
        return true;
      }
    } else {
      // If dateVal is a DateTime, we can also check the day number fallback for legacy keys
      if (dateVal is DateTime) {
        final String fallbackKey2 = '${fieldName.trim().toUpperCase()}_${dateVal.day}_$time';
        if (blockedSlots.contains(fallbackKey2)) {
          debugPrint("FieldPricingManager: Slot IS blocked (found by fallback key 2: $fallbackKey2)!");
          return true;
        }
      }
    }
    
    return false;
  }
}
