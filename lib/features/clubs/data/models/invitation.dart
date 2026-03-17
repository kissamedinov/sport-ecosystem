import 'package:json_annotation/json_annotation.dart';

part 'invitation.g.dart';

enum InvitationStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('ACCEPTED')
  accepted,
  @JsonValue('DECLINED')
  declined,
}

enum ClubRole {
  @JsonValue('OWNER')
  owner,
  @JsonValue('MANAGER')
  manager,
  @JsonValue('COACH')
  coach,
  @JsonValue('PLAYER')
  player,
}

@JsonSerializable()
class Invitation {
  final String id;
  @JsonKey(name: 'club_id')
  final String clubId;
  @JsonKey(name: 'team_id')
  final String? teamId;
  @JsonKey(name: 'invited_user_id')
  final String invitedUserId;
  @JsonKey(name: 'invited_by')
  final String invitedBy;
  @JsonKey(name: 'child_profile_id')
  final String? childProfileId;
  final ClubRole role;
  final InvitationStatus status;
  @JsonKey(name: 'is_approved')
  final bool isApproved;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'expires_at')
  final DateTime? expiresAt;

  Invitation({
    required this.id,
    required this.clubId,
    this.teamId,
    required this.invitedUserId,
    required this.invitedBy,
    this.childProfileId,
    required this.role,
    required this.status,
    required this.isApproved,
    required this.createdAt,
    this.expiresAt,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) => _$InvitationFromJson(json);
  Map<String, dynamic> toJson() => _$InvitationToJson(this);
}
