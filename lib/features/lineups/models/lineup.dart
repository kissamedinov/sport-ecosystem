enum LineupStatus { SUBMITTED, CONFIRMED }

class MatchLineup {
  final String id;
  final String matchId;
  final String teamId;
  final String? submittedBy;
  final LineupStatus status;
  final DateTime createdAt;
  final List<LineupPlayer> players;

  MatchLineup({
    required this.id,
    required this.matchId,
    required this.teamId,
    this.submittedBy,
    required this.status,
    required this.createdAt,
    required this.players,
  });

  factory MatchLineup.fromJson(Map<String, dynamic> json) {
    return MatchLineup(
      id: json['id'],
      matchId: json['match_id'],
      teamId: json['team_id'],
      submittedBy: json['submitted_by'],
      status: json['status'] == 'CONFIRMED' ? LineupStatus.CONFIRMED : LineupStatus.SUBMITTED,
      createdAt: DateTime.parse(json['created_at']),
      players: (json['players'] as List)
          .map((p) => LineupPlayer.fromJson(p))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'match_id': matchId,
      'team_id': teamId,
      'players': players.map((p) => p.toJson()).toList(),
    };
  }
}

class LineupPlayer {
  final String? playerId;
  final String? childProfileId;
  final bool isStarting;
  final String? position;
  final int? jerseyNumber;

  LineupPlayer({
    this.playerId,
    this.childProfileId,
    required this.isStarting,
    this.position,
    this.jerseyNumber,
  });

  factory LineupPlayer.fromJson(Map<String, dynamic> json) {
    return LineupPlayer(
      playerId: json['player_id'],
      childProfileId: json['child_profile_id'],
      isStarting: json['is_starting'] ?? false,
      position: json['position'],
      jerseyNumber: json['jersey_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (playerId != null) 'player_id': playerId,
      if (childProfileId != null) 'child_profile_id': childProfileId,
      'is_starting': isStarting,
      'position': position,
      if (jerseyNumber != null) 'jersey_number': jerseyNumber,
    };
  }
}
