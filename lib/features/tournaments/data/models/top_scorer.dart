class TopScorer {
  final String playerId;
  final String name;
  final String? teamName;
  final int goals;

  TopScorer({
    required this.playerId,
    required this.name,
    this.teamName,
    required this.goals,
  });

  factory TopScorer.fromJson(Map<String, dynamic> json) {
    return TopScorer(
      playerId: json['player_id'],
      name: json['name'],
      teamName: json['team_name'],
      goals: json['goals'],
    );
  }
}
