import 'package:json_annotation/json_annotation.dart';
import '../../../matches/data/models/match.dart';
import 'player_team.dart';

part 'team.g.dart';

@JsonSerializable()
class Team {
  final String id;
  final String name;
  final String city;
  @JsonKey(name: 'coach_id')
  final String? coachId;
  @JsonKey(name: 'coach_name')
  final String? coachName;
  final int rating;
  @JsonKey(name: 'matches_played')
  final int matchesPlayed;
  final int wins;
  final int draws;
  final int losses;
  @JsonKey(name: 'academy_name')
  final String? academyName;
  @JsonKey(name: 'age_category')
  final String? ageCategory;
  @JsonKey(name: 'birth_year')
  final int? birthYear;
  @JsonKey(name: 'recent_matches', defaultValue: [])
  final List<MatchModel> recentMatches;
  @JsonKey(defaultValue: [])
  final List<String> form;
  @JsonKey(defaultValue: [])
  final List<PlayerTeam> players;
  final String? whatsapp;
  final String? instagram;

  Team({
    required this.id,
    required this.name,
    required this.city,
    this.coachId,
    this.coachName,
    required this.rating,
    required this.matchesPlayed,
    required this.wins,
    required this.draws,
    required this.losses,
    this.academyName,
    this.ageCategory,
    this.birthYear,
    this.recentMatches = const [],
    this.form = const [],
    this.players = const [],
    this.whatsapp,
    this.instagram,
  });

  Team copyWith({
    String? id,
    String? name,
    String? city,
    String? coachId,
    String? coachName,
    int? rating,
    int? matchesPlayed,
    int? wins,
    int? draws,
    int? losses,
    String? academyName,
    String? ageCategory,
    int? birthYear,
    List<MatchModel>? recentMatches,
    List<String>? form,
    List<PlayerTeam>? players,
    String? whatsapp,
    String? instagram,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      coachId: coachId ?? this.coachId,
      coachName: coachName ?? this.coachName,
      rating: rating ?? this.rating,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      wins: wins ?? this.wins,
      draws: draws ?? this.draws,
      losses: losses ?? this.losses,
      academyName: academyName ?? this.academyName,
      ageCategory: ageCategory ?? this.ageCategory,
      birthYear: birthYear ?? this.birthYear,
      recentMatches: recentMatches ?? this.recentMatches,
      form: form ?? this.form,
      players: players ?? this.players,
      whatsapp: whatsapp ?? this.whatsapp,
      instagram: instagram ?? this.instagram,
    );
  }

  factory Team.fromJson(Map<String, dynamic> json) => _$TeamFromJson(json);
  Map<String, dynamic> toJson() => _$TeamToJson(this);
}
