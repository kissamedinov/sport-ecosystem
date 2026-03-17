import 'package:json_annotation/json_annotation.dart';

part 'tournament.g.dart';

@JsonSerializable()
class Tournament {
  final String id;
  final String name;
  final String location;
  @JsonKey(name: 'start_date')
  final String startDate;
  @JsonKey(name: 'end_date')
  final String endDate;
  final String format;
  @JsonKey(name: 'age_category')
  final String ageCategory;
  @JsonKey(name: 'logo_url')
  final String? logoUrl;
  @JsonKey(name: 'teams_count')
  final int? teamsCount;
  final String status;
  
  // New fields for Details & History
  @JsonKey(name: 'surface_type')
  final String? surfaceType;
  @JsonKey(name: 'series_name')
  final String? seriesName;
  @JsonKey(name: 'num_fields')
  final int numFields;
  @JsonKey(name: 'match_half_duration')
  final int matchHalfDuration;
  @JsonKey(name: 'halftime_break_duration')
  final int halftimeBreakDuration;
  @JsonKey(name: 'break_between_matches')
  final int breakBetweenMatches;
  @JsonKey(name: 'registration_open')
  final String? registrationOpen;
  @JsonKey(name: 'registration_close')
  final String? registrationClose;
  @JsonKey(name: 'allowed_age_categories')
  final String? allowedAgeCategories;
  @JsonKey(name: 'history_data')
  final String? historyData;
  @JsonKey(name: 'created_by')
  final String? createdBy;

  Tournament({
    required this.id,
    required this.name,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.format,
    required this.ageCategory,
    required this.status,
    this.logoUrl,
    this.teamsCount,
    this.surfaceType,
    this.seriesName,
    this.numFields = 1,
    this.matchHalfDuration = 20,
    this.halftimeBreakDuration = 5,
    this.breakBetweenMatches = 10,
    this.registrationOpen,
    this.registrationClose,
    this.allowedAgeCategories,
    this.historyData,
    this.createdBy,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) => _$TournamentFromJson(json);
  Map<String, dynamic> toJson() => _$TournamentToJson(this);
}
