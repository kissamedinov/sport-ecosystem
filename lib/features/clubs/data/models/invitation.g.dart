// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invitation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Invitation _$InvitationFromJson(Map<String, dynamic> json) => Invitation(
  id: json['id'] as String,
  clubId: json['club_id'] as String,
  teamId: json['team_id'] as String?,
  invitedUserId: json['invited_user_id'] as String,
  invitedBy: json['invited_by'] as String,
  childProfileId: json['child_profile_id'] as String?,
  role: $enumDecode(_$ClubRoleEnumMap, json['role']),
  status: $enumDecode(_$InvitationStatusEnumMap, json['status']),
  isApproved: json['is_approved'] as bool,
  createdAt: DateTime.parse(json['created_at'] as String),
  expiresAt: json['expires_at'] == null
      ? null
      : DateTime.parse(json['expires_at'] as String),
);

Map<String, dynamic> _$InvitationToJson(Invitation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'club_id': instance.clubId,
      'team_id': instance.teamId,
      'invited_user_id': instance.invitedUserId,
      'invited_by': instance.invitedBy,
      'child_profile_id': instance.childProfileId,
      'role': _$ClubRoleEnumMap[instance.role]!,
      'status': _$InvitationStatusEnumMap[instance.status]!,
      'is_approved': instance.isApproved,
      'created_at': instance.createdAt.toIso8601String(),
      'expires_at': instance.expiresAt?.toIso8601String(),
    };

const _$ClubRoleEnumMap = {
  ClubRole.owner: 'OWNER',
  ClubRole.manager: 'MANAGER',
  ClubRole.coach: 'COACH',
  ClubRole.player: 'PLAYER',
};

const _$InvitationStatusEnumMap = {
  InvitationStatus.pending: 'PENDING',
  InvitationStatus.accepted: 'ACCEPTED',
  InvitationStatus.declined: 'DECLINED',
};
