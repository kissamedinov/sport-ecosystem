import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/features/tournaments/presentation/screens/referee_search_screen.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';
import '../../../fields/data/field_pricing_manager.dart';
import '../../../fields/data/repositories/field_repository.dart';
import '../../../fields/data/models/field.dart';
import '../../../fields/data/models/booking.dart' as model_booking;
import '../../../../core/api/api_client.dart';

class OrganizerLogisticsScreen extends StatefulWidget {
  const OrganizerLogisticsScreen({super.key});

  @override
  State<OrganizerLogisticsScreen> createState() => _OrganizerLogisticsScreenState();
}

class _OrganizerLogisticsScreenState extends State<OrganizerLogisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  List<Field> _backendFields = [];
  final Map<String, List<model_booking.Booking>> _fieldBookingsMap = {};
  bool _isLoadingVenuesData = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadVenuesData();
  }

  Future<void> _loadVenuesData() async {
    try {
      final repo = FieldRepository(ApiClient());
      final fields = await repo.getFields();
      _backendFields = fields;
      
      for (final field in fields) {
        try {
          final bookings = await repo.getFieldBookings(field.id);
          _fieldBookingsMap[field.name.toUpperCase()] = bookings;
        } catch (e) {
          debugPrint("Error loading bookings for field ${field.name}: $e");
        }
      }
      
      if (mounted) {
        setState(() {
          _isLoadingVenuesData = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading fields: $e");
      if (mounted) {
        setState(() {
          _isLoadingVenuesData = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: PremiumTheme.surfaceBase(context),
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeaderBackground(),
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: innerBoxIsScrolled 
                  ? Text("booking.organizer_logistics".tr(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2))
                  : null,
              ),
            ),
            SliverToBoxAdapter(
              child: _buildLogisticsStats(),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                child: _buildTabBar(),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            const RefereeSearchScreen(),
            _buildVenuesTab(),
            _buildEquipmentTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBackground() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "organizer.hub".tr(),
              style: TextStyle(color: PremiumTheme.neonGreen, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Tournament\nLogistics Hub",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.1, letterSpacing: -0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildLogisticsStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Row(
        children: [
          _miniStat("12", "REFS", Icons.gavel_rounded, PremiumTheme.neonGreen, onTap: () => _tabController.animateTo(0)),
          const SizedBox(width: 12),
          _miniStat("4", "VENUES", Icons.stadium_rounded, PremiumTheme.electricBlue, onTap: () => _tabController.animateTo(1)),
          const SizedBox(width: 12),
          _miniStat("85%", "STAFF", Icons.verified_user_rounded, Colors.orangeAccent, onTap: () => _tabController.animateTo(2)),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label, IconData icon, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (onTap != null) onTap();
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 12),
              Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: color)),
              Text(label.toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2), letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: PremiumTheme.surfaceBase(context),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: PremiumTheme.neonGreen,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: PremiumTheme.neonGreen.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.black,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: "REFEREES"),
            Tab(text: "VENUES"),
            Tab(text: "GEAR"),
          ],
        ),
      ),
    );
  }

  final List<Map<String, dynamic>> _arenas = [
    {
      'name': 'SAIRAN ARENA',
      'type': 'Indoor & Outdoor / 6x6',
      'price': 15000,
      'surface': 'Artificial Turf',
      'hours': '18:00 - 22:00',
      'address': 'Turan Ave 48, Astana',
    },
    {
      'name': 'SPORT CITY PITCHES',
      'type': 'Indoor / 5x5',
      'price': 12000,
      'surface': 'Artificial Turf',
      'hours': '10:00 - 00:00',
      'address': 'Kabanbay Batyr Ave 47, Astana',
    },
    {
      'name': 'ASTANA ARENA',
      'type': 'Stadium & Training / 11x11',
      'price': 25000,
      'surface': 'Hybrid Pro',
      'hours': '08:00 - 23:00',
      'address': 'Kabanbay Batyr Ave 33, Astana',
    },
    {
      'name': 'DUMAN SPORT COMPLEX',
      'type': 'Covered Arena / 5x5',
      'price': 10000,
      'surface': 'Rubber Multi',
      'hours': '12:00 - 22:00',
      'address': 'Kurgalzhyn Highway 2, Astana',
    },
    {
      'name': 'QAZAQSTAN ATHLETIC COMPLEX',
      'type': 'Covered Pro / 7x7',
      'price': 20000,
      'surface': 'Natural Grass',
      'hours': '09:00 - 21:00',
      'address': 'Turan Ave 59, Astana',
    },
  ];

  Widget _buildVenuesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _arenas.length,
      itemBuilder: (context, index) {
        final arena = _arenas[index];
        return _buildVenueCard(arena);
      },
    );
  }

  Widget _buildVenueCard(Map<String, dynamic> arena) {
    final cs = Theme.of(context).colorScheme;
    final name = arena['name'] as String;
    final type = arena['type'] as String;
    final address = arena['address'] as String;
    final surface = arena['surface'] as String;
    final double price = (arena['price'] as num).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: PremiumTheme.glassDecorationOf(context, radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: PremiumTheme.electricBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.stadium_rounded, color: PremiumTheme.electricBlue, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type,
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              _buildTag(surface),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address,
                  style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BASE RATE',
                    style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${price.toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")} ₸ / 1.5h',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: PremiumTheme.neonGreen),
                  ),
                ],
              ),
              SizedBox(
                width: 140,
                child: PremiumButton(
                  text: 'INQUIRE / BOOK',
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _showTournamentInquirySheet(context, arena);
                  },
                  height: 38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55), letterSpacing: 0.5),
      ),
    );
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

  bool isTournamentBlockBlocked(String fieldName, DateTime date, String blockTime) {
    final manager = FieldPricingManager();

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

    // 1. Check local owner-blocked slots
    for (final config in slotsConfig) {
      final slotTime = config['time'] as String;
      if (_intervalsOverlap(blockTime, slotTime)) {
        final isBlockedByOwner = manager.isSlotBlocked(fieldName, date.toLocal(), slotTime);
        if (isBlockedByOwner) {
          return true;
        }
      }
    }

    // 2. Check local manual bookings
    for (final req in manager.pendingRequests) {
      final reqDateStr = req['dateStr'] ?? '';
      final isSameDate = reqDateStr.isNotEmpty 
          ? reqDateStr == date.toLocal().toIso8601String().split('T')[0]
          : req['day'] == date.toLocal().day;
      if (req['field'].toString().trim().toUpperCase() == fieldName.trim().toUpperCase() && 
          isSameDate && 
          req['status'] == 'APPROVED') {
        if (_intervalsOverlap(blockTime, req['time'] as String)) {
          return true;
        }
      }
    }

    // 3. Check real backend bookings from the database
    final backendBookings = _fieldBookingsMap[fieldName.toUpperCase()] ?? [];
    for (final booking in backendBookings) {
      if (booking.status.toUpperCase() == 'CANCELLED') continue;

      // Parse start and end times
      String startStr = booking.startTime;
      if (startStr.endsWith('Z')) startStr = startStr.substring(0, startStr.length - 1);
      if (startStr.contains('+')) startStr = startStr.split('+')[0];
      
      String endStr = booking.endTime;
      if (endStr.endsWith('Z')) endStr = endStr.substring(0, endStr.length - 1);
      if (endStr.contains('+')) endStr = endStr.split('+')[0];
      
      final bStart = DateTime.parse(startStr).toLocal();
      final bEnd = DateTime.parse(endStr).toLocal();

      // Check if the booking is on the same day as selected date
      if (DateUtils.isSameDay(bStart, date.toLocal())) {
        // Format booking times as range "HH:mm - HH:mm"
        final String bookingTimeRange = "${bStart.hour.toString().padLeft(2, '0')}:${bStart.minute.toString().padLeft(2, '0')} - ${bEnd.hour.toString().padLeft(2, '0')}:${bEnd.minute.toString().padLeft(2, '0')}";
        if (_intervalsOverlap(blockTime, bookingTimeRange)) {
          return true;
        }
      }
    }

    // 4. Fallback/legacy mock bookings for demo purposes
    for (final config in slotsConfig) {
      final slotTime = config['time'] as String;
      final hour = config['hour'] as int;

      if (_intervalsOverlap(blockTime, slotTime)) {
        final isBooked = (hour == 18 && date.day % 2 == 0) || 
                         (hour == 20 && date.day % 3 != 0) || 
                         (hour == 12 && date.day % 4 == 0);
        if (isBooked) {
          return true;
        }
      }
    }

    return false;
  }

  String _getDayName(int day) {
    return ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][day - 1];
  }

  void _showTournamentInquirySheet(BuildContext context, Map<String, dynamic> arena) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String name = arena['name'] as String;
    final double basePrice = (arena['price'] as num).toDouble();

    int selectedPackageIndex = 0; // 0 = 3h, 1 = 6h
    int selectedDateIndex = 0;
    String? selectedBlockTime;

    final DateTime today = DateTime.now();
    final dates = List.generate(7, (idx) => today.add(Duration(days: idx)));

    final threeHourBlocks = [
      "09:00 - 12:00",
      "12:00 - 15:00",
      "15:00 - 18:00",
      "18:00 - 21:00",
      "21:00 - 00:00"
    ];

    final sixHourBlocks = [
      "09:00 - 15:00",
      "15:00 - 21:00",
      "18:00 - 00:00"
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final blocks = selectedPackageIndex == 0 ? threeHourBlocks : sixHourBlocks;
            final discount = selectedPackageIndex == 0 ? 0.10 : 0.20;
            final hoursMultiplier = selectedPackageIndex == 0 ? 2 : 4;
            final double originalPrice = basePrice * hoursMultiplier;
            final double finalPrice = (originalPrice * (1.0 - discount) / 100).round() * 100.0;

            final DateTime currentDate = dates[selectedDateIndex];

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A0E12) : const Color(0xFFF5F5F5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.2),
                              ),
                              Text(
                                'TOURNAMENT BOOKING PACKAGE',
                                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      children: [
                        const Text(
                          '1. SELECT PACKAGE',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPackageChip(
                                title: '3 Hours Block',
                                subtitle: '10% Discount',
                                isSelected: selectedPackageIndex == 0,
                                onTap: () {
                                  setModalState(() {
                                    selectedPackageIndex = 0;
                                    selectedBlockTime = null;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildPackageChip(
                                title: '6 Hours Block',
                                subtitle: '20% Discount',
                                isSelected: selectedPackageIndex == 1,
                                onTap: () {
                                  setModalState(() {
                                    selectedPackageIndex = 1;
                                    selectedBlockTime = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          '2. CHOOSE DATE',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 64,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 7,
                            itemBuilder: (context, idx) {
                              final d = dates[idx];
                              final isSel = idx == selectedDateIndex;
                              final dayName = _getDayName(d.weekday);
                              
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: InkWell(
                                  onTap: () {
                                    setModalState(() {
                                      selectedDateIndex = idx;
                                      selectedBlockTime = null;
                                    });
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
                        const SizedBox(height: 24),

                        const Text(
                          '3. AVAILABLE TIME BLOCKS',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 2.2,
                          ),
                          itemCount: blocks.length,
                          itemBuilder: (context, idx) {
                            final blockTime = blocks[idx];
                            final isBlocked = isTournamentBlockBlocked(name, currentDate, blockTime);
                            final isSel = selectedBlockTime == blockTime;

                            Color itemBgColor = isDark ? const Color(0xFF161B22) : Colors.white;
                            Color itemBorderColor = cs.onSurface.withValues(alpha: 0.06);
                            Color textColor = cs.onSurface;
                            Color subtitleColor = cs.onSurfaceVariant;

                            if (isBlocked) {
                              itemBgColor = isDark ? const Color(0xFF1F1215) : const Color(0xFFFEEBED);
                              itemBorderColor = Colors.redAccent.withValues(alpha: 0.15);
                              textColor = Colors.redAccent.withValues(alpha: 0.5);
                              subtitleColor = Colors.redAccent.withValues(alpha: 0.4);
                            } else if (isSel) {
                              itemBgColor = PremiumTheme.electricBlue.withValues(alpha: 0.15);
                              itemBorderColor = PremiumTheme.electricBlue;
                              textColor = PremiumTheme.electricBlue;
                              subtitleColor = PremiumTheme.electricBlue;
                            }

                            return InkWell(
                              onTap: isBlocked 
                                  ? null 
                                  : () {
                                      setModalState(() {
                                        selectedBlockTime = blockTime;
                                      });
                                    },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: itemBgColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: itemBorderColor, width: 1.5),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      blockTime,
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isBlocked ? 'Unavailable' : 'Available',
                                      style: TextStyle(
                                        color: subtitleColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 28),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF161B22) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PRICE BREAKDOWN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Regular Rent (${selectedPackageIndex == 0 ? "3 Hours" : "6 Hours"})', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                                  Text(
                                    '${originalPrice.toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")} ₸',
                                    style: TextStyle(color: cs.onSurface, fontSize: 12, fontWeight: FontWeight.w600, decoration: TextDecoration.lineThrough),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Package Discount (${(discount * 100).toInt()}% OFF)', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                                  Text(
                                    '-${(originalPrice * discount).toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")} ₸',
                                    style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const Divider(height: 20, color: Colors.white10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('ESTIMATED PRICE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(
                                    '${finalPrice.toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")} ₸',
                                    style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.w900, fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        PremiumButton(
                          text: 'SUBMIT INQUIRY',
                          color: selectedBlockTime == null ? Colors.grey.withValues(alpha: 0.3) : null,
                          onPressed: selectedBlockTime == null 
                              ? () {} 
                              : () {
                                  final manager = FieldPricingManager();
                                  manager.pendingRequests.add({
                                    'id': 'req-org-${DateTime.now().millisecondsSinceEpoch}',
                                    'clientName': 'Tournament Organizer',
                                    'field': name,
                                    'date': '${_getDayName(currentDate.weekday)}, ${currentDate.day} June',
                                    'day': currentDate.day,
                                    'time': selectedBlockTime,
                                    'price': finalPrice,
                                    'status': 'PENDING',
                                  });
                                  manager.notify();

                                  Navigator.pop(context);
                                  
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      title: const Text('Inquiry Submitted', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      content: const Text('Your tournament block booking request has been sent to the field owner. You can track its status in your dashboard requests.', style: TextStyle(fontSize: 13)),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('OK', style: TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPackageChip({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? PremiumTheme.neonGreen : (isDark ? const Color(0xFF161B22) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? PremiumTheme.neonGreen : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.black : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected ? Colors.black.withValues(alpha: 0.7) : Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_rounded, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06), size: 80),
          const SizedBox(height: 20),
          Text("GEAR MANAGEMENT", style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08), letterSpacing: 2)),
          Text('common.coming_soon_content'.tr(namedArgs: {'title': 'GEAR'}), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06), fontSize: 12)),
        ],
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _StickyTabBarDelegate({required this.child});

  @override
  double get minExtent => 64;
  @override
  double get maxExtent => 64;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) => false;
}
