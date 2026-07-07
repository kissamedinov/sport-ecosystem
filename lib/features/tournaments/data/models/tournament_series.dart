import 'package:mobile/features/tournaments/data/models/tournament.dart';

class TournamentSeries {
  final String id;
  final String name;
  final String city;
  final String? description;
  final String? logoUrl;
  final String organizerId;
  final DateTime createdAt;

  TournamentSeries({
    required this.id,
    required this.name,
    required this.city,
    this.description,
    this.logoUrl,
    required this.organizerId,
    required this.createdAt,
  });

  factory TournamentSeries.fromJson(Map<String, dynamic> json) {
    return TournamentSeries(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      organizerId: json['organizer_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class SeriesChampionInfo {
  final String tournamentId;
  final String tournamentName;
  final String divisionId;
  final String divisionName;
  final String teamId;
  final String teamName;
  final int? year;
  final String? season;

  SeriesChampionInfo({
    required this.tournamentId,
    required this.tournamentName,
    required this.divisionId,
    required this.divisionName,
    required this.teamId,
    required this.teamName,
    this.year,
    this.season,
  });

  factory SeriesChampionInfo.fromJson(Map<String, dynamic> json) {
    return SeriesChampionInfo(
      tournamentId: json['tournament_id'] as String,
      tournamentName: json['tournament_name'] as String,
      divisionId: json['division_id'] as String,
      divisionName: json['division_name'] as String,
      teamId: json['team_id'] as String,
      teamName: json['team_name'] as String,
      year: json['year'] as int?,
      season: json['season'] as String?,
    );
  }
}

class SeriesTeamLeaderboardEntry {
  final String teamId;
  final String teamName;
  final String? logoUrl;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;

  SeriesTeamLeaderboardEntry({
    required this.teamId,
    required this.teamName,
    this.logoUrl,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
  });

  factory SeriesTeamLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return SeriesTeamLeaderboardEntry(
      teamId: json['team_id'] as String,
      teamName: json['team_name'] as String,
      logoUrl: json['logo_url'] as String?,
      played: json['played'] as int,
      wins: json['wins'] as int,
      draws: json['draws'] as int,
      losses: json['losses'] as int,
      goalsFor: json['goals_for'] as int,
      goalsAgainst: json['goals_against'] as int,
      goalDifference: json['goal_difference'] as int,
      points: json['points'] as int,
    );
  }
}

class SeriesPlayerStatsEntry {
  final String playerId;
  final String playerName;
  final String? avatarUrl;
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;

  SeriesPlayerStatsEntry({
    required this.playerId,
    required this.playerName,
    this.avatarUrl,
    required this.goals,
    required this.assists,
    required this.yellowCards,
    required this.redCards,
  });

  factory SeriesPlayerStatsEntry.fromJson(Map<String, dynamic> json) {
    return SeriesPlayerStatsEntry(
      playerId: json['player_id'] as String,
      playerName: json['player_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      goals: json['goals'] as int,
      assists: json['assists'] as int,
      yellowCards: json['yellow_cards'] as int,
      redCards: json['red_cards'] as int,
    );
  }
}

class TournamentSeriesDetail {
  final String id;
  final String name;
  final String city;
  final String? description;
  final String? logoUrl;
  final String organizerId;
  final DateTime createdAt;
  final List<Tournament> editions;
  final List<SeriesChampionInfo> champions;
  final List<SeriesTeamLeaderboardEntry> teamLeaderboard;
  final List<SeriesPlayerStatsEntry> playerLeaderboard;

  TournamentSeriesDetail({
    required this.id,
    required this.name,
    required this.city,
    this.description,
    this.logoUrl,
    required this.organizerId,
    required this.createdAt,
    required this.editions,
    required this.champions,
    required this.teamLeaderboard,
    required this.playerLeaderboard,
  });

  factory TournamentSeriesDetail.fromJson(Map<String, dynamic> json) {
    return TournamentSeriesDetail(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      organizerId: json['organizer_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      editions: (json['editions'] as List<dynamic>?)
              ?.map((e) => Tournament.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      champions: (json['champions'] as List<dynamic>?)
              ?.map((e) => SeriesChampionInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      teamLeaderboard: (json['team_leaderboard'] as List<dynamic>?)
              ?.map((e) => SeriesTeamLeaderboardEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      playerLeaderboard: (json['player_leaderboard'] as List<dynamic>?)
              ?.map((e) => SeriesPlayerStatsEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
