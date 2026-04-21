import '../../../auth/data/models/user.dart';

class PlayerTeam {
  final String id;
  final String teamId;
  final String playerId;
  final DateTime joinedAt;
  final User? player;

  final String? joinStatus;
  final String? childProfileId;

  PlayerTeam({
    required this.id,
    required this.teamId,
    required this.playerId,
    required this.joinedAt,
    this.player,
    this.joinStatus,
    this.childProfileId,
  });

  factory PlayerTeam.fromJson(Map<String, dynamic> json) {
    return PlayerTeam(
      id: json['id']?.toString() ?? '',
      teamId: json['team_id']?.toString() ?? '',
      playerId: json['player_id']?.toString() ?? '',
      joinedAt: json['joined_at'] != null 
          ? DateTime.parse(json['joined_at']) 
          : DateTime.now(),
      player: json['player'] != null ? User.fromJson(json['player']) : null,
      joinStatus: json['join_status']?.toString(),
      childProfileId: json['child_profile_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'team_id': teamId,
    'player_id': playerId,
    'joined_at': joinedAt.toIso8601String(),
    'player': player?.toJson(),
    'join_status': joinStatus,
    'child_profile_id': childProfileId,
  };
}
