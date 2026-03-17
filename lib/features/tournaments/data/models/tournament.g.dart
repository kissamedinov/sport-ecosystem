// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tournament.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Tournament _$TournamentFromJson(Map<String, dynamic> json) => Tournament(
  id: json['id'] as String,
  name: json['name'] as String,
  location: json['location'] as String,
  startDate: json['start_date'] as String,
  endDate: json['end_date'] as String,
  format: json['format'] as String,
  ageCategory: json['age_category'] as String,
  status: json['status'] as String,
  logoUrl: json['logo_url'] as String?,
  teamsCount: (json['teams_count'] as num?)?.toInt(),
  surfaceType: json['surface_type'] as String?,
  seriesName: json['series_name'] as String?,
  numFields: (json['num_fields'] as num?)?.toInt() ?? 1,
  matchHalfDuration: (json['match_half_duration'] as num?)?.toInt() ?? 20,
  halftimeBreakDuration:
      (json['halftime_break_duration'] as num?)?.toInt() ?? 5,
  breakBetweenMatches: (json['break_between_matches'] as num?)?.toInt() ?? 10,
  registrationOpen: json['registration_open'] as String?,
  registrationClose: json['registration_close'] as String?,
  allowedAgeCategories: json['allowed_age_categories'] as String?,
  historyData: json['history_data'] as String?,
  createdBy: json['created_by'] as String?,
);

Map<String, dynamic> _$TournamentToJson(Tournament instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'location': instance.location,
      'start_date': instance.startDate,
      'end_date': instance.endDate,
      'format': instance.format,
      'age_category': instance.ageCategory,
      'logo_url': instance.logoUrl,
      'teams_count': instance.teamsCount,
      'status': instance.status,
      'surface_type': instance.surfaceType,
      'series_name': instance.seriesName,
      'num_fields': instance.numFields,
      'match_half_duration': instance.matchHalfDuration,
      'halftime_break_duration': instance.halftimeBreakDuration,
      'break_between_matches': instance.breakBetweenMatches,
      'registration_open': instance.registrationOpen,
      'registration_close': instance.registrationClose,
      'allowed_age_categories': instance.allowedAgeCategories,
      'history_data': instance.historyData,
      'created_by': instance.createdBy,
    };
