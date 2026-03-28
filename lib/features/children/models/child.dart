class Child {
  final String id;
  final String name;
  final int age;
  final String teamName;
  final DateTime? dateOfBirth;
  final String email;
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
    this.dateOfBirth,
    this.email = '',
    this.matchesPlayed = 0,
    this.goals = 0,
    this.assists = 0,
    this.yellowCards = 0,
    this.coachNotes = '',
  });

  factory Child.fromJson(Map<String, dynamic> json) {
    DateTime? dob;
    if (json['date_of_birth'] != null) {
      dob = DateTime.parse(json['date_of_birth']);
    }

    int calculatedAge = json['age'] ?? 0;
    if (dob != null) {
      DateTime today = DateTime.now();
      calculatedAge = today.year - dob.year;
      if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
        calculatedAge--;
      }
    }

    return Child(
      id: json['id'] ?? '',
      name: json['full_name'] ?? json['name'] ?? '',
      age: calculatedAge,
      dateOfBirth: dob,
      email: json['email'] ?? '',
      teamName: json['team_name'] ?? json['teamName'] ?? 'No Team',
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
    'date_of_birth': dateOfBirth?.toIso8601String(),
    'email': email,
    'matchesPlayed': matchesPlayed,
    'goals': goals,
    'assists': assists,
    'yellowCards': yellowCards,
    'coachNotes': coachNotes,
  };
}
