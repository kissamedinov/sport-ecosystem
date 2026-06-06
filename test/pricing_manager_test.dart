import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/features/fields/data/field_pricing_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FieldPricingManager Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('should save and load blocked slots', () async {
      final manager = FieldPricingManager();
      
      // Clean up from any previous test
      manager.blockedSlots.clear();
      manager.pendingRequests.clear();

      // Setup initial data (legacy int day)
      manager.blockSlot('SAIRAN ARENA', 6, '12:00 - 13:30');
      expect(manager.isSlotBlocked('SAIRAN ARENA', 6, '12:00 - 13:30'), isTrue);
      // Verify legacy day number checks fallback when checking with a DateTime
      expect(manager.isSlotBlocked('SAIRAN ARENA', DateTime(2026, 6, 6), '12:00 - 13:30'), isTrue);

      // Setup initial data (DateTime)
      final DateTime testDate = DateTime(2026, 6, 8);
      manager.blockSlot('SAIRAN ARENA', testDate, '14:00 - 15:30');
      expect(manager.isSlotBlocked('SAIRAN ARENA', testDate, '14:00 - 15:30'), isTrue);

      // Explicitly await saving to prefs
      await manager.saveToPrefs();

      // Re-initialize manager (simulate app restart)
      final newManager = FieldPricingManager();
      await newManager.init();

      expect(newManager.isSlotBlocked('SAIRAN ARENA', 6, '12:00 - 13:30'), isTrue);
      expect(newManager.isSlotBlocked('SAIRAN ARENA', testDate, '14:00 - 15:30'), isTrue);
    });

    test('should save and load manual bookings', () async {
      final manager = FieldPricingManager();
      manager.pendingRequests.clear();

      final booking = {
        'id': 'manual-12345',
        'clientName': 'Test Client',
        'field': 'SAIRAN ARENA',
        'date': 'SAT, 6 June',
        'day': 6,
        'time': '12:00 - 13:30',
        'price': 15000.0,
        'status': 'APPROVED',
      };

      manager.pendingRequests.add(booking);
      
      // Explicitly await saving to prefs
      await manager.saveToPrefs();

      // Re-initialize manager (simulate app restart)
      final newManager = FieldPricingManager();
      await newManager.init();

      expect(newManager.pendingRequests.length, 1);
      expect(newManager.pendingRequests.first['clientName'], 'Test Client');
    });
  });
}
