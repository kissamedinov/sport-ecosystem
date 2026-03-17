// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'career_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CareerRecord _$CareerRecordFromJson(Map<String, dynamic> json) => CareerRecord(
  clubName: json['club_name'] as String,
  teamName: json['team_name'] as String,
  joinedAt: DateTime.parse(json['joined_at'] as String),
  leftAt: json['left_at'] == null
      ? null
      : DateTime.parse(json['left_at'] as String),
  status: json['status'] as String,
);

Map<String, dynamic> _$CareerRecordToJson(CareerRecord instance) =>
    <String, dynamic>{
      'club_name': instance.clubName,
      'team_name': instance.teamName,
      'joined_at': instance.joinedAt.toIso8601String(),
      'left_at': instance.leftAt?.toIso8601String(),
      'status': instance.status,
    };

PlayerCareer _$PlayerCareerFromJson(Map<String, dynamic> json) => PlayerCareer(
  playerName: json['player_name'] as String,
  careerHistory: (json['career_history'] as List<dynamic>)
      .map((e) => CareerRecord.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalGoals: (json['total_goals'] as num).toInt(),
  totalAssists: (json['total_assists'] as num).toInt(),
  awards: (json['awards'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$PlayerCareerToJson(PlayerCareer instance) =>
    <String, dynamic>{
      'player_name': instance.playerName,
      'career_history': instance.careerHistory,
      'total_goals': instance.totalGoals,
      'total_assists': instance.totalAssists,
      'awards': instance.awards,
    };
