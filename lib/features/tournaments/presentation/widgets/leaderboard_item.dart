import 'package:flutter/material.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';

class LeaderboardItem extends StatelessWidget {
  final String name;
  final String? teamName;
  final int rank;
  final int value;
  final IconData icon;
  final Color highlightColor;

  const LeaderboardItem({
    super.key,
    required this.name,
    this.teamName,
    required this.rank,
    required this.value,
    this.icon = Icons.sports_soccer,
    this.highlightColor = PremiumTheme.neonGreen,
  });

  @override
  Widget build(BuildContext context) {
    final bool isTop3 = rank <= 3;
    final Color medalColor = _getMedalColor();

    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildRankBadge(context, medalColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toUpperCase(),
                  style: TextStyle(
                    fontWeight: isTop3 ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                    color: isTop3 ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    letterSpacing: 0.5,
                  ),
                ),
                if (teamName != null)
                  Text(
                    teamName!,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 11),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: highlightColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: highlightColor.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 12, color: highlightColor),
                const SizedBox(width: 6),
                Text(
                  "$value",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: highlightColor,
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

  Widget _buildRankBadge(BuildContext context, Color medalColor) {
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
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          "$rank",
          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 13),
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
