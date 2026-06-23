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
      fieldName: json['field_name'] as String?,
      matchDate:
          json['match_date'] == null
              ? null
              : DateTime.parse(json['match_date'] as String),
      status: json['status'] as String,
      homeScore: (json['home_score'] as num).toInt(),
      awayScore: (json['away_score'] as num).toInt(),
      homeTeamName: json['home_team_name'] as String?,
      awayTeamName: json['away_team_name'] as String?,
      groupId: json['group_id'] as String?,
      nextMatchId: json['next_match_id'] as String?,
      bracketPosition: (json['bracket_position'] as num?)?.toInt(),
      roundNumber: (json['round_number'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TournamentMatchToJson(TournamentMatch instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tournament_id': instance.tournamentId,
      'division_id': instance.divisionId,
      'home_team_id': instance.homeTeamId,
      'away_team_id': instance.awayTeamId,
      'field_id': instance.fieldId,
      'field_name': instance.fieldName,
      'match_date': instance.matchDate?.toIso8601String(),
      'status': instance.status,
      'home_score': instance.homeScore,
      'away_score': instance.awayScore,
      'home_team_name': instance.homeTeamName,
      'away_team_name': instance.awayTeamName,
      'group_id': instance.groupId,
      'next_match_id': instance.nextMatchId,
      'bracket_position': instance.bracketPosition,
      'round_number': instance.roundNumber,
    };
