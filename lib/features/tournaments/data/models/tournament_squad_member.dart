class TournamentSquadMember {
  final String id;
  final String playerProfileId;
  final int? jerseyNumber;
  final String? position;
  final String tournamentTeamId;

  TournamentSquadMember({
    required this.id,
    required this.playerProfileId,
    this.jerseyNumber,
    this.position,
    required this.tournamentTeamId,
  });

  factory TournamentSquadMember.fromJson(Map<String, dynamic> json) {
    return TournamentSquadMember(
      id: json['id']?.toString() ?? '',
      playerProfileId: json['player_profile_id']?.toString() ?? '',
      jerseyNumber: json['jersey_number'] as int?,
      position: json['position'] as String?,
      tournamentTeamId: json['tournament_team_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'player_profile_id': playerProfileId,
    'jersey_number': jerseyNumber,
    'position': position,
    'tournament_team_id': tournamentTeamId,
  };
}
