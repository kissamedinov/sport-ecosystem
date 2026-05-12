class TournamentSquadMember {
  final String id;
  final String childProfileId;
  final int? jerseyNumber;
  final String? position;
  final String tournamentTeamId;
  final String? playerName;

  TournamentSquadMember({
    required this.id,
    required this.childProfileId,
    this.jerseyNumber,
    this.position,
    required this.tournamentTeamId,
    this.playerName,
  });

  factory TournamentSquadMember.fromJson(Map<String, dynamic> json) {
    return TournamentSquadMember(
      id: json['id']?.toString() ?? '',
      childProfileId: json['child_profile_id']?.toString() ?? '',
      jerseyNumber: json['jersey_number'] as int?,
      position: json['position'] as String?,
      tournamentTeamId: json['tournament_team_id']?.toString() ?? '',
      playerName: json['player_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'child_profile_id': childProfileId,
    'jersey_number': jerseyNumber,
    'position': position,
    'tournament_team_id': tournamentTeamId,
    'player_name': playerName,
  };
}
