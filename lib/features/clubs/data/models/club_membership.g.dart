// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'club_membership.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClubMembership _$ClubMembershipFromJson(Map<String, dynamic> json) =>
    ClubMembership(
      id: json['id'] as String,
      clubId: json['club_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      leftAt: json['left_at'] == null
          ? null
          : DateTime.parse(json['left_at'] as String),
    );

Map<String, dynamic> _$ClubMembershipToJson(ClubMembership instance) =>
    <String, dynamic>{
      'id': instance.id,
      'club_id': instance.clubId,
      'user_id': instance.userId,
      'role': instance.role,
      'status': instance.status,
      'joined_at': instance.joinedAt.toIso8601String(),
      'left_at': instance.leftAt?.toIso8601String(),
    };
