// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tournament_match.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TournamentMatch _$TournamentMatchFromJson(Map<String, dynamic> json) =>
    TournamentMatch(
      id: json['id'] as String,
      tournamentId: json['tournament_id'] as String?,
      divisionId: json['division_id'] as String?,
      homeTeamId: json['home_team_id'] as String,
      awayTeamId: json['away_team_id'] as String,
      fieldId: json['field_id'] as String?,
      matchDate: json['match_date'] == null
          ? null
          : DateTime.parse(json['match_date'] as String),
      status: json['status'] as String,
      homeScore: (json['home_score'] as num).toInt(),
      awayScore: (json['away_score'] as num).toInt(),
      groupId: json['group_id'] as String?,
    );

Map<String, dynamic> _$TournamentMatchToJson(TournamentMatch instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tournament_id': instance.tournamentId,
      'division_id': instance.divisionId,
      'home_team_id': instance.homeTeamId,
      'away_team_id': instance.awayTeamId,
      'field_id': instance.fieldId,
      'match_date': instance.matchDate?.toIso8601String(),
      'status': instance.status,
      'home_score': instance.homeScore,
      'away_score': instance.awayScore,
      'group_id': instance.groupId,
    };
