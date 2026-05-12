// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tournament_team_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TournamentTeamResponse _$TournamentTeamResponseFromJson(
  Map<String, dynamic> json,
) => TournamentTeamResponse(
  id: json['id'] as String,
  divisionId: json['division_id'] as String?,
  tournamentId: json['tournament_id'] as String,
  teamId: json['team_id'] as String,
  status: json['status'] as String,
  team: Team.fromJson(json['team'] as Map<String, dynamic>),
  registrationData: json['registration_data'] as String?,
);

Map<String, dynamic> _$TournamentTeamResponseToJson(
  TournamentTeamResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'division_id': instance.divisionId,
  'tournament_id': instance.tournamentId,
  'team_id': instance.teamId,
  'status': instance.status,
  'registration_data': instance.registrationData,
  'team': instance.team,
};
