import 'package:flutter/material.dart';
import 'package:mobile/core/api/profile_api_service.dart';
import 'package:mobile/core/theme/premium_theme.dart';

class ParentCoachNotesScreen extends StatefulWidget {
  const ParentCoachNotesScreen({super.key});

  @override
  State<ParentCoachNotesScreen> createState() => _ParentCoachNotesScreenState();
}

class _ParentCoachNotesScreenState extends State<ParentCoachNotesScreen> {
  final _api = ProfileApiService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.getParentChildrenFeedback();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('COACH NOTES',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 15)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen));
          }
          if (snap.hasError) {
            return _buildError(snap.error.toString());
          }
          final children = snap.data ?? [];
          if (children.isEmpty) {
            return _buildEmpty(cs, 'No feedback yet',
                'Coach ratings will appear here once your child is enrolled in an academy.');
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            itemCount: children.length,
            itemBuilder: (context, i) => _buildChildSection(children[i], cs),
          );
        },
      ),
    );
  }

  Widget _buildChildSection(Map<String, dynamic> child, ColorScheme cs) {
    final name = child['child_name'] as String;
    final feedbacks = (child['feedbacks'] as List?) ?? [];
    final initials = name.split(' ').where((w) => w.isNotEmpty).take(2)
        .map((w) => w[0].toUpperCase()).join();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: PremiumTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(initials,
                style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 12),
          Text(name.toUpperCase(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900,
                  color: cs.onSurfaceVariant, letterSpacing: 1.5)),
        ]),
        const SizedBox(height: 12),
        if (feedbacks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: PremiumTheme.surfaceCard(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
            ),
            child: Text('No feedback from coach yet',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          )
        else
          ...feedbacks.map((f) => _buildFeedbackCard(f as Map<String, dynamic>, cs)),
      ],
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> f, ColorScheme cs) {
    final date = (f['created_at'] as String?)?.substring(0, 10) ?? '';
    final comment = f['comment'] as String?;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PremiumTheme.surfaceCard(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PremiumTheme.electricBlue.withValues(alpha: 0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: PremiumTheme.electricBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('COACH RATING',
                style: TextStyle(color: PremiumTheme.electricBlue, fontSize: 9,
                    fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
          Text(date, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _buildRatingBar('Technical', f['technical'] as int? ?? 0,
              const Color(0xFF42A5F5))),
          const SizedBox(width: 12),
          Expanded(child: _buildRatingBar('Tactical', f['tactical'] as int? ?? 0,
              PremiumTheme.neonGreen)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _buildRatingBar('Physical', f['physical'] as int? ?? 0,
              Colors.amber)),
          const SizedBox(width: 12),
          Expanded(child: _buildRatingBar('Discipline', f['discipline'] as int? ?? 0,
              const Color(0xFFB490D0))),
        ]),
        if (comment != null && comment.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(comment,
                style: TextStyle(color: cs.onSurface, fontSize: 13, height: 1.4)),
          ),
        ],
      ]),
    );
  }

  Widget _buildRatingBar(String label, int value, Color color) {
    final pct = (value.clamp(0, 10) / 10.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 10, fontWeight: FontWeight.w600)),
        Text('$value/10', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: pct,
          minHeight: 6,
          backgroundColor: color.withValues(alpha: 0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    ]);
  }

  Widget _buildEmpty(ColorScheme cs, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 64, color: cs.onSurface.withValues(alpha: 0.12)),
          const SizedBox(height: 16),
          Text(title.toUpperCase(),
              style: TextStyle(color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 48, color: PremiumTheme.danger),
          const SizedBox(height: 16),
          Text('Failed to load', style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _future = _api.getParentChildrenFeedback()),
            child: const Text('RETRY', style: TextStyle(color: PremiumTheme.neonGreen)),
          ),
        ]),
      ),
    );
  }
}
