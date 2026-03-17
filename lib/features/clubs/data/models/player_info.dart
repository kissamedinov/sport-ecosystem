import 'package:json_annotation/json_annotation.dart';

part 'player_info.g.dart';

@JsonSerializable()
class PlayerInfo {
  @JsonKey(name: 'user_id')
  final String userId;
  final String name;
  @JsonKey(name: 'profile_id')
  final String profileId;
  final String? position;
  @JsonKey(name: 'jersey_number')
  final int? jerseyNumber;

  PlayerInfo({
    required this.userId,
    required this.name,
    required this.profileId,
    this.position,
    this.jerseyNumber,
  });

  factory PlayerInfo.fromJson(Map<String, dynamic> json) => _$PlayerInfoFromJson(json);
  Map<String, dynamic> toJson() => _$PlayerInfoToJson(this);
}
