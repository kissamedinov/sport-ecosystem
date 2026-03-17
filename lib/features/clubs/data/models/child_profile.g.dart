// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'child_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChildProfile _$ChildProfileFromJson(Map<String, dynamic> json) => ChildProfile(
      id: json['id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      dateOfBirth: DateTime.parse(json['date_of_birth'] as String),
      position: json['position'] as String?,
      createdBy: json['created_by'] as String,
      clubId: json['club_id'] as String,
      linkedUserId: json['linked_user_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ChildProfileToJson(ChildProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'date_of_birth': instance.dateOfBirth.toIso8601String(),
      'position': instance.position,
      'created_by': instance.createdBy,
      'club_id': instance.clubId,
      'linked_user_id': instance.linkedUserId,
      'created_at': instance.createdAt.toIso8601String(),
    };
