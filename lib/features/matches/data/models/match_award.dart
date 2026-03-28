enum MatchAwardType {
  MVP,
  BEST_GOALKEEPER,
  BEST_DEFENDER,
  BEST_STRIKER,
}

class MatchAward {
  final String id;
  final String matchId;
  final String? playerId;
  final String? childProfileId;
  final MatchAwardType awardType;
  final String createdAt;

  MatchAward({
    required this.id,
    required this.matchId,
    this.playerId,
    this.childProfileId,
    required this.awardType,
    required this.createdAt,
  });

  factory MatchAward.fromJson(Map<String, dynamic> json) {
    return MatchAward(
      id: json['id'],
      matchId: json['match_id'],
      playerId: json['player_id'],
      childProfileId: json['child_profile_id'],
      awardType: MatchAwardType.values.firstWhere(
        (e) => e.name == json['award_type'],
        orElse: () => MatchAwardType.MVP,
      ),
      createdAt: json['created_at'],
    );
  }
}
