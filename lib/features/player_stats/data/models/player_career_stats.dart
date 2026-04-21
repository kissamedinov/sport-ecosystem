class PlayerCareerStats {
  final String playerId;
  final int matchesPlayed;
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;
  final int bestPlayerAwards;
  final double rating;

  PlayerCareerStats({
    required this.playerId,
    required this.matchesPlayed,
    required this.goals,
    required this.assists,
    required this.yellowCards,
    required this.redCards,
    required this.bestPlayerAwards,
    required this.rating,
  });

  factory PlayerCareerStats.fromJson(Map<String, dynamic> json) {
    return PlayerCareerStats(
      playerId: json['player_id'],
      matchesPlayed: json['matches_played'] ?? 0,
      goals: json['goals'] ?? 0,
      assists: json['assists'] ?? 0,
      yellowCards: json['yellow_cards'] ?? 0,
      redCards: json['red_cards'] ?? 0,
      bestPlayerAwards: json['best_player_awards'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
    );
  }
}
