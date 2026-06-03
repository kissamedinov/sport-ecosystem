class AcademyRanking {
  final String id;
  final String academyId;
  final int points;
  final int tournamentsPlayed;
  final int tournamentsWon;
  final String academyName;
  final String academyCity;

  AcademyRanking({
    required this.id,
    required this.academyId,
    required this.points,
    required this.tournamentsPlayed,
    required this.tournamentsWon,
    required this.academyName,
    required this.academyCity,
  });

  factory AcademyRanking.fromJson(Map<String, dynamic> json) {
    final academyJson = json['academy'] as Map<String, dynamic>?;
    return AcademyRanking(
      id: json['id'] as String,
      academyId: json['academy_id'] as String,
      points: json['points'] as int,
      tournamentsPlayed: json['tournaments_played'] as int,
      tournamentsWon: json['tournaments_won'] as int,
      academyName: academyJson?['name'] as String? ?? 'Unknown Academy',
      academyCity: academyJson?['city'] as String? ?? '',
    );
  }
}
