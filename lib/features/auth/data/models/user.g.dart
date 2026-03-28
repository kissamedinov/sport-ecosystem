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
  onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
  dateOfBirth: json['date_of_birth'] == null
      ? null
      : DateTime.parse(json['date_of_birth'] as String),
  phone: json['phone'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'roles': instance.roles,
  'child_ids': instance.childIds,
  'player_profile_id': instance.playerProfileId,
  'onboarding_completed': instance.onboardingCompleted,
  'date_of_birth': instance.dateOfBirth?.toIso8601String(),
  'phone': instance.phone,
};
