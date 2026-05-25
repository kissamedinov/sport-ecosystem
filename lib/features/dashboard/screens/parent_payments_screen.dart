import 'package:flutter/material.dart';
import 'package:mobile/core/api/profile_api_service.dart';
import 'package:mobile/core/theme/premium_theme.dart';

class ParentPaymentsScreen extends StatefulWidget {
  const ParentPaymentsScreen({super.key});

  @override
  State<ParentPaymentsScreen> createState() => _ParentPaymentsScreenState();
}

class _ParentPaymentsScreenState extends State<ParentPaymentsScreen> {
  final _api = ProfileApiService();
  late Future<List<Map<String, dynamic>>> _future;
  int _selectedMonth = DateTime.now().month;
  final int _selectedYear = DateTime.now().year;

  final _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _loadBilling();
  }

  void _loadBilling() {
    _future = _api.getParentChildrenBilling(month: _selectedMonth, year: _selectedYear);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('PAYMENTS',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 15)),
      ),
      body: Column(children: [
        _buildMonthPicker(cs),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: PremiumTheme.neonGreen));
              }
              if (snap.hasError) {
                return _buildError();
              }
              final children = snap.data ?? [];
              if (children.isEmpty) {
                return _buildEmpty(cs);
              }
              final total = children.fold<double>(
                0, (sum, c) => sum + ((c['total_owed'] as num?)?.toDouble() ?? 0));
              final currency = (children.first['currency'] as String?) ?? 'KZT';
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: [
                  _buildTotalCard(total, currency, cs),
                  const SizedBox(height: 8),
                  ...children.map((c) => _buildChildBillingCard(c, cs)),
                ],
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildMonthPicker(ColorScheme cs) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _months.length,
        itemBuilder: (context, i) {
          final isSelected = i + 1 == _selectedMonth;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedMonth = i + 1;
                _loadBilling();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFB490D0).withValues(alpha: 0.15)
                    : PremiumTheme.surfaceCard(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFB490D0).withValues(alpha: 0.5)
                      : cs.onSurface.withValues(alpha: 0.08),
                ),
              ),
              child: Text(_months[i],
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFB490D0) : cs.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  )),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalCard(double total, String currency, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xFFB490D0).withValues(alpha: 0.12),
          const Color(0xFFB490D0).withValues(alpha: 0.04),
        ]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFB490D0).withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFB490D0).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.account_balance_wallet_outlined,
              color: Color(0xFFB490D0), size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('TOTAL FOR ${_months[_selectedMonth - 1].toUpperCase()} $_selectedYear',
              style: TextStyle(color: cs.onSurfaceVariant,
                  fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text('${total.toStringAsFixed(0)} $currency',
              style: const TextStyle(color: Color(0xFFB490D0),
                  fontSize: 24, fontWeight: FontWeight.w900)),
        ])),
      ]),
    );
  }

  Widget _buildChildBillingCard(Map<String, dynamic> child, ColorScheme cs) {
    final name = child['child_name'] as String? ?? '';
    final totalOwed = (child['total_owed'] as num?)?.toDouble() ?? 0.0;
    final baseFee = (child['base_fee'] as num?)?.toDouble() ?? 0.0;
    final currency = child['currency'] as String? ?? 'KZT';
    final totalSessions = child['total_sessions'] as int? ?? 0;
    final present = child['present'] as int? ?? 0;
    final absent = child['absent'] as int? ?? 0;
    final initials = name.split(' ').where((w) => w.isNotEmpty).take(2)
        .map((w) => w[0].toUpperCase()).join();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PremiumTheme.surfaceCard(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              gradient: PremiumTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(initials,
                style: const TextStyle(color: Colors.black,
                    fontSize: 13, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name,
              style: TextStyle(color: cs.onSurface,
                  fontWeight: FontWeight.w800, fontSize: 14))),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${totalOwed.toStringAsFixed(0)} $currency',
                style: const TextStyle(color: Color(0xFFB490D0),
                    fontWeight: FontWeight.w900, fontSize: 16)),
            Text('owed', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10)),
          ]),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          _buildMiniStat('SESSIONS', '$totalSessions', cs),
          const SizedBox(width: 8),
          _buildMiniStat('PRESENT', '$present', cs, color: PremiumTheme.neonGreen),
          const SizedBox(width: 8),
          _buildMiniStat('ABSENT', '$absent', cs, color: PremiumTheme.danger),
          const SizedBox(width: 8),
          _buildMiniStat('BASE FEE', '${baseFee.toStringAsFixed(0)}', cs,
              color: const Color(0xFFB490D0)),
        ]),
        if (totalOwed > 0) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment gateway coming soon')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB490D0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: const Text('PAY NOW',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildMiniStat(String label, String value, ColorScheme cs, {Color? color}) {
    final c = color ?? cs.onSurface;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(color: c, fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: cs.onSurfaceVariant,
                  fontSize: 7, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
        ]),
      ),
    );
  }

  Widget _buildEmpty(ColorScheme cs) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.account_balance_wallet_outlined,
            size: 64, color: cs.onSurface.withValues(alpha: 0.12)),
        const SizedBox(height: 16),
        Text('NO BILLING DATA',
            style: TextStyle(color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
        const SizedBox(height: 8),
        Text('Billing information will appear once your child is enrolled.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 12)),
      ]),
    ),
  );

  Widget _buildError() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, size: 48, color: PremiumTheme.danger),
      const SizedBox(height: 16),
      TextButton(
        onPressed: () => setState(() => _loadBilling()),
        child: const Text('RETRY', style: TextStyle(color: PremiumTheme.neonGreen)),
      ),
    ]),
  );
}
