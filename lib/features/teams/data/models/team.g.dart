// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Team _$TeamFromJson(Map<String, dynamic> json) => Team(
  id: json['id'] as String,
  name: json['name'] as String,
  city: json['city'] as String,
  coachId: json['coach_id'] as String,
  rating: (json['rating'] as num).toInt(),
  matchesPlayed: (json['matches_played'] as num).toInt(),
  wins: (json['wins'] as num).toInt(),
  draws: (json['draws'] as num).toInt(),
  losses: (json['losses'] as num).toInt(),
  academyName: json['academy_name'] as String?,
  ageCategory: json['age_category'] as String?,
  birthYear: (json['birth_year'] as num?)?.toInt(),
  recentMatches:
      (json['recent_matches'] as List<dynamic>?)
          ?.map((e) => MatchModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  form:
      (json['form'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  players:
      (json['players'] as List<dynamic>?)
          ?.map((e) => PlayerTeam.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$TeamToJson(Team instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'city': instance.city,
  'coach_id': instance.coachId,
  'rating': instance.rating,
  'matches_played': instance.matchesPlayed,
  'wins': instance.wins,
  'draws': instance.draws,
  'losses': instance.losses,
  'academy_name': instance.academyName,
  'age_category': instance.ageCategory,
  'birth_year': instance.birthYear,
  'recent_matches': instance.recentMatches,
  'form': instance.form,
  'players': instance.players,
};
