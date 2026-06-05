import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';
import '../../data/field_pricing_manager.dart';

class OwnerAnalyticsScreen extends StatefulWidget {
  const OwnerAnalyticsScreen({super.key});

  @override
  State<OwnerAnalyticsScreen> createState() => _OwnerAnalyticsScreenState();
}

class _OwnerAnalyticsScreenState extends State<OwnerAnalyticsScreen> {
  int _selectedPeriod = 0; // 0 = Today, 1 = 7 Days, 2 = 30 Days

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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final manager = FieldPricingManager();

    // Dynamically calculate revenue by field from approved requests
    double sairanAdd = 0;
    double sportCityAdd = 0;
    double astanaAdd = 0;
    double dumanAdd = 0;
    double qazaqstanAdd = 0;

    final approvedReqs = manager.pendingRequests.where((req) => req['status'] == 'APPROVED').toList();

    for (final req in approvedReqs) {
      final field = req['field'] as String;
      final price = (req['price'] as num).toDouble();
      if (field == 'SAIRAN ARENA') sairanAdd += price;
      else if (field == 'SPORT CITY PITCHES') sportCityAdd += price;
      else if (field == 'ASTANA ARENA') astanaAdd += price;
      else if (field == 'DUMAN SPORT COMPLEX') dumanAdd += price;
      else if (field == 'QAZAQSTAN ATHLETIC COMPLEX') qazaqstanAdd += price;
    }

    // Base statistics to simulate history
    double totalRevenue = manager.todayRevenue;
    double occupancy = manager.occupancy;
    int bookingsCount = approvedReqs.length + 5;

    if (_selectedPeriod == 1) {
      totalRevenue = manager.todayRevenue + 185000.0;
      occupancy = (manager.occupancy - 0.04).clamp(0.0, 1.0);
      bookingsCount = approvedReqs.length + 18;
    } else if (_selectedPeriod == 2) {
      totalRevenue = manager.todayRevenue + 720000.0;
      occupancy = (manager.occupancy + 0.02).clamp(0.0, 1.0);
      bookingsCount = approvedReqs.length + 54;
    }

    // Dynamic field breakdowns
    final fieldStats = [
      {
        'name': 'SAIRAN ARENA',
        'revenue': 45000.0 + sairanAdd,
        'bookings': 3 + approvedReqs.where((r) => r['field'] == 'SAIRAN ARENA').length,
        'color': PremiumTheme.neonGreen
      },
      {
        'name': 'SPORT CITY PITCHES',
        'revenue': 24000.0 + sportCityAdd,
        'bookings': 2 + approvedReqs.where((r) => r['field'] == 'SPORT CITY PITCHES').length,
        'color': PremiumTheme.electricBlue
      },
      {
        'name': 'ASTANA ARENA',
        'revenue': 50000.0 + astanaAdd,
        'bookings': 2 + approvedReqs.where((r) => r['field'] == 'ASTANA ARENA').length,
        'color': Colors.orangeAccent
      },
      {
        'name': 'DUMAN SPORT COMPLEX',
        'revenue': 10000.0 + dumanAdd,
        'bookings': 1 + approvedReqs.where((r) => r['field'] == 'DUMAN SPORT COMPLEX').length,
        'color': Colors.pinkAccent
      },
      {
        'name': 'QAZAQSTAN ATHLETIC COMPLEX',
        'revenue': 20000.0 + qazaqstanAdd,
        'bookings': 1 + approvedReqs.where((r) => r['field'] == 'QAZAQSTAN ATHLETIC COMPLEX').length,
        'color': Colors.tealAccent
      },
    ];

