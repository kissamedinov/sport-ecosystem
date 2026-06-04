import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/presentation/screens/notification_screen.dart';
import '../../../core/theme/premium_theme.dart';
import '../../../core/presentation/widgets/premium_widgets.dart';
import '../../fields/data/field_pricing_manager.dart';

class FieldOwnerDashboard extends StatefulWidget {
  const FieldOwnerDashboard({super.key});

  @override
  State<FieldOwnerDashboard> createState() => _FieldOwnerDashboardState();
}

class _FieldOwnerDashboardState extends State<FieldOwnerDashboard> {
  late final VoidCallback _managerListener;

  @override
  void initState() {
    super.initState();
    final provider = context.read<NotificationProvider>();
    Future.microtask(() => provider.fetchNotifications());
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
    final user = context.watch<AuthProvider>().user;
    final manager = FieldPricingManager();
    final pendingCount = manager.pendingRequests.where((r) => r['status'] == 'PENDING').length;

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        title: Text(
          'field.partner_hub'.tr().toUpperCase(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          _buildNotificationIcon(),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(user),
            const SizedBox(height: 24),
            _buildStatGrid(manager),
            const SizedBox(height: 32),
            _buildSectionLabel('field.operations'.tr().toUpperCase()),
            const SizedBox(height: 12),
            _buildActionCard(
              context,
              'field.booking_requests'.tr(),
              '$pendingCount ${'field.new_requests_waiting'.tr()}',
              Icons.book_online_rounded,
              PremiumTheme.neonGreen,
              () => _showBookingRequestsSheet(context),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              'profile.my_fields'.tr(),
              'field.manage_availability_pricing'.tr(),
              Icons.stadium_rounded,
              PremiumTheme.electricBlue,
              () => _showManualAvailabilitySheet(context),
            ),
            const SizedBox(height: 32),
            _buildSectionLabel('field.management_tools'.tr().toUpperCase()),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: [
                _buildGridActionTile(
                  'field.earnings'.tr(),
                  Icons.analytics_rounded,
                  Colors.orangeAccent,
                  () => _showEarningsSheet(context),
                ),
                _buildGridActionTile(
                  'field.promotions'.tr(),
                  Icons.local_offer_rounded,
                  Colors.purpleAccent,
                  () => _showPromotionsSheet(context),
                ),
              ],
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, size: 26),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
            ),
            if (provider.unreadCount > 0)
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(user) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'field.welcome_partner'.tr(namedArgs: {'name': user?.name ?? 'field.partner'.tr()}),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'field.field_owner_role'.tr().toUpperCase(),
                      style: const TextStyle(color: PremiumTheme.neonGreen, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.person_rounded, color: PremiumTheme.neonGreen),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Container(width: 4, height: 14, decoration: BoxDecoration(color: PremiumTheme.neonGreen, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
      ],
    );
  }

