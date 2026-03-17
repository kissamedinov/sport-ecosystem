// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlayerInfo _$PlayerInfoFromJson(Map<String, dynamic> json) => PlayerInfo(
  userId: json['user_id'] as String,
  name: json['name'] as String,
  profileId: json['profile_id'] as String,
  position: json['position'] as String?,
  jerseyNumber: (json['jersey_number'] as num?)?.toInt(),
);

Map<String, dynamic> _$PlayerInfoToJson(PlayerInfo instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'name': instance.name,
      'profile_id': instance.profileId,
      'position': instance.position,
      'jersey_number': instance.jerseyNumber,
    };
