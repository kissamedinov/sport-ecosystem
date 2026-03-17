import 'package:json_annotation/json_annotation.dart';

part 'career_record.g.dart';

@JsonSerializable()
class CareerRecord {
  @JsonKey(name: 'club_name')
  final String clubName;
  @JsonKey(name: 'team_name')
  final String teamName;
  @JsonKey(name: 'joined_at')
  final DateTime joinedAt;
  @JsonKey(name: 'left_at')
  final DateTime? leftAt;
  final String status;

  CareerRecord({
    required this.clubName,
    required this.teamName,
    required this.joinedAt,
    this.leftAt,
    required this.status,
  });

  factory CareerRecord.fromJson(Map<String, dynamic> json) => _$CareerRecordFromJson(json);
  Map<String, dynamic> toJson() => _$CareerRecordToJson(this);
}

@JsonSerializable()
class PlayerCareer {
  @JsonKey(name: 'player_name')
  final String playerName;
  @JsonKey(name: 'career_history')
  final List<CareerRecord> careerHistory;
  @JsonKey(name: 'total_goals')
  final int totalGoals;
  @JsonKey(name: 'total_assists')
  final int totalAssists;
  final List<String> awards;

  PlayerCareer({
    required this.playerName,
    required this.careerHistory,
    required this.totalGoals,
    required this.totalAssists,
    required this.awards,
  });

  factory PlayerCareer.fromJson(Map<String, dynamic> json) => _$PlayerCareerFromJson(json);
  Map<String, dynamic> toJson() => _$PlayerCareerToJson(this);
}