  Widget _buildStatGrid(FieldPricingManager manager) {
    final rawRevenue = manager.todayRevenue.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},'
    );
    final revenueFormatted = '$rawRevenue ₸';
    final occupancyFormatted = '${(manager.occupancy * 100).toInt()}%';

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2,
      children: [
        _buildStatItem('field.today_revenue'.tr(), revenueFormatted, Colors.green),
        _buildStatItem('field.occupancy'.tr(), occupancyFormatted, Colors.blue),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12)),
        trailing: Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildGridActionTile(String label, IconData icon, Color color, VoidCallback onTap) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: onSurface.withValues(alpha: 0.06)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label.toUpperCase(),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0),
              ),
            ],
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
            return AnimatedBuilder(
              animation: FieldPricingManager(),
              builder: (context, _) {
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
            return AnimatedBuilder(
              animation: FieldPricingManager(),
              builder: (context, _) {
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
                                final isBlocked = manager.isSlotBlocked(selectedField, selectedDate.day, time);

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
                                        manager.unblockSlot(selectedField, selectedDate.day, time);
                                      } else {
                                        manager.blockSlot(selectedField, selectedDate.day, time);
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
      },
    );
  }

  void _showEarningsSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AnimatedBuilder(
              animation: FieldPricingManager(),
              builder: (context, _) {
                final manager = FieldPricingManager();
                final approvedBookings = manager.pendingRequests
                    .where((r) => r['status'] == 'APPROVED')
                    .toList();

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
                              'EARNINGS & ANALYTICS',
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
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: PremiumTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: PremiumTheme.neonShadow(color: PremiumTheme.neonGreen, opacity: 0.2),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'TOTAL BUSINESS REVENUE',
                                    style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${manager.todayRevenue.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ₸',
                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 32, letterSpacing: -1),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.show_chart_rounded, color: Colors.black87, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Live occupancy at ${(manager.occupancy * 100).toInt()}%',
                                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            const Text(
                              'COMPLETED BOOKINGS REVENUE',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0),
                            ),
                            const SizedBox(height: 10),
                            if (approvedBookings.isEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF161B22) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
                                ),
                                child: Center(
                                  child: Text(
                                    'No completed bookings registered today.',
                                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                                  ),
                                ),
                              ),
                            ] else ...[
                              ...approvedBookings.map((booking) {
                                final clientName = booking['clientName'] as String;
                                final field = booking['field'] as String;
                                final time = booking['time'] as String;
                                final price = booking['price'] as double;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF161B22) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: cs.onSurface.withValues(alpha: 0.05)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check_circle_rounded, color: PremiumTheme.neonGreen, size: 18),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            Text('$field • $time', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10)),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '+${price.toInt()} ₸',
                                        style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.w900, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
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
      },
    );
  }

  void _showPromotionsSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final codeController = TextEditingController();
    double discountPercent = 15;
    int maxUses = 50;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AnimatedBuilder(
              animation: FieldPricingManager(),
              builder: (context, _) {
                final manager = FieldPricingManager();
                final promoCodes = manager.promoCodes;

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
                              'PROMOTIONS & COUPONS',
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
                                  const Text('CREATE PROMO CODE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: codeController,
                                    decoration: InputDecoration(
                                      hintText: 'e.g. FLASH20',
                                      labelText: 'Coupon Code String',
                                      labelStyle: TextStyle(color: cs.onSurfaceVariant),
                                    ),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Discount Value', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      Text('${discountPercent.toInt()}% OFF', style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Slider(
                                    value: discountPercent,
                                    min: 5,
                                    max: 50,
                                    divisions: 9,
                                    activeColor: PremiumTheme.neonGreen,
                                    onChanged: (val) {
                                      setModalState(() {
                                        discountPercent = val;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Max Uses Limit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      Text('$maxUses uses', style: const TextStyle(color: PremiumTheme.electricBlue, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Slider(
                                    value: maxUses.toDouble(),
                                    min: 10,
                                    max: 200,
                                    divisions: 19,
                                    activeColor: PremiumTheme.electricBlue,
                                    onChanged: (val) {
                                      setModalState(() {
                                        maxUses = val.toInt();
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  PremiumButton(
                                    text: 'CREATE COUPON',
                                    onPressed: () {
                                      final rawCode = codeController.text.trim().toUpperCase();
                                      if (rawCode.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Please enter a coupon code!')),
                                        );
                                        return;
                                      }
                                      setModalState(() {
                                        manager.promoCodes.insert(0, {
                                          'code': rawCode,
                                          'discount': discountPercent.toInt(),
                                          'uses': '0/$maxUses',
                                          'status': 'ACTIVE',
                                          'expiry': '30 Jun 2026',
                                        });
                                        codeController.clear();
                                      });
                                      manager.notify();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: Colors.green,
                                          content: Text("Promo Code '$rawCode' created successfully!"),
                                        ),
                                      );
                                    },
                                    height: 44,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            const Text(
                              'ACTIVE COUPONS',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0),
                            ),
                            const SizedBox(height: 10),
                            if (promoCodes.isEmpty) ...[
                              Center(
                                child: Text(
                                  'No promo codes active.',
                                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                                ),
                              ),
                            ] else ...[
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: 1.15,
                                  ),
                                itemCount: promoCodes.length,
                                itemBuilder: (context, index) {
                                  final promo = promoCodes[index];
                                  final code = promo['code'] as String;
                                  final discount = promo['discount'] as int;
                                  final uses = promo['uses'] as String;
                                  final status = promo['status'] as String;
                                  final expiry = promo['expiry'] as String;
                                  final isActive = status == 'ACTIVE';

                                  return PremiumCard(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              code,
                                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: -0.2),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (isActive ? Colors.green : Colors.red).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                status,
                                                style: TextStyle(
                                                  color: isActive ? Colors.green : Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 7,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '$discount% OFF',
                                          style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.w900, fontSize: 14),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Uses: $uses',
                                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 9, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          'Expires: $expiry',
                                          style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 8),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
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
      },
    );
  }
}
