import 'package:json_annotation/json_annotation.dart';

part 'club.g.dart';

@JsonSerializable()
class Club {
  final String id;
  final String name;
  final String city;
  @JsonKey(name: 'owner_id')
  final String ownerId;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Club({
    required this.id,
    required this.name,
    required this.city,
    required this.ownerId,
    required this.createdAt,
  });

  factory Club.fromJson(Map<String, dynamic> json) => _$ClubFromJson(json);
  Map<String, dynamic> toJson() => _$ClubToJson(this);
}
