// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'academy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Academy _$AcademyFromJson(Map<String, dynamic> json) => Academy(
  id: json['id'] as String,
  name: json['name'] as String,
  city: json['city'] as String,
  address: json['address'] as String,
  clubId: json['club_id'] as String,
  ownerId: json['owner_id'] as String,
  logoUrl: json['logo_url'] as String?,
  teamsCount: (json['teams_count'] as num?)?.toInt(),
  playersCount: (json['players_count'] as num?)?.toInt(),
);

Map<String, dynamic> _$AcademyToJson(Academy instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'city': instance.city,
  'address': instance.address,
  'club_id': instance.clubId,
  'owner_id': instance.ownerId,
  'logo_url': instance.logoUrl,
  'teams_count': instance.teamsCount,
  'players_count': instance.playersCount,
};
