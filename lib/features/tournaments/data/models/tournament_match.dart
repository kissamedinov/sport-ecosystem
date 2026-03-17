import 'package:json_annotation/json_annotation.dart';

part 'tournament_match.g.dart';

@JsonSerializable()
class TournamentMatch {
  final String id;
  @JsonKey(name: 'tournament_id')
  final String tournamentId;
  @JsonKey(name: 'home_team_id')
  final String homeTeamId;
  @JsonKey(name: 'away_team_id')
  final String awayTeamId;
  @JsonKey(name: 'field_number')
  final int? fieldNumber;
  @JsonKey(name: 'start_time')
  final DateTime? startTime;
  @JsonKey(name: 'end_time')
  final DateTime? endTime;
  final String status;
  @JsonKey(name: 'home_score')
  final int homeScore;
  @JsonKey(name: 'away_score')
  final int awayScore;

  TournamentMatch({
    required this.id,
    required this.tournamentId,
    required this.homeTeamId,
    required this.awayTeamId,
    this.fieldNumber,
    this.startTime,
    this.endTime,
    required this.status,
    required this.homeScore,
    required this.awayScore,
  });

  factory TournamentMatch.fromJson(Map<String, dynamic> json) => _$TournamentMatchFromJson(json);
  Map<String, dynamic> toJson() => _$TournamentMatchToJson(this);
}
