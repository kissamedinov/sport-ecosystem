import 'package:flutter/material.dart';
import '../../../../core/theme/premium_theme.dart';

class LeaderboardItem extends StatelessWidget {
  final String name;
  final String? teamName;
  final int rank;
  final int value;
  final String? displayValue;
  final IconData icon;
  final Color highlightColor;

  const LeaderboardItem({
    super.key,
    required this.name,
    this.teamName,
    required this.rank,
    required this.value,
    this.displayValue,
    this.icon = Icons.sports_soccer,
    this.highlightColor = PremiumTheme.neonGreen,
  });

  @override
  Widget build(BuildContext context) {
    final bool isTop3 = rank <= 3;
    final Color medalColor = _getMedalColor();
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.02),
        border: Border(
          bottom: BorderSide(
            color: cs.onSurface.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
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
                    fontWeight: isTop3 ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                    color: cs.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
                if (teamName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    teamName!,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: highlightColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(icon, size: 12, color: highlightColor),
                const SizedBox(width: 6),
                Text(
                  displayValue ?? "$value",
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
    final cs = Theme.of(context).colorScheme;
    final isTop3 = rank <= 3;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isTop3 ? medalColor : cs.onSurface.withValues(alpha: 0.05),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          "$rank",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isTop3 ? Colors.black : cs.onSurface.withValues(alpha: 0.5),
            fontSize: 12,
          ),
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
