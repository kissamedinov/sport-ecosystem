import 'package:json_annotation/json_annotation.dart';

part 'tournament_standing.g.dart';

@JsonSerializable()
class TournamentStanding {
  @JsonKey(name: 'team_id')
  final String teamId;
  @JsonKey(name: 'team_name')
  final String? teamName;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  @JsonKey(name: 'goals_for')
  final int goalsFor;
  @JsonKey(name: 'goals_against')
  final int goalsAgainst;
  @JsonKey(name: 'goal_difference')
  final int goalDifference;
  final int points;

  TournamentStanding({
    required this.teamId,
    this.teamName,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
  });

  factory TournamentStanding.fromJson(Map<String, dynamic> json) => _$TournamentStandingFromJson(json);
  Map<String, dynamic> toJson() => _$TournamentStandingToJson(this);
}
