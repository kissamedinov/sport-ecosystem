import 'package:flutter/material.dart';
import '../../data/models/top_scorer.dart';

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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: rank <= 3 ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: rank <= 3
            ? BorderSide(color: _getMedalColor().withOpacity(0.5), width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildRankBadge(),
        title: Text(
          scorer.name,
          style: TextStyle(
            fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
            fontSize: 18,
          ),
        ),
        subtitle: scorer.teamName != null
            ? Text(scorer.teamName!)
            : null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "${scorer.goals} Goals",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRankBadge() {
    if (rank <= 3) {
      return Text(
        rank == 1 ? "🥇" : (rank == 2 ? "🥈" : "🥉"),
        style: const TextStyle(fontSize: 32),
      );
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          "#$rank",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Color _getMedalColor() {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.blueGrey[300]!;
    if (rank == 3) return Colors.brown[300]!;
    return Colors.transparent;
  }
}
