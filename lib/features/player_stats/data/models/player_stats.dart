class PlayerStats {
  final String playerId;
  final String name;
  final int goals;
  final int assists;
  final int saves;
  final int yellowCards;
  final int redCards;
  final List<String> awards;

  PlayerStats({
    required this.playerId,
    required this.name,
    required this.goals,
    required this.assists,
    required this.saves,
    required this.yellowCards,
    required this.redCards,
    required this.awards,
  });

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      playerId: json['player_id'],
      name: json['name'],
      goals: json['goals'] ?? 0,
      assists: json['assists'] ?? 0,
      saves: json['saves'] ?? 0,
      yellowCards: json['yellow_cards'] ?? 0,
      redCards: json['red_cards'] ?? 0,
      awards: List<String>.from(json['awards'] ?? []),
    );
  }
}
