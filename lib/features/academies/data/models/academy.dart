import 'package:json_annotation/json_annotation.dart';

part 'academy.g.dart';

@JsonSerializable()
class Academy {
  final String id;
  final String name;
  final String city;
  final String address;
  @JsonKey(name: 'club_id')
  final String clubId;
  @JsonKey(name: 'owner_id')
  final String ownerId;
  @JsonKey(name: 'logo_url')
  final String? logoUrl;
  @JsonKey(name: 'teams_count')
  final int? teamsCount;
  @JsonKey(name: 'players_count')
  final int? playersCount;

  Academy({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.clubId,
    required this.ownerId,
    this.logoUrl,
    this.teamsCount,
    this.playersCount,
  });

  factory Academy.fromJson(Map<String, dynamic> json) => _$AcademyFromJson(json);
  Map<String, dynamic> toJson() => _$AcademyToJson(this);
}
