// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'club.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Club _$ClubFromJson(Map<String, dynamic> json) => Club(
  id: json['id'] as String,
  name: json['name'] as String,
  city: json['city'] as String,
  ownerId: json['owner_id'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$ClubToJson(Club instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'city': instance.city,
  'owner_id': instance.ownerId,
  'created_at': instance.createdAt.toIso8601String(),
};
