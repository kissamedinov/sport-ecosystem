import 'package:json_annotation/json_annotation.dart';

part 'match.g.dart';

@JsonSerializable()
class MatchModel {
  final String id;
  @JsonKey(name: 'home_team_id')
  final String homeTeamId;
  @JsonKey(name: 'away_team_id')
  final String awayTeamId;
  @JsonKey(name: 'scheduled_at')
  final String scheduledAt;
  final String status;
  @JsonKey(name: 'home_score')
  final int? homeScore;
  @JsonKey(name: 'away_score')
  final int? awayScore;
  @JsonKey(name: 'tournament_id')
  final String? tournamentId;

  MatchModel({
    required this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.scheduledAt,
    required this.status,
    this.homeScore,
    this.awayScore,
    this.tournamentId,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) => _$MatchModelFromJson(json);
  Map<String, dynamic> toJson() => _$MatchModelToJson(this);
}
