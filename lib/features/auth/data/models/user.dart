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

  User({
    required this.id,
    required this.name,
    required this.email,
    this.roles,
    this.childIds,
    this.playerProfileId,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
