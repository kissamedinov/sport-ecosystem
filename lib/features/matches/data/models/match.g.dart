// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchModel _$MatchModelFromJson(Map<String, dynamic> json) => MatchModel(
  id: json['id'] as String,
  homeTeamId: json['home_team_id'] as String,
  awayTeamId: json['away_team_id'] as String,
  scheduledAt: json['scheduled_at'] as String,
  status: json['status'] as String,
  homeScore: (json['home_score'] as num?)?.toInt(),
  awayScore: (json['away_score'] as num?)?.toInt(),
  tournamentId: json['tournament_id'] as String?,
);

Map<String, dynamic> _$MatchModelToJson(MatchModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'home_team_id': instance.homeTeamId,
      'away_team_id': instance.awayTeamId,
      'scheduled_at': instance.scheduledAt,
      'status': instance.status,
      'home_score': instance.homeScore,
      'away_score': instance.awayScore,
      'tournament_id': instance.tournamentId,
    };
