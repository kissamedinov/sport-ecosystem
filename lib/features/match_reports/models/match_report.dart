class MatchReport {
  final String id;
  final String matchId;
  final String managerId;
  final DateTime submittedAt;
  final int homeScore;
  final int awayScore;
  final List<MatchPlayerStats> playerStats;

  MatchReport({
    required this.id,
    required this.matchId,
    required this.managerId,
    required this.submittedAt,
    required this.homeScore,
    required this.awayScore,
    required this.playerStats,
  });

  factory MatchReport.fromJson(Map<String, dynamic> json) {
    return MatchReport(
      id: json['id'],
      matchId: json['match_id'],
      managerId: json['manager_id'],
      submittedAt: DateTime.parse(json['submitted_at']),
      homeScore: json['home_score'],
      awayScore: json['away_score'],
      playerStats: (json['player_stats'] as List)
          .map((s) => MatchPlayerStats.fromJson(s))
          .toList(),
    );
  }
}

class MatchPlayerStats {
  final String id;
  final String matchId;
  final String playerId;
  final String teamId;
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;
  final bool isMvp;

  MatchPlayerStats({
    required this.id,
    required this.matchId,
    required this.playerId,
    required this.teamId,
    this.goals = 0,
    this.assists = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.isMvp = false,
  });

  factory MatchPlayerStats.fromJson(Map<String, dynamic> json) {
    return MatchPlayerStats(
      id: json['id'],
      matchId: json['match_id'],
      playerId: json['player_id'],
      teamId: json['team_id'],
      goals: json['goals'] ?? 0,
      assists: json['assists'] ?? 0,
      yellowCards: json['yellow_cards'] ?? 0,
      redCards: json['red_cards'] ?? 0,
      isMvp: json['is_mvp'] ?? false,
    );
  }
}
