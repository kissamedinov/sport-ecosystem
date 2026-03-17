// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Player _$PlayerFromJson(Map<String, dynamic> json) => Player(
  id: json['id'] as String,
  name: json['name'] as String,
  position: json['position'] as String?,
  dateOfBirth: json['date_of_birth'] as String?,
  avatarUrl: json['avatar_url'] as String?,
);

Map<String, dynamic> _$PlayerToJson(Player instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'position': instance.position,
  'date_of_birth': instance.dateOfBirth,
  'avatar_url': instance.avatarUrl,
};
