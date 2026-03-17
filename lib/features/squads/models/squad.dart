class TournamentSquad {
  final String id;
  final String tournamentId;
  final String teamId;
  final String coachId;
  final DateTime createdAt;
  final List<String> playerIds;

  TournamentSquad({
    required this.id,
    required this.tournamentId,
    required this.teamId,
    required this.coachId,
    required this.createdAt,
    required this.playerIds,
  });

  factory TournamentSquad.fromJson(Map<String, dynamic> json) {
    return TournamentSquad(
      id: json['id'],
      tournamentId: json['tournament_id'],
      teamId: json['team_id'],
      coachId: json['coach_id'],
      createdAt: DateTime.parse(json['created_at']),
      playerIds: List<String>.from(json['player_ids'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'team_id': teamId,
      'coach_id': coachId,
      'created_at': createdAt.toIso8601String(),
      'player_ids': playerIds,
    };
  }
}
