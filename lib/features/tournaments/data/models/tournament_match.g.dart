// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tournament_match.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TournamentMatch _$TournamentMatchFromJson(Map<String, dynamic> json) =>
    TournamentMatch(
      id: json['id'] as String,
      tournamentId: json['tournament_id'] as String,
      homeTeamId: json['home_team_id'] as String,
      awayTeamId: json['away_team_id'] as String,
      fieldNumber: (json['field_number'] as num?)?.toInt(),
      startTime: json['start_time'] == null
          ? null
          : DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] == null
          ? null
          : DateTime.parse(json['end_time'] as String),
      status: json['status'] as String,
      homeScore: (json['home_score'] as num).toInt(),
      awayScore: (json['away_score'] as num).toInt(),
    );

Map<String, dynamic> _$TournamentMatchToJson(TournamentMatch instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tournament_id': instance.tournamentId,
      'home_team_id': instance.homeTeamId,
      'away_team_id': instance.awayTeamId,
      'field_number': instance.fieldNumber,
      'start_time': instance.startTime?.toIso8601String(),
      'end_time': instance.endTime?.toIso8601String(),
      'status': instance.status,
      'home_score': instance.homeScore,
      'away_score': instance.awayScore,
    };
