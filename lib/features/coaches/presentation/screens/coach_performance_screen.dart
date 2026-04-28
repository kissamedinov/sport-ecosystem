import 'package:flutter/material.dart';
import 'package:mobile/core/theme/premium_theme.dart';

class CoachPerformanceScreen extends StatelessWidget {
  final Map<String, dynamic> perf;
  final List topPerformers;

  const CoachPerformanceScreen({
    super.key,
    required this.perf,
    required this.topPerformers,
  });

  @override
  Widget build(BuildContext context) {
    final wins = (perf['wins'] ?? 0) as num;
    final total = (perf['matches_played'] ?? 0) as num;
    final winRate = total > 0 ? (wins / total * 100) : 0.0;
    final goals = perf['goals_scored'] ?? 0;
    final conceded = perf['goals_conceded'] ?? 0;
    final cleanSheets = perf['clean_sheets'] ?? 0;
    final xPoints = perf['xpoints'] ?? 0;

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'PERFORMANCE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _buildSeasonHeader(),
          const SizedBox(height: 20),
          _buildWinRateCard(context, winRate, total.toInt()),
          const SizedBox(height: 12),
          _buildStatsGrid(goals, conceded, cleanSheets, xPoints),
          const SizedBox(height: 24),
          _buildTopPerformersSection(context),
        ],
      ),
    );
  }

  Widget _buildSeasonHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Season Stats',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '2025/26 · All teams combined',
          style: TextStyle(color: Colors.white38, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildWinRateCard(BuildContext context, double winRate, int matchesPlayed) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: PremiumTheme.glassDecorationOf(context, radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WIN RATE',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${winRate.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: PremiumTheme.neonGreen,
              fontSize: 60,
              fontWeight: FontWeight.w900,
              height: 1.0,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$matchesPlayed matches played this season',
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: winRate / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: const AlwaysStoppedAnimation<Color>(PremiumTheme.neonGreen),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(int goals, int conceded, int cleanSheets, int xPoints) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _statsCard(
                icon: Icons.sports_soccer_rounded,
                iconColor: PremiumTheme.electricBlue,
                value: '$goals',
                label: 'GOALS SCORED',
                bgColor: PremiumTheme.electricBlue.withValues(alpha: 0.06),
                borderColor: PremiumTheme.electricBlue.withValues(alpha: 0.15),
                valueColor: PremiumTheme.electricBlue,
              ),
              const SizedBox(height: 10),
              _statsCard(
                icon: Icons.shield_outlined,
                iconColor: Colors.amber,
                value: '$cleanSheets',
                label: 'CLEAN SHEETS',
                bgColor: Colors.amber.withValues(alpha: 0.06),
                borderColor: Colors.amber.withValues(alpha: 0.15),
                valueColor: Colors.amber,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              _statsCard(
                icon: Icons.sports_soccer_rounded,
                iconColor: Colors.redAccent,
                value: '$conceded',
                label: 'CONCEDED',
                bgColor: Colors.redAccent.withValues(alpha: 0.06),
                borderColor: Colors.redAccent.withValues(alpha: 0.15),
                valueColor: Colors.redAccent,
              ),
              const SizedBox(height: 10),
              _statsCard(
                icon: Icons.bar_chart_rounded,
                iconColor: Colors.purpleAccent,
                value: '$xPoints',
                label: 'XPOINTS',
                bgColor: Colors.purpleAccent.withValues(alpha: 0.06),
                borderColor: Colors.purpleAccent.withValues(alpha: 0.15),
                valueColor: Colors.purpleAccent,
                badge: 'EXPECTED',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statsCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required Color bgColor,
    required Color borderColor,
    required Color valueColor,
    String? badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              if (badge != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.0,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 16),
            SizedBox(width: 8),
            Text(
              'TOP PERFORMERS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (topPerformers.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: PremiumTheme.glassDecorationOf(context, radius: 16),
            child: const Center(
              child: Text(
                'NO PERFORMER DATA',
                style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
              ),
            ),
          )
        else
          ...topPerformers.asMap().entries.map((entry) {
            return _performerRow(context, entry.key + 1, entry.value as Map<String, dynamic>);
          }),
      ],
    );
  }

  Widget _performerRow(BuildContext context, int rank, Map<String, dynamic> player) {
    final name = player['name']?.toString() ?? player['player_name']?.toString() ?? 'Player';
    final jersey = player['jersey_number']?.toString() ?? '—';
    final position = player['position']?.toString() ?? 'FW';
    final goals = player['goals']?.toString() ?? '0';
    final assists = player['assists']?.toString() ?? '0';
    final rating = (player['rating'] as num?)?.toStringAsFixed(1) ?? '—';

    Color rankColor;
    if (rank == 1) rankColor = Colors.amber;
    else if (rank == 2) rankColor = Colors.white54;
    else if (rank == 3) rankColor = Colors.orangeAccent;
    else rankColor = Colors.white24;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: PremiumTheme.glassDecorationOf(context, radius: 14),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: rankColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(color: rankColor, fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: PremiumTheme.neonGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: Text(
                  jersey,
                  style: const TextStyle(color: PremiumTheme.neonGreen, fontSize: 13, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    position,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _statChip(goals, 'G', PremiumTheme.neonGreen),
                const SizedBox(width: 8),
                _statChip(assists, 'A', PremiumTheme.electricBlue),
                const SizedBox(width: 8),
                _statChip(rating, 'RTG', Colors.amber),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          style: TextStyle(color: color.withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
      ],
    );
  }
}
