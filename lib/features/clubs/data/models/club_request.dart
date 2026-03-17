import 'package:json_annotation/json_annotation.dart';

part 'club_request.g.dart';

enum RequestStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('APPROVED')
  approved,
  @JsonValue('REJECTED')
  rejected,
}

@JsonSerializable()
class ClubRequest {
  final String id;
  final String name;
  final String city;
  final String address;
  @JsonKey(name: 'training_schedule')
  final String? trainingSchedule;
  @JsonKey(name: 'contact_phone')
  final String? contactPhone;
  @JsonKey(name: 'social_links')
  final String? socialLinks;
  final String? description;
  @JsonKey(name: 'created_by')
  final String createdBy;
  final RequestStatus status;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  ClubRequest({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    this.trainingSchedule,
    this.contactPhone,
    this.socialLinks,
    this.description,
    required this.createdBy,
    required this.status,
    required this.createdAt,
  });

  factory ClubRequest.fromJson(Map<String, dynamic> json) => _$ClubRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ClubRequestToJson(this);
}
