// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchModel _$MatchModelFromJson(Map<String, dynamic> json) => MatchModel(
  id: json['id'] as String,
  homeTeamId: json['home_team_id'] as String,
  awayTeamId: json['away_team_id'] as String,
  matchDate: json['match_date'] == null
      ? null
      : DateTime.parse(json['match_date'] as String),
  status: json['status'] as String,
  homeScore: (json['home_score'] as num?)?.toInt(),
  awayScore: (json['away_score'] as num?)?.toInt(),
  tournamentId: json['tournament_id'] as String?,
  divisionId: json['division_id'] as String?,
  groupId: json['group_id'] as String?,
);

Map<String, dynamic> _$MatchModelToJson(MatchModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'home_team_id': instance.homeTeamId,
      'away_team_id': instance.awayTeamId,
      'match_date': instance.matchDate?.toIso8601String(),
      'status': instance.status,
      'home_score': instance.homeScore,
      'away_score': instance.awayScore,
      'tournament_id': instance.tournamentId,
      'division_id': instance.divisionId,
      'group_id': instance.groupId,
    };
