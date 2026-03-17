import 'package:json_annotation/json_annotation.dart';
import 'package:mobile/features/teams/data/models/team.dart';

part 'tournament_team_response.g.dart';

@JsonSerializable()
class TournamentTeamResponse {
  final String id;
  @JsonKey(name: 'tournament_id')
  final String tournamentId;
  @JsonKey(name: 'team_id')
  final String teamId;
  final String status;
  @JsonKey(name: 'registration_data')
  final String? registrationData;
  final Team team;

  TournamentTeamResponse({
    required this.id,
    required this.tournamentId,
    required this.teamId,
    required this.status,
    required this.team,
    this.registrationData,
  });

  factory TournamentTeamResponse.fromJson(Map<String, dynamic> json) => _$TournamentTeamResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TournamentTeamResponseToJson(this);
}
