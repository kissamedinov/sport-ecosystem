import 'package:json_annotation/json_annotation.dart';

part 'match.g.dart';

@JsonSerializable()
class MatchModel {
  final String id;
  @JsonKey(name: 'home_team_id')
  final String? homeTeamId;
  @JsonKey(name: 'away_team_id')
  final String? awayTeamId;
  @JsonKey(name: 'match_date')
  final DateTime? matchDate;
  final String status;
  @JsonKey(name: 'home_score')
  final int? homeScore;
  @JsonKey(name: 'away_score')
  final int? awayScore;
  @JsonKey(name: 'tournament_id')
  final String? tournamentId;
  @JsonKey(name: 'division_id')
  final String? divisionId;
  @JsonKey(name: 'group_id')
  final String? groupId;
  @JsonKey(name: 'round_number')
  final int? roundNumber;

  // Compatibility getter for UI
  String get scheduledAt => matchDate?.toIso8601String() ?? "";

  MatchModel({
    required this.id,
    this.homeTeamId,
    this.awayTeamId,
    this.matchDate,
    required this.status,
    this.homeScore,
    this.awayScore,
    this.tournamentId,
    this.divisionId,
    this.groupId,
    this.roundNumber,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) => _$MatchModelFromJson(json);
  Map<String, dynamic> toJson() => _$MatchModelToJson(this);
}
