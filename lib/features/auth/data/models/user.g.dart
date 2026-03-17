// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  roles: (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList(),
  childIds: (json['child_ids'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  playerProfileId: json['player_profile_id'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'roles': instance.roles,
  'child_ids': instance.childIds,
  'player_profile_id': instance.playerProfileId,
};
