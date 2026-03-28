import 'package:flutter/material.dart';
import '../../data/models/match_award.dart';

class AwardCard extends StatelessWidget {
  final MatchAward award;

  const AwardCard({super.key, required this.award});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)], // Gold to Orange
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, color: Colors.white, size: 40),
            const SizedBox(height: 12),
            Text(
              _getAwardLabel(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              award.playerId ?? award.childProfileId ?? "Player",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getAwardLabel() {
    switch (award.awardType) {
      case MatchAwardType.MVP:
        return "MVP";
      case MatchAwardType.BEST_GOALKEEPER:
        return "Best GK";
      case MatchAwardType.BEST_DEFENDER:
        return "Best DF";
      case MatchAwardType.BEST_STRIKER:
        return "Best FW";
    }
  }
}

extension ColorExtension on Colors {
  static const Color gold = Color(0xFFFFD700);
}
