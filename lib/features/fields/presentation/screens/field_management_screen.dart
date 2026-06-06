import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../data/field_pricing_manager.dart';

class FieldManagementScreen extends StatefulWidget {
  const FieldManagementScreen({super.key});

  @override
  State<FieldManagementScreen> createState() => _FieldManagementScreenState();
}

class _FieldManagementScreenState extends State<FieldManagementScreen> {
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
  }

  @override
  void dispose() {
    FieldPricingManager().removeListener(_managerListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        title: Text('field.field_management'.tr(), style: const TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold, fontSize: 14)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatGrid(),
            const SizedBox(height: 32),
            _buildSectionTitle('field.operations'.tr()),
            const SizedBox(height: 12),
            _buildActionCard(
              context,
              'field.booking_requests'.tr(),
              'field.booking_requests_desc'.tr(),
              Icons.book_online,
              PremiumTheme.neonGreen,
              () => _showBookingRequestsSheet(context),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              'field.batch_slot_generation'.tr(),
              'field.batch_slot_desc'.tr(),
              Icons.auto_awesome,
              PremiumTheme.electricBlue,
              () => _showGenerateSlotsDialog(context),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              'field.manual_availability'.tr(),
              'field.manual_availability_desc'.tr(),
              Icons.timer_outlined,
              Colors.orange,
              () => _showManualAvailabilitySheet(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
    );
  }

  Widget _buildStatGrid() {
    final manager = FieldPricingManager();
    final rawRevenue = manager.todayRevenue.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},'
    );
    final revenueFormatted = '$rawRevenue ₸';
    final occupancyFormatted = '${(manager.occupancy * 100).toInt()}%';

    return Row(
      children: [
        Expanded(child: _buildStatCard('field.today_revenue'.tr(), revenueFormatted, Icons.payments_rounded, Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('field.occupancy'.tr(), occupancyFormatted, Icons.bar_chart_rounded, PremiumTheme.electricBlue)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.28),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: onSurface, letterSpacing: -0.5),
          ),
          const SizedBox(height: 3),
          Text(
            title.toUpperCase(),
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: onSurface.withValues(alpha: 0.4), letterSpacing: 0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B22) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: onSurface.withValues(alpha: 0.07)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.09),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [color, color.withValues(alpha: 0.2)],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: onSurface, fontSize: 15)),
                              const SizedBox(height: 3),
                              Text(subtitle, style: TextStyle(color: onSurface.withValues(alpha: 0.4), fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: onSurface.withValues(alpha: 0.2)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBookingRequestsSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final manager = FieldPricingManager();
            final requests = manager.pendingRequests;

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
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
                        const Text(
                          'BOOKING REQUESTS',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: requests.isEmpty
                        ? Center(
                            child: Text(
                              'No booking requests found.',
                              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            itemCount: requests.length,
                            itemBuilder: (context, index) {
                              final req = requests[index];
                              final String clientName = req['clientName'];
                              final String field = req['field'];
                              final String date = req['date'];
                              final String time = req['time'];
                              final double price = req['price'];
                              final String status = req['status'];

                              Color statusColor = Colors.grey;
                              if (status == 'APPROVED') statusColor = PremiumTheme.neonGreen;
                              if (status == 'REJECTED') statusColor = Colors.redAccent;
                              if (status == 'PENDING') statusColor = Colors.orangeAccent;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF161B22) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: PremiumTheme.electricBlue.withValues(alpha: 0.15),
                                              child: Text(
                                                clientName.substring(0, 1),
                                                style: const TextStyle(color: PremiumTheme.electricBlue, fontWeight: FontWeight.bold, fontSize: 12),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                Text(field, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10)),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                                          ),
                                          child: Text(
                                            status,
                                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 9, letterSpacing: 0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24, color: Colors.white10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('DATE & TIME', style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 2),
                                            Text('$date, $time', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text('REVENUE', style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ₸',
                                              style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.w900, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (status == 'PENDING') ...[
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () {
                                                setModalState(() {
                                                  req['status'] = 'REJECTED';
                                                });
                                                manager.notify();
                                              },
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.redAccent,
                                                side: const BorderSide(color: Colors.redAccent, width: 1),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                              child: const Text('REJECT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () {
                                                setModalState(() {
                                                  req['status'] = 'APPROVED';
                                                });
                                                manager.todayRevenue += price;
                                                manager.occupancy = (manager.occupancy + 0.05).clamp(0.0, 1.0);
                                                manager.notify();
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: PremiumTheme.neonGreen,
                                                foregroundColor: Colors.black,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                              child: const Text('APPROVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
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
          },
        );
      },
    );
  }

  void _showManualAvailabilitySheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int selectedDateIndex = 0;
    String selectedField = 'SAIRAN ARENA';

    final slotsConfig = [
      '08:00 - 09:30',
      '10:00 - 11:30',
      '12:00 - 13:30',
      '14:00 - 15:30',
      '16:00 - 17:30',
      '18:00 - 19:30',
      '20:00 - 21:30',
      '22:00 - 23:30',
      '00:00 - 01:30',
    ];

    final List<String> fields = [
      'SAIRAN ARENA',
      'SPORT CITY PITCHES',
      'ASTANA ARENA',
      'DUMAN SPORT COMPLEX',
      'QAZAQSTAN ATHLETIC COMPLEX',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final manager = FieldPricingManager();
            
            final primePct = ((manager.primeTimeMultiplier - 1.0) * 100).round();
            final weekendPct = ((manager.weekendMultiplier - 1.0) * 100).round();
            final nightPct = ((1.0 - manager.nightOwlMultiplier) * 100).round();

            final selectedDate = DateTime.now().add(Duration(days: selectedDateIndex));

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
                        const Text(
                          'AVAILABILITY & PRICING',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        const Text(
                          'DYNAMIC PRICING ADJUSTMENTS',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0),
                        ),
                        const SizedBox(height: 12),
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Prime-Time Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(
                                    '+$primePct%',
                                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w900, fontSize: 13),
                                  ),
                                ],
                              ),
                              Slider(
                                value: manager.primeTimeMultiplier,
                                min: 1.0,
                                max: 1.5,
                                divisions: 10,
                                activeColor: Colors.orange,
                                inactiveColor: Colors.orange.withValues(alpha: 0.2),
                                onChanged: (val) {
                                  setModalState(() {
                                    manager.primeTimeMultiplier = val;
                                  });
                                  manager.notify();
                                },
                              ),
                              const SizedBox(height: 10),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Weekend Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(
                                    '+$weekendPct%',
                                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w900, fontSize: 13),
                                  ),
                                ],
                              ),
                              Slider(
                                value: manager.weekendMultiplier,
                                min: 1.0,
                                max: 1.6,
                                divisions: 12,
                                activeColor: Colors.blue,
                                inactiveColor: Colors.blue.withValues(alpha: 0.2),
                                onChanged: (val) {
                                  setModalState(() {
                                    manager.weekendMultiplier = val;
                                  });
                                  manager.notify();
                                },
                              ),
                              const SizedBox(height: 10),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Night-Owl Discount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(
                                    '-$nightPct%',
                                    style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.w900, fontSize: 13),
                                  ),
                                ],
                              ),
                              Slider(
                                value: manager.nightOwlMultiplier,
                                min: 0.5,
                                max: 1.0,
                                divisions: 10,
                                activeColor: Colors.purpleAccent,
                                inactiveColor: Colors.purpleAccent.withValues(alpha: 0.2),
                                onChanged: (val) {
                                  setModalState(() {
                                    manager.nightOwlMultiplier = val;
                                  });
                                  manager.notify();
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          'SELECT FIELD',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                              items: fields.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() {
                                    selectedField = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'SELECT DATE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 60,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 7,
                            itemBuilder: (context, index) {
                              final date = DateTime.now().add(Duration(days: index));
                              final isSelected = selectedDateIndex == index;
                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    selectedDateIndex = index;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 55,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    gradient: isSelected ? PremiumTheme.primaryGradient : null,
                                    color: isSelected ? null : cs.onSurface.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? Colors.transparent : cs.onSurface.withValues(alpha: 0.05),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][date.weekday - 1],
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.black : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${date.day}',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: isSelected ? Colors.black : cs.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'TIME SLOTS (TAP TO TOGGLE BLOCKED STATUS)',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0),
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.35,
                          ),
                          itemCount: slotsConfig.length,
                          itemBuilder: (context, index) {
                            final time = slotsConfig[index];
                            final isBlocked = manager.isSlotBlocked(selectedField, selectedDate, time);

                            Color cardColor = Colors.transparent;
                            Color borderColor = cs.onSurface.withValues(alpha: 0.08);
                            Color textColor = cs.onSurface;
                            IconData statusIcon = Icons.check_circle_outline_rounded;
                            Color statusColor = Colors.green;

                            if (isBlocked) {
                              cardColor = Colors.red.withValues(alpha: 0.1);
                              borderColor = Colors.redAccent.withValues(alpha: 0.5);
                              textColor = Colors.redAccent;
                              statusIcon = Icons.block_rounded;
                              statusColor = Colors.redAccent;
                            } else {
                              cardColor = Colors.green.withValues(alpha: 0.05);
                              borderColor = Colors.green.withValues(alpha: 0.3);
                              textColor = cs.onSurface;
                              statusIcon = Icons.check_circle_rounded;
                              statusColor = Colors.green;
                            }

                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  if (isBlocked) {
                                    manager.unblockSlot(selectedField, selectedDate, time);
                                  } else {
                                    manager.blockSlot(selectedField, selectedDate, time);
                                  }
                                });
                                manager.notify();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: borderColor,
                                    width: 1.5,
                                  ),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      time.split(' - ')[0],
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: textColor,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    Text(
                                      '- ${time.split(' - ')[1]}',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: textColor.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(statusIcon, size: 10, color: statusColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          isBlocked ? 'BLOCKED' : 'OPEN',
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w900,
                                            color: statusColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 30),
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

  void _showGenerateSlotsDialog(BuildContext context) {
    final priceController = TextEditingController(text: '15000');
    final startHourController = TextEditingController(text: '9');
    final endHourController = TextEditingController(text: '22');
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PremiumTheme.surfaceBase(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), 
          side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
        ),
        title: Text('field.batch_slot_generation'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Setup your field availability for a full day.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12)),
            const SizedBox(height: 20),
            TextField(
              controller: startHourController,
              decoration: InputDecoration(labelText: 'Start Hour (0-23)', labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: endHourController,
              decoration: InputDecoration(labelText: 'End Hour (1-24)', labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: priceController,
              decoration: InputDecoration(labelText: 'Price per slot (₸)', labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('common.cancel'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)))),
          ElevatedButton(
            onPressed: () async {
              final provider = context.read<BookingProvider>();
              const dummyFieldId = '00000000-0000-0000-0000-000000000000'; 
              
              final success = await provider.generateFieldSlots(dummyFieldId, {
                'date': selectedDate.toIso8601String(),
                'start_hour': int.parse(startHourController.text),
                'end_hour': int.parse(endHourController.text),
                'price': double.parse(priceController.text),
                'slot_duration_minutes': 60,
              });

              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('field.booking_confirmed'.tr())));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: PremiumTheme.neonGreen, foregroundColor: Colors.black),
            child: Text('field.batch_slot_generation'.tr()),
          ),
        ],
      ),
    );
  }
}
