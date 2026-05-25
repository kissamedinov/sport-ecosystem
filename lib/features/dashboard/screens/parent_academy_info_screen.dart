import 'package:flutter/material.dart';
import 'package:mobile/core/api/profile_api_service.dart';
import 'package:mobile/core/theme/premium_theme.dart';

class ParentAcademyInfoScreen extends StatefulWidget {
  const ParentAcademyInfoScreen({super.key});

  @override
  State<ParentAcademyInfoScreen> createState() => _ParentAcademyInfoScreenState();
}

class _ParentAcademyInfoScreenState extends State<ParentAcademyInfoScreen> {
  final _api = ProfileApiService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.getParentAcademyInfo();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('ACADEMY INFO',
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
          final academies = snap.data ?? [];
          if (academies.isEmpty) {
            return _buildEmpty(cs);
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            itemCount: academies.length,
            itemBuilder: (context, i) => _buildAcademyCard(academies[i], cs),
          );
        },
      ),
    );
  }

  Widget _buildAcademyCard(Map<String, dynamic> academy, ColorScheme cs) {
    final name = academy['name'] as String? ?? '';
    final city = academy['city'] as String? ?? '';
    final address = academy['address'] as String? ?? '';
    final description = academy['description'] as String?;
    final childNames = (academy['child_names'] as List?)?.cast<String>() ?? [];
    final schedules = (academy['schedules'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: PremiumTheme.surfaceCard(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFC107).withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              const Color(0xFFFFC107).withValues(alpha: 0.08),
              const Color(0xFFFFC107).withValues(alpha: 0.02),
            ]),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.school_outlined, color: Color(0xFFFFC107), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  style: TextStyle(color: cs.onSurface,
                      fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 3),
              Row(children: [
                Icon(Icons.location_on_rounded, size: 12, color: cs.onSurfaceVariant),
                const SizedBox(width: 3),
                Text('$city · $address',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
              ]),
            ])),
          ]),
        ),
        // Children enrolled
        if (childNames.isNotEmpty) ...[
          _buildDivider(cs),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildSectionLabel('ENROLLED CHILDREN', cs),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: childNames.map((n) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.3)),
                  ),
                  child: Text(n,
                      style: const TextStyle(color: PremiumTheme.neonGreen,
                          fontSize: 12, fontWeight: FontWeight.w700)),
                )).toList(),
              ),
            ]),
          ),
        ],
        // Description
        if (description != null && description.isNotEmpty) ...[
          _buildDivider(cs),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildSectionLabel('ABOUT', cs),
              const SizedBox(height: 8),
              Text(description,
                  style: TextStyle(color: cs.onSurface, fontSize: 13, height: 1.5)),
            ]),
          ),
        ],
        // Training schedule
        if (schedules.isNotEmpty) ...[
          _buildDivider(cs),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildSectionLabel('TRAINING SCHEDULE', cs),
              const SizedBox(height: 10),
              ...schedules.map((s) => _buildScheduleRow(s, cs)),
            ]),
          ),
        ],
        if (schedules.isEmpty) const SizedBox(height: 6),
      ]),
    );
  }

  Widget _buildScheduleRow(Map<String, dynamic> s, ColorScheme cs) {
    final day = s['day_of_week'] as String? ?? '';
    final start = (s['start_time'] as String?)?.substring(0, 5) ?? '';
    final end = (s['end_time'] as String?)?.substring(0, 5) ?? '';
    final location = s['location'] as String?;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Container(
          width: 80,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC107).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(day.substring(0, 3).toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFFFC107),
                  fontSize: 10, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 12),
        Text('$start – $end',
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700, fontSize: 13)),
        if (location != null && location.isNotEmpty) ...[
          const SizedBox(width: 8),
          Icon(Icons.location_on_rounded, size: 11, color: cs.onSurfaceVariant),
          const SizedBox(width: 2),
          Expanded(child: Text(location,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
              overflow: TextOverflow.ellipsis)),
        ],
      ]),
    );
  }

  Widget _buildDivider(ColorScheme cs) =>
      Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06));

  Widget _buildSectionLabel(String text, ColorScheme cs) => Text(text,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
          color: cs.onSurfaceVariant, letterSpacing: 1.5));

  Widget _buildEmpty(ColorScheme cs) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.school_outlined, size: 64, color: cs.onSurface.withValues(alpha: 0.12)),
        const SizedBox(height: 16),
        Text('NO ACADEMY YET',
            style: TextStyle(color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
        const SizedBox(height: 8),
        Text('Your child will appear here once enrolled in an academy.',
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
        onPressed: () => setState(() => _future = _api.getParentAcademyInfo()),
        child: const Text('RETRY', style: TextStyle(color: PremiumTheme.neonGreen)),
      ),
    ]),
  );
}
