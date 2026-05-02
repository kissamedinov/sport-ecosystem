import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String name;
  final String email;
  final List<String>? roles;
  @JsonKey(name: 'child_ids')
  final List<String>? childIds;

  @JsonKey(name: 'player_profile_id')
  final String? playerProfileId;
  @JsonKey(name: 'onboarding_completed', defaultValue: false)
  final bool onboardingCompleted;
  @JsonKey(name: 'date_of_birth')
  final DateTime? dateOfBirth;
  final String? phone;
  final String? bio;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @JsonKey(name: 'unique_code')
  final String? uniqueCode;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.roles,
    this.childIds,
    this.playerProfileId,
    this.onboardingCompleted = false,
    this.dateOfBirth,
    this.phone,
    this.bio,
    this.avatarUrl,
    this.uniqueCode,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
