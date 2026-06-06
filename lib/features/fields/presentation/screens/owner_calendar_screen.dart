import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import '../../data/field_pricing_manager.dart';
import '../../../../core/api/api_client.dart';
import '../../data/models/field.dart' as model_field;
import '../../data/models/booking.dart' as model_booking;
import '../../data/repositories/field_repository.dart';

class OwnerCalendarScreen extends StatefulWidget {
  const OwnerCalendarScreen({super.key});

  @override
  State<OwnerCalendarScreen> createState() => _OwnerCalendarScreenState();
}

class _OwnerCalendarScreenState extends State<OwnerCalendarScreen> {
  String selectedField = 'SAIRAN ARENA';
  int selectedDateIndex = 0;

  List<model_field.Field> _backendFields = [];
  model_field.Field? _selectedBackendField;
  List<model_booking.Booking> _backendBookings = [];
  bool _isLoadingFields = true;
  bool _isLoadingBookings = false;

  late final VoidCallback _managerListener;

  @override
  void initState() {
    super.initState();
    _managerListener = () {
      if (mounted) {
        setState(() {});
      }
    };
    FieldPricingManager().addListener(_managerListener);
    _loadBackendFields();
  }

  @override
  void dispose() {
    FieldPricingManager().removeListener(_managerListener);
    super.dispose();
  }

  Future<void> _loadBackendFields() async {
    try {
      final repo = FieldRepository(ApiClient());
      final fields = await repo.getFields();
      if (mounted) {
        setState(() {
          _backendFields = fields;
          if (_backendFields.isNotEmpty) {
            final match = _backendFields.firstWhere(
              (f) => f.name.toUpperCase() == selectedField.toUpperCase(),
              orElse: () => _backendFields.first,
            );
            _selectedBackendField = match;
            selectedField = match.name.toUpperCase();
          }
          _isLoadingFields = false;
        });
        if (_selectedBackendField != null) {
          _loadBackendBookings();
        }
      }
    } catch (e) {
      print("Error loading backend fields: $e");
      if (mounted) {
        setState(() {
          _isLoadingFields = false;
        });
      }
    }
  }

  Future<void> _loadBackendBookings() async {
    if (_selectedBackendField == null) return;
    setState(() {
      _isLoadingBookings = true;
    });
    try {
      final repo = FieldRepository(ApiClient());
      final bookings = await repo.getFieldBookings(_selectedBackendField!.id);
      if (mounted) {
        setState(() {
          _backendBookings = bookings;
          _isLoadingBookings = false;
        });
      }
    } catch (e) {
      print("Error loading backend bookings: $e");
      if (mounted) {
        setState(() {
          _isLoadingBookings = false;
        });
      }
    }
  }

