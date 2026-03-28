enum EventType {
  GOAL,
  ASSIST,
  SAVE,
  YELLOW_CARD,
  RED_CARD,
  PENALTY_GOAL,
  SUBSTITUTE,
}

class MatchEvent {
  final String id;
  final String matchId;
  final String? teamId;
  final String? playerId;
  final String? childProfileId;
  final EventType eventType;
  final int minute;
  final String createdAt;

  MatchEvent({
    required this.id,
    required this.matchId,
    this.teamId,
    this.playerId,
    this.childProfileId,
    required this.eventType,
    required this.minute,
    required this.createdAt,
  });

  factory MatchEvent.fromJson(Map<String, dynamic> json) {
    return MatchEvent(
      id: json['id'],
      matchId: json['match_id'],
      teamId: json['team_id'],
      playerId: json['player_id'],
      childProfileId: json['child_profile_id'],
      eventType: EventType.values.firstWhere(
        (e) => e.name == json['event_type'],
        orElse: () => EventType.GOAL,
      ),
      minute: json['minute'],
      createdAt: json['created_at'],
    );
  }
}
