import 'package:json_annotation/json_annotation.dart';

part 'tournament_match.g.dart';

@JsonSerializable()
class TournamentMatch {
  final String id;
  @JsonKey(name: 'tournament_id')
  final String? tournamentId;
  @JsonKey(name: 'division_id')
  final String? divisionId;
  @JsonKey(name: 'home_team_id')
  final String? homeTeamId;
  @JsonKey(name: 'away_team_id')
  final String? awayTeamId;
  @JsonKey(name: 'field_id')
  final String? fieldId;
  @JsonKey(name: 'field_name')
  final String? fieldName;
  @JsonKey(name: 'match_date')
  final DateTime? matchDate;
  final String status;
  @JsonKey(name: 'home_score')
  final int homeScore;
  @JsonKey(name: 'away_score')
  final int awayScore;
  @JsonKey(name: 'home_team_name')
  final String? homeTeamName;
  @JsonKey(name: 'away_team_name')
  final String? awayTeamName;
  @JsonKey(name: 'group_id')
  final String? groupId;
  @JsonKey(name: 'next_match_id')
  final String? nextMatchId;
  @JsonKey(name: 'bracket_position')
  final int? bracketPosition;
  @JsonKey(name: 'round_number')
  final int? roundNumber;

  TournamentMatch({
    required this.id,
    this.tournamentId,
    this.divisionId,
    this.homeTeamId,
    this.awayTeamId,
    this.fieldId,
    this.fieldName,
    this.matchDate,
    required this.status,
    required this.homeScore,
    required this.awayScore,
    this.homeTeamName,
    this.awayTeamName,
    this.groupId,
    this.nextMatchId,
    this.bracketPosition,
    this.roundNumber,
  });

  factory TournamentMatch.fromJson(Map<String, dynamic> json) => _$TournamentMatchFromJson(json);
  Map<String, dynamic> toJson() => _$TournamentMatchToJson(this);
}
