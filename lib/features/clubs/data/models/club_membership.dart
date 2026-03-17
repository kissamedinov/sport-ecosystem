import 'package:json_annotation/json_annotation.dart';

part 'club_membership.g.dart';

@JsonSerializable()
class ClubMembership {
  final String id;
  @JsonKey(name: 'club_id')
  final String clubId;
  @JsonKey(name: 'user_id')
  final String userId;
  final String role;
  final String status;
  @JsonKey(name: 'joined_at')
  final DateTime joinedAt;
  @JsonKey(name: 'left_at')
  final DateTime? leftAt;

  ClubMembership({
    required this.id,
    required this.clubId,
    required this.userId,
    required this.role,
    required this.status,
    required this.joinedAt,
    this.leftAt,
  });

  factory ClubMembership.fromJson(Map<String, dynamic> json) => _$ClubMembershipFromJson(json);
  Map<String, dynamic> toJson() => _$ClubMembershipToJson(this);
}
