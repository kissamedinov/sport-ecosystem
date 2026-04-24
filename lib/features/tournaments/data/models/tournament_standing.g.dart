// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tournament_standing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TournamentStanding _$TournamentStandingFromJson(Map<String, dynamic> json) =>
    TournamentStanding(
      teamId: json['team_id'] as String,
      teamName: json['team_name'] as String?,
      played: (json['played'] as num).toInt(),
      wins: (json['wins'] as num).toInt(),
      draws: (json['draws'] as num).toInt(),
      losses: (json['losses'] as num).toInt(),
      goalsFor: (json['goals_for'] as num).toInt(),
      goalsAgainst: (json['goals_against'] as num).toInt(),
      goalDifference: (json['goal_difference'] as num).toInt(),
      points: (json['points'] as num).toInt(),
      divisionId: json['division_id'] as String?,
      groupId: json['group_id'] as String?,
    );

Map<String, dynamic> _$TournamentStandingToJson(TournamentStanding instance) =>
    <String, dynamic>{
      'team_id': instance.teamId,
      'team_name': instance.teamName,
      'played': instance.played,
      'wins': instance.wins,
      'draws': instance.draws,
      'losses': instance.losses,
      'goals_for': instance.goalsFor,
      'goals_against': instance.goalsAgainst,
      'goal_difference': instance.goalDifference,
      'points': instance.points,
      'division_id': instance.divisionId,
      'group_id': instance.groupId,
    };
