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
  final String coachId;
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
    required this.coachId,
    required this.rating,
    @JsonKey(name: 'matches_played')
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

  factory Team.fromJson(Map<String, dynamic> json) => _$TeamFromJson(json);
  Map<String, dynamic> toJson() => _$TeamToJson(this);
}
