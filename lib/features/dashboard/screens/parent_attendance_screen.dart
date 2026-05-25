import 'package:flutter/material.dart';
import 'package:mobile/core/api/profile_api_service.dart';
import 'package:mobile/core/theme/premium_theme.dart';

class ParentAttendanceScreen extends StatefulWidget {
  const ParentAttendanceScreen({super.key});

  @override
  State<ParentAttendanceScreen> createState() => _ParentAttendanceScreenState();
}

class _ParentAttendanceScreenState extends State<ParentAttendanceScreen> {
  final _api = ProfileApiService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.getParentChildrenAttendance();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('ATTENDANCE',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 15)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen));
          }
          if (snap.hasError) {
            return _buildError();
          }
          final children = snap.data ?? [];
          if (children.isEmpty) {
            return _buildEmpty(cs);
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            itemCount: children.length,
            itemBuilder: (context, i) => _buildChildCard(children[i], cs),
          );
        },
      ),
    );
  }

  Widget _buildChildCard(Map<String, dynamic> child, ColorScheme cs) {
    final name = child['child_name'] as String? ?? '';
    final total = child['total_sessions'] as int? ?? 0;
    final present = child['present'] as int? ?? 0;
    final absent = child['absent'] as int? ?? 0;
    final late = child['late'] as int? ?? 0;
    final injured = child['injured'] as int? ?? 0;
    final rate = (child['attendance_rate'] as num?)?.toDouble() ?? 0.0;
    final initials = name.split(' ').where((w) => w.isNotEmpty).take(2)
        .map((w) => w[0].toUpperCase()).join();

    final rateColor = rate >= 80
        ? PremiumTheme.neonGreen
        : rate >= 60
            ? Colors.amber
            : PremiumTheme.danger;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PremiumTheme.surfaceCard(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Child header
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: PremiumTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(initials,
                style: const TextStyle(color: Colors.black,
                    fontSize: 14, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name,
              style: TextStyle(color: cs.onSurface,
                  fontWeight: FontWeight.w800, fontSize: 15))),
          // Rate badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: rateColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: rateColor.withValues(alpha: 0.3)),
            ),
            child: Text('$rate%',
                style: TextStyle(color: rateColor,
                    fontSize: 13, fontWeight: FontWeight.w900)),
          ),
        ]),
        const SizedBox(height: 20),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: total > 0 ? present / total : 0,
            minHeight: 8,
            backgroundColor: rateColor.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(rateColor),
          ),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('$present of $total sessions attended',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
          Text('${total > 0 ? (present / total * 100).toStringAsFixed(0) : 0}%',
              style: TextStyle(color: rateColor, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 20),
        // Stats grid
        Row(children: [
          Expanded(child: _buildStat('PRESENT', present, PremiumTheme.neonGreen, cs)),
          const SizedBox(width: 8),
          Expanded(child: _buildStat('ABSENT', absent, PremiumTheme.danger, cs)),
          const SizedBox(width: 8),
          Expanded(child: _buildStat('LATE', late, Colors.amber, cs)),
          const SizedBox(width: 8),
          Expanded(child: _buildStat('INJURED', injured, const Color(0xFFB490D0), cs)),
        ]),
      ]),
    );
  }

  Widget _buildStat(String label, int value, Color color, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(children: [
        Text('$value',
            style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(color: cs.onSurfaceVariant,
                fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ]),
    );
  }

  Widget _buildEmpty(ColorScheme cs) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.playlist_add_check_rounded,
            size: 64, color: cs.onSurface.withValues(alpha: 0.12)),
        const SizedBox(height: 16),
        Text('NO ATTENDANCE YET',
            style: TextStyle(color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
        const SizedBox(height: 8),
        Text('Attendance records will appear once your child starts training.',
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
        onPressed: () => setState(() => _future = _api.getParentChildrenAttendance()),
        child: const Text('RETRY', style: TextStyle(color: PremiumTheme.neonGreen)),
      ),
    ]),
  );
}
