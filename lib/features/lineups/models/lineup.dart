class MatchLineup {
  final String id;
  final String matchId;
  final String teamId;
  final String coachId;
  final DateTime createdAt;
  final List<LineupPlayer> players;

  MatchLineup({
    required this.id,
    required this.matchId,
    required this.teamId,
    required this.coachId,
    required this.createdAt,
    required this.players,
  });

  factory MatchLineup.fromJson(Map<String, dynamic> json) {
    return MatchLineup(
      id: json['id'],
      matchId: json['match_id'],
      teamId: json['team_id'],
      coachId: json['coach_id'],
      createdAt: DateTime.parse(json['created_at']),
      players: (json['players'] as List)
          .map((p) => LineupPlayer.fromJson(p))
          .toList(),
    );
  }
}

class LineupPlayer {
  final String playerId;
  final bool isStarting;

  LineupPlayer({
    required this.playerId,
    required this.isStarting,
  });

  factory LineupPlayer.fromJson(Map<String, dynamic> json) {
    return LineupPlayer(
      playerId: json['player_id'],
      isStarting: json['is_starting'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'player_id': playerId,
      'is_starting': isStarting,
    };
  }
}
