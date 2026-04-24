import 'package:flutter/material.dart';
import '../../data/models/top_scorer.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';

class LeaderboardItem extends StatelessWidget {
  final TopScorer scorer;
  final int rank;

  const LeaderboardItem({
    super.key,
    required this.scorer,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final bool isTop3 = rank <= 3;
    final Color medalColor = _getMedalColor();

    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildRankBadge(medalColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scorer.name.toUpperCase(),
                  style: TextStyle(
                    fontWeight: isTop3 ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                    color: isTop3 ? Colors.white : Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),
                if (scorer.teamName != null)
                  Text(
                    scorer.teamName!,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.sports_soccer, size: 12, color: PremiumTheme.neonGreen),
                const SizedBox(width: 6),
                Text(
                  "${scorer.goals}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: PremiumTheme.neonGreen,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(Color medalColor) {
    if (rank <= 3) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: medalColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: medalColor.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: medalColor.withValues(alpha: 0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            rank == 1 ? "🥇" : (rank == 2 ? "🥈" : "🥉"),
            style: const TextStyle(fontSize: 18),
          ),
        ),
      );
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          "$rank",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white38, fontSize: 13),
        ),
      ),
    );
  }

  Color _getMedalColor() {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return const Color(0xFFC0C0C0); // Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    return Colors.transparent;
  }
}
