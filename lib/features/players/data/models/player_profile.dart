class PlayerTournamentStats {
  final String divisionId;
  final int goals;
  final int assists;
  final int matchesPlayed;
  final int cleanSheets;
  final int yellowCards;
  final int redCards;

  PlayerTournamentStats({
    required this.divisionId,
    required this.goals,
    required this.assists,
    required this.matchesPlayed,
    required this.cleanSheets,
    required this.yellowCards,
    required this.redCards,
  });

  factory PlayerTournamentStats.fromJson(Map<String, dynamic> json) {
    return PlayerTournamentStats(
      divisionId: json['division_id']?.toString() ?? '',
      goals: json['goals'] ?? 0,
      assists: json['assists'] ?? 0,
      matchesPlayed: json['matches_played'] ?? 0,
      cleanSheets: json['clean_sheets'] ?? 0,
      yellowCards: json['yellow_cards'] ?? 0,
      redCards: json['red_cards'] ?? 0,
    );
  }
}

class PlayerAward {
  final String id;
  final String title;
  final String? description;
  final String divisionId;
  final DateTime? createdAt;

  PlayerAward({
    required this.id,
    required this.title,
    this.description,
    required this.divisionId,
    this.createdAt,
  });

  factory PlayerAward.fromJson(Map<String, dynamic> json) {
    return PlayerAward(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      divisionId: json['division_id']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}

class PlayerProfile {
  final String id;
  final String? userId; // Adding this to store the linked user ID
  final String name;
  final String email;
  final String? dateOfBirth;
  final String? profileId;
  final String? preferredPosition;
  final String? dominantFoot;
  final String? height;
  final String? weight;
  final List<PlayerTournamentStats> tournamentStats;
  final List<PlayerAward> awards;

  PlayerProfile({
    required this.id,
    this.userId,
    required this.name,
    required this.email,
    this.dateOfBirth,
    this.profileId,
    this.preferredPosition,
    this.dominantFoot,
    this.height,
    this.weight,
    required this.tournamentStats,
    required this.awards,
  });

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    return PlayerProfile(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      dateOfBirth: json['date_of_birth']?.toString(),
      profileId: json['profile_id']?.toString(),
      preferredPosition: json['preferred_position']?.toString(),
      dominantFoot: json['dominant_foot']?.toString(),
      height: json['height']?.toString(),
      weight: json['weight']?.toString(),
      tournamentStats: (json['tournament_stats'] as List<dynamic>? ?? [])
          .map((s) => PlayerTournamentStats.fromJson(s))
          .toList(),
      awards: (json['awards'] as List<dynamic>? ?? [])
          .map((a) => PlayerAward.fromJson(a))
          .toList(),
    );
  }

  // Aggregate career totals across all tournaments
  int get careerGoals =>
      tournamentStats.fold(0, (sum, s) => sum + s.goals);
  int get careerAssists =>
      tournamentStats.fold(0, (sum, s) => sum + s.assists);
  int get careerMatchesPlayed =>
      tournamentStats.fold(0, (sum, s) => sum + s.matchesPlayed);
  int get careerYellowCards =>
      tournamentStats.fold(0, (sum, s) => sum + s.yellowCards);
  int get careerRedCards =>
      tournamentStats.fold(0, (sum, s) => sum + s.redCards);
}
