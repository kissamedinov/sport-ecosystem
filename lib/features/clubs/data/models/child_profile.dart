import 'package:json_annotation/json_annotation.dart';

part 'child_profile.g.dart';

@JsonSerializable()
class ChildProfile {
  final String id;
  @JsonKey(name: 'first_name')
  final String firstName;
  @JsonKey(name: 'last_name')
  final String lastName;
  @JsonKey(name: 'date_of_birth')
  final DateTime dateOfBirth;
  final String? position;
  @JsonKey(name: 'created_by')
  final String createdBy;
  @JsonKey(name: 'club_id')
  final String clubId;
  @JsonKey(name: 'linked_user_id')
  final String? linkedUserId;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  ChildProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    this.position,
    required this.createdBy,
    required this.clubId,
    this.linkedUserId,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  factory ChildProfile.fromJson(Map<String, dynamic> json) => _$ChildProfileFromJson(json);
  Map<String, dynamic> toJson() => _$ChildProfileToJson(this);
}