    // Sort by revenue descending
    fieldStats.sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));
    final double maxFieldRevenue = fieldStats.map((e) => e['revenue'] as double).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        title: Text('analytics.business_analytics'.tr().toUpperCase(), style: const TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold, fontSize: 13)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period selector choice chips
            Row(
              children: [
                _buildPeriodChip('analytics.today'.tr(), 0),
                const SizedBox(width: 8),
                _buildPeriodChip('analytics.seven_days'.tr(), 1),
                const SizedBox(width: 8),
                _buildPeriodChip('analytics.thirty_days'.tr(), 2),
              ],
            ),
            const SizedBox(height: 24),

            // Top Stat Row
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    'analytics.total_revenue'.tr(),
                    '${totalRevenue.toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")} ₸',
                    Icons.payments_outlined,
                    PremiumTheme.neonGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniStat(
                    'analytics.occupancy_rate'.tr(),
                    '${(occupancy * 100).toInt()}%',
                    Icons.trending_up,
                    PremiumTheme.electricBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildMiniStat(
              'analytics.total_bookings'.tr(),
              '$bookingsCount ${'analytics.reservations'.tr()}',
              Icons.calendar_today_outlined,
              Colors.orangeAccent,
              horizontal: true,
            ),
            const SizedBox(height: 32),

            // Revenue breakdown by field
            _buildSectionHeader('analytics.revenue_by_arena'.tr()),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161B22) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
              ),
              child: Column(
                children: fieldStats.map((item) {
                  final String name = item['name'] as String;
                  final double rev = item['revenue'] as double;
                  final int count = item['bookings'] as int;
                  final Color color = item['color'] as Color;
                  
                  final ratio = maxFieldRevenue > 0 ? rev / maxFieldRevenue : 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${rev.toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")} ₸ ($count ${'analytics.bookings_label'.tr()})',
                              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 8,
                            backgroundColor: cs.onSurface.withValues(alpha: 0.05),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),

            // Peak Booking Times
            _buildSectionHeader('analytics.peak_hours'.tr()),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161B22) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
              ),
              child: Column(
                children: [
                  _buildPeakBar('18:00 - 21:00 (Prime)', 0.95, PremiumTheme.neonGreen),
                  _buildPeakBar('21:00 - 00:00 (Late)', 0.85, PremiumTheme.electricBlue),
                  _buildPeakBar('15:00 - 18:00 (Mid-day)', 0.70, Colors.orangeAccent),
                  _buildPeakBar('12:00 - 15:00 (Noon)', 0.55, Colors.amber),
                  _buildPeakBar('08:00 - 12:00 (Morning)', 0.35, Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Recent Transaction Logs
            _buildSectionHeader('analytics.transaction_logs'.tr()),
            const SizedBox(height: 12),
            if (approvedReqs.isEmpty) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text('analytics.no_transactions'.tr(), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                ),
              ),
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: approvedReqs.length,
                itemBuilder: (context, idx) {
                  final req = approvedReqs[idx];
                  final String client = req['clientName'] as String;
                  final String field = req['field'] as String;
                  final String date = req['date'] as String;
                  final String time = req['time'] as String;
                  final double price = (req['price'] as num).toDouble();

                  final String invoice = 'TX-${req['id'].hashCode.abs().toString().padLeft(6, '0')}';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF161B22) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.onSurface.withValues(alpha: 0.04)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoice,
                              style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              client,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              '$field, $date @ $time',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                        Text(
                          '+${price.toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")} ₸',
                          style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildPeriodChip(String label, int index) {
    final isSel = _selectedPeriod == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPeriod = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? PremiumTheme.neonGreen : (isDark ? const Color(0xFF161B22) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSel ? PremiumTheme.neonGreen : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSel ? Colors.black : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color, {bool horizontal = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 12),
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color)),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: cs.onSurface.withValues(alpha: 0.3),
            letterSpacing: 1.0,
          ),
        ),
      ],
    );

    if (horizontal) {
      content = Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface.withValues(alpha: 0.3),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
            ],
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: content,
    );
  }

  Widget _buildPeakBar(String label, double ratio, Color color) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              Text('${(ratio * 100).toInt()}% occupancy', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: cs.onSurface.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