  int _parseTimeToMinutes(String timeStr) {
    final cleanStr = timeStr.trim();
    final parts = cleanStr.split(':');
    if (parts.length < 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }

  bool _intervalsOverlap(String range1, String range2) {
    final p1 = range1.split('-');
    final p2 = range2.split('-');
    if (p1.length < 2 || p2.length < 2) return false;

    final start1 = _parseTimeToMinutes(p1[0]);
    final end1 = _parseTimeToMinutes(p1[1]);

    final start2 = _parseTimeToMinutes(p2[0]);
    final end2 = _parseTimeToMinutes(p2[1]);

    int actualEnd1 = end1;
    if (actualEnd1 <= start1) actualEnd1 += 24 * 60;

    int actualEnd2 = end2;
    if (actualEnd2 <= start2) actualEnd2 += 24 * 60;

    return start1 < actualEnd2 && start2 < actualEnd1;
  }

  String _getDayName(int day) {
    return ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][day - 1];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final manager = FieldPricingManager();

    final DateTime today = DateTime.now();
    final dates = List.generate(7, (idx) => today.add(Duration(days: idx)));
    final DateTime currentDate = dates[selectedDateIndex];

    final slotsConfig = [
      {'time': '08:00 - 09:30', 'hour': 8},
      {'time': '10:00 - 11:30', 'hour': 10},
      {'time': '12:00 - 13:30', 'hour': 12},
      {'time': '14:00 - 15:30', 'hour': 14},
      {'time': '16:00 - 17:30', 'hour': 16},
      {'time': '18:00 - 19:30', 'hour': 18},
      {'time': '20:00 - 21:30', 'hour': 20},
      {'time': '22:00 - 23:30', 'hour': 22},
      {'time': '00:00 - 01:30', 'hour': 0},
    ];

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        title: Text('field.reservations_calendar'.tr().toUpperCase(), style: const TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold, fontSize: 13)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoadingFields
          ? const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen))
          : Column(
              children: [
                // Arena Selection Dropdown
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF161B22) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedField,
                        isExpanded: true,
                        dropdownColor: isDark ? const Color(0xFF161B22) : Colors.white,
                        style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface, fontSize: 14),
                        items: _backendFields.map((f) => DropdownMenuItem(value: f.name.toUpperCase(), child: Text(f.name.toUpperCase()))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              selectedField = val;
                              _selectedBackendField = _backendFields.firstWhere((f) => f.name.toUpperCase() == val.toUpperCase());
                            });
                            _loadBackendBookings();
                          }
                        },
                      ),
                    ),
                  ),
                ),

                // Date selection horizontal slider
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: SizedBox(
                    height: 64,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: 7,
                      itemBuilder: (context, idx) {
                        final d = dates[idx];
                        final isSel = idx == selectedDateIndex;
                        final dayName = _getDayName(d.weekday);
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selectedDateIndex = idx;
                              });
                              _loadBackendBookings();
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 56,
                              decoration: BoxDecoration(
                                color: isSel ? PremiumTheme.neonGreen : (isDark ? const Color(0xFF161B22) : Colors.white),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSel ? PremiumTheme.neonGreen : cs.onSurface.withValues(alpha: 0.06),
                                ),
                              ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dayName,
                              style: TextStyle(
                                color: isSel ? Colors.black : cs.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              d.day.toString(),
                              style: TextStyle(
                                color: isSel ? Colors.black : cs.onSurface,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const Divider(height: 24, color: Colors.white10),

          // Schedule List
          Expanded(
            child: _isLoadingBookings
                ? const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: slotsConfig.length,
                    itemBuilder: (context, index) {
                final config = slotsConfig[index];
                final slotTime = config['time'] as String;
                final hour = config['hour'] as int;

                final isBlockedByOwner = manager.isSlotBlocked(selectedField, currentDate, slotTime);

                // Calculate local start and end DateTime for the slot
                final DateTime slotStart = hour == 0
                    ? DateTime(currentDate.year, currentDate.month, currentDate.day + 1, 0, 0)
                    : DateTime(currentDate.year, currentDate.month, currentDate.day, hour, 0);
                final DateTime slotEnd = slotStart.add(const Duration(minutes: 90));

                // Find if there is a real DB booking that overlaps with this slot
                model_booking.Booking? dbBooking;
                for (final booking in _backendBookings) {
                  if (booking.status.toUpperCase() == 'CANCELLED') continue;
                  
                  // Parse date string as naive local time by stripping 'Z' or offset
                  String startStr = booking.startTime;
                  if (startStr.endsWith('Z')) startStr = startStr.substring(0, startStr.length - 1);
                  if (startStr.contains('+')) startStr = startStr.split('+')[0];
                  
                  String endStr = booking.endTime;
                  if (endStr.endsWith('Z')) endStr = endStr.substring(0, endStr.length - 1);
                  if (endStr.contains('+')) endStr = endStr.split('+')[0];
                  
                  final bStart = DateTime.parse(startStr);
                  final bEnd = DateTime.parse(endStr);
                  
                  // Overlap condition: slotStart < bEnd && bStart < slotEnd
                  if (slotStart.isBefore(bEnd) && bStart.isBefore(slotEnd)) {
                    dbBooking = booking;
                    break;
                  }
                }

                // Determine if there is an approved overlapping request (local manual bookings)
                Map<String, dynamic>? overlappingBooking;
                for (final req in manager.pendingRequests) {
                  final reqDateStr = req['dateStr'] ?? '';
                  final isSameDate = reqDateStr.isNotEmpty 
                      ? reqDateStr == currentDate.toIso8601String().split('T')[0]
                      : req['day'] == currentDate.day;
                  if (req['field'].toString().trim().toUpperCase() == selectedField.trim().toUpperCase() && 
                      isSameDate && 
                      req['status'] == 'APPROVED') {
                    if (_intervalsOverlap(slotTime, req['time'] as String)) {
                      overlappingBooking = req;
                      break;
                    }
                  }
                }

                String statusLabel = 'field.available'.tr();
                Color statusColor = PremiumTheme.neonGreen;
                String subtitle = 'field.open_for_reservation'.tr();

                if (isBlockedByOwner) {
                  statusLabel = 'field.blocked'.tr();
                  statusColor = Colors.redAccent;
                  subtitle = 'field.maintenance_unavailable'.tr();
                } else if (dbBooking != null) {
                  statusLabel = 'field.booked'.tr();
                  statusColor = PremiumTheme.electricBlue;
                  subtitle = dbBooking.status.toUpperCase() == 'PENDING' 
                      ? '${dbBooking.userName ?? 'Player'} (Pending)' 
                      : (dbBooking.userName ?? 'Player');
                } else if (overlappingBooking != null) {
                  statusLabel = 'field.booked'.tr();
                  statusColor = PremiumTheme.electricBlue;
                  subtitle = '${overlappingBooking['clientName']} (Walk-in)';
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161B22) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    children: [
                      // Time Indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: cs.onSurface.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: Colors.grey),
                            const SizedBox(height: 4),
                            Text(
                              slotTime.split(' - ')[0],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Booking Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  statusLabel.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                    color: statusColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: cs.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              slotTime,
                              style: TextStyle(
                                fontSize: 10,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Quick actions
                       if (isBlockedByOwner) ...[
                        IconButton(
                          icon: const Icon(Icons.lock_open, color: Colors.green),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            manager.unblockSlot(selectedField, currentDate, slotTime);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Slot $slotTime unblocked!')),
                            );
                          },
                        ),
                      ] else if (overlappingBooking != null || dbBooking != null) ...[
                        const Icon(Icons.check_circle_outline, color: Colors.grey),
                      ] else ...[
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.block, color: Colors.redAccent, size: 20),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                manager.blockSlot(selectedField, currentDate, slotTime);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Slot $slotTime blocked by owner!')),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_task_rounded, color: PremiumTheme.neonGreen, size: 20),
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                _showManualBookingDialog(context, slotTime, currentDate);
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showManualBookingDialog(BuildContext context, String slotTime, DateTime currentDate) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '15000');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'MANUAL WALK-IN BOOKING',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: cs.onSurface, letterSpacing: 0.5),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Create a manual reservation for $selectedField on ${_getDayName(currentDate.weekday)}, ${currentDate.day} June @ $slotTime.',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Customer Name'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: 'Price (₸)'),
                keyboardType: TextInputType.number,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: PremiumTheme.neonGreen),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              
              final priceVal = double.tryParse(priceCtrl.text) ?? 15000.0;
              final manager = FieldPricingManager();

              manager.pendingRequests.add({
                'id': 'manual-${DateTime.now().millisecondsSinceEpoch}',
                'clientName': name,
                'field': selectedField,
                'date': '${_getDayName(currentDate.weekday)}, ${currentDate.day} June',
                'day': currentDate.day,
                'dateStr': currentDate.toIso8601String().split('T')[0],
                'time': slotTime,
                'price': priceVal,
                'status': 'APPROVED',
              });

              manager.todayRevenue += priceVal;
              manager.occupancy = (manager.occupancy + 0.05).clamp(0.0, 1.0);
              manager.notify();

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.green,
                  content: Text('Manual booking for $name registered successfully!'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PremiumTheme.neonGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('CONFIRM', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
