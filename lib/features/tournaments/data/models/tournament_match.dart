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
  final String homeTeamId;
  @JsonKey(name: 'away_team_id')
  final String awayTeamId;
  @JsonKey(name: 'field_id')
  final String? fieldId;
  @JsonKey(name: 'match_date')
  final DateTime? matchDate;
  final String status;
  @JsonKey(name: 'home_score')
  final int homeScore;
  @JsonKey(name: 'away_score')
  final int awayScore;
  @JsonKey(name: 'group_id')
  final String? groupId;

  TournamentMatch({
    required this.id,
    this.tournamentId,
    this.divisionId,
    required this.homeTeamId,
    required this.awayTeamId,
    this.fieldId,
    this.matchDate,
    required this.status,
    required this.homeScore,
    required this.awayScore,
    this.groupId,
  });

  factory TournamentMatch.fromJson(Map<String, dynamic> json) => _$TournamentMatchFromJson(json);
  Map<String, dynamic> toJson() => _$TournamentMatchToJson(this);
}
