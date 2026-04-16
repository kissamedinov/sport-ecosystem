import 'package:json_annotation/json_annotation.dart';

part 'academy.g.dart';

@JsonSerializable()
class Academy {
  final String id;
  final String name;
  final String city;
  final String address;
  @JsonKey(name: 'club_id')
  final String? clubId;
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
    this.clubId,
    required this.ownerId,
    this.logoUrl,
    this.teamsCount,
    this.playersCount,
  });

  factory Academy.fromJson(Map<String, dynamic> json) => _$AcademyFromJson(json);
  Map<String, dynamic> toJson() => _$AcademyToJson(this);
}

class AcademyPlayer {
  final String id;
  final String fullName;
  final String? position;
  final String status;
  @JsonKey(name: 'player_profile_id')
  final String? playerProfileId;

  AcademyPlayer({
    required this.id,
    required this.fullName,
    this.position,
    required this.status,
    this.playerProfileId,
  });

  factory AcademyPlayer.fromJson(Map<String, dynamic> json) {
    return AcademyPlayer(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      position: json['position'] as String?,
      status: json['status'] as String,
      playerProfileId: json['player_profile_id'] as String?,
    );
  }
}

class TrainingSession {
  final String id;
  final String title;
  final String scheduledAt;
  final String? topic;
  final String? description;
  @JsonKey(name: 'team_id')
  final String teamId;
  final String? date;
  @JsonKey(name: 'start_time')
  final String? startTime;
  @JsonKey(name: 'end_time')
  final String? endTime;

  TrainingSession({
    required this.id,
    required this.title,
    required this.scheduledAt,
    this.topic,
    this.description,
    required this.teamId,
    this.date,
    this.startTime,
    this.endTime,
  });

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    return TrainingSession(
      id: json['id'] as String,
      title: json['title'] as String,
      scheduledAt: json['scheduled_at'] as String,
      topic: json['topic'] as String?,
      description: json['description'] as String?,
      teamId: json['team_id'] as String,
      date: json['date'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
    );
  }
}
