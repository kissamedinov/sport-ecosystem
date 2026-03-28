class PlayerLineupModel {
  final String id;
  final String name;
  String? position;
  bool isStarting;

  PlayerLineupModel({
    required this.id,
    required this.name,
    this.position,
    this.isStarting = false,
  });

  Map<String, dynamic> toJson() => {
    'player_id': id,
    'is_starting': isStarting,
    'position': position,
  };
}
