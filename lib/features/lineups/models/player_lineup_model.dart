class PlayerLineupModel {
  final String id;
  final String name;
  String? position;
  bool isStarting;
  int? jerseyNumber;
  double? posX;
  double? posY;

  PlayerLineupModel({
    required this.id,
    required this.name,
    this.position,
    this.isStarting = false,
    this.jerseyNumber,
    this.posX,
    this.posY,
  });

  Map<String, dynamic> toJson() => {
    'player_id': id,
    'is_starting': isStarting,
    'position': position,
    if (jerseyNumber != null) 'jersey_number': jerseyNumber,
    if (posX != null) 'pos_x': posX,
    if (posY != null) 'pos_y': posY,
  };
}
