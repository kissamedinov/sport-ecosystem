import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/orleon_widgets.dart';
import '../../../clubs/providers/club_provider.dart';

class PerformanceScreen extends StatelessWidget {
  final bool embedded;
  const PerformanceScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final body = Consumer<ClubProvider>(
      builder: (context, club, _) {
        final data = club.coachDashboard ?? {};
        final perf = (data['performance_stats'] as Map<String, dynamic>?) ?? {};
        final top = (data['top_performers'] as List?) ?? _demoTopPerformers;

        return RefreshIndicator(
          onRefresh: () => club.fetchCoachDashboard(),
          color: PremiumTheme.neonGreen,
          backgroundColor: PremiumTheme.cardNavy,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (!embedded) SliverToBoxAdapter(child: _header(context)),
              SliverToBoxAdapter(child: _WinRateCard(perf: perf)),
              const SliverToBoxAdapter(
                child: OrleonSectionHeader(title: 'Season Stats'),
              ),
              SliverToBoxAdapter(child: _StatsGrid(perf: perf)),
              const SliverToBoxAdapter(
                child: OrleonSectionHeader(title: 'Top Performers'),
              ),
              SliverToBoxAdapter(child: _TopPerformers(list: top)),
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          ),
        );
      },
    );

    if (embedded) return body;
    return Scaffold(
      backgroundColor: PremiumTheme.deepNavy,
      body: SafeArea(child: body),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 20, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 26),
          ),
          const Expanded(
            child: Text(
              'PERFORMANCE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _demoTopPerformers = [
    {'name': 'Luca Garcia', 'stat': '12 goals', 'rating': 8.4},
    {'name': 'Elias Moreau', 'stat': '9 assists', 'rating': 8.1},
    {'name': 'Noah Bernard', 'stat': '8 clean sheets', 'rating': 7.9},
    {'name': 'Hugo Laurent', 'stat': '7 goals', 'rating': 7.7},
    {'name': 'Arthur Petit', 'stat': '6 assists', 'rating': 7.5},
  ];
}

class _WinRateCard extends StatelessWidget {
  final Map<String, dynamic> perf;
  const _WinRateCard({required this.perf});

  @override
  Widget build(BuildContext context) {
    final raw = perf['win_rate'] ?? perf['winRate'] ?? 0;
    final value = raw is num ? raw.toDouble() : double.tryParse('$raw') ?? 0;
    final pct = value > 1 ? value : value * 100;
    final wins = (perf['wins'] ?? 0).toString();
    final draws = (perf['draws'] ?? 0).toString();
    final losses = (perf['losses'] ?? 0).toString();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: OrleonCard(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F1E16), Color(0xFF0A0E12)],
        ),
        borderColor: PremiumTheme.neonGreen.withValues(alpha: 0.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WIN RATE',
              style: TextStyle(
                color: PremiumTheme.neonGreen,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  pct.toStringAsFixed(0),
                  style: const TextStyle(
                    color: PremiumTheme.neonGreen,
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: -4,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 14, left: 4),
                  child: Text(
                    '%',
                    style: TextStyle(
                      color: PremiumTheme.neonGreen,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (pct / 100).clamp(0, 1),
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation(PremiumTheme.neonGreen),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _miniResult('W', wins, PremiumTheme.neonGreen),
                const SizedBox(width: 12),
                _miniResult('D', draws, PremiumTheme.amber),
                const SizedBox(width: 12),
                _miniResult('L', losses, PremiumTheme.danger),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniResult(String letter, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              letter,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> perf;
  const _StatsGrid({required this.perf});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Goals Scored',
        (perf['goals_scored'] ?? 34).toString(),
        Icons.sports_soccer,
        PremiumTheme.electricBlue,
        null as String?,
      ),
      (
        'Conceded',
        (perf['goals_conceded'] ?? 18).toString(),
        Icons.shield_outlined,
        PremiumTheme.danger,
        null,
      ),
      (
        'Clean Sheets',
        (perf['clean_sheets'] ?? 7).toString(),
        Icons.verified_outlined,
        PremiumTheme.amber,
        null,
      ),
      (
        'xPoints',
        (perf['x_points'] ?? 42).toString(),
        Icons.insights_outlined,
        Colors.purpleAccent,
        'EXPECTED',
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: items
            .map((e) => OrleonStatCard(
                  label: e.$1,
                  value: e.$2,
                  icon: e.$3,
                  accent: e.$4,
                  badge: e.$5,
                ))
            .toList(),
      ),
    );
  }
}

class _TopPerformers extends StatelessWidget {
  final List list;
  const _TopPerformers({required this.list});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: list.take(5).toList().asMap().entries.map((entry) {
          final i = entry.key;
          final p = (entry.value as Map).cast<String, dynamic>();
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OrleonCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _Medal(rank: i + 1),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (p['name'] ?? 'Player').toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (p['stat'] ?? '').toString(),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: PremiumTheme.neonGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      (p['rating'] ?? 0).toString(),
                      style: const TextStyle(
                        color: PremiumTheme.neonGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Medal extends StatelessWidget {
  final int rank;
  const _Medal({required this.rank});

  Color get _color {
    switch (rank) {
      case 1:
        return PremiumTheme.gold;
      case 2:
        return PremiumTheme.silver;
      case 3:
        return PremiumTheme.bronze;
      default:
        return Colors.white24;
    }
  }

  IconData get _icon => rank <= 3 ? Icons.emoji_events : Icons.person_outline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _color.withValues(alpha: 0.6)),
      ),
      alignment: Alignment.center,
      child: rank <= 3
          ? Icon(_icon, color: _color, size: 20)
          : Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }
}
