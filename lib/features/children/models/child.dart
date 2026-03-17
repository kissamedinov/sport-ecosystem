class Child {
  final String id;
  final String name;
  final int age;
  final String teamName;
  final int matchesPlayed;
  final int goals;
  final int assists;
  final int yellowCards;
  final String coachNotes;

  Child({
    required this.id,
    required this.name,
    required this.age,
    required this.teamName,
    this.matchesPlayed = 0,
    this.goals = 0,
    this.assists = 0,
    this.yellowCards = 0,
    this.coachNotes = '',
  });

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      teamName: json['teamName'] ?? 'No Team',
      matchesPlayed: json['matchesPlayed'] ?? 0,
      goals: json['goals'] ?? 0,
      assists: json['assists'] ?? 0,
      yellowCards: json['yellowCards'] ?? 0,
      coachNotes: json['coachNotes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'age': age,
    'teamName': teamName,
    'matchesPlayed': matchesPlayed,
    'goals': goals,
    'assists': assists,
    'yellowCards': yellowCards,
    'coachNotes': coachNotes,
  };
}
