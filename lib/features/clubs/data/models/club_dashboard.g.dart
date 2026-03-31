// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'club_dashboard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClubDashboard _$ClubDashboardFromJson(Map<String, dynamic> json) =>
    ClubDashboard(
      club: Club.fromJson(json['club'] as Map<String, dynamic>),
      academies:
          (json['academies'] as List<dynamic>?)
              ?.map((e) => Academy.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      teams:
          (json['teams'] as List<dynamic>?)
              ?.map((e) => Team.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      players:
          (json['players'] as List<dynamic>?)
              ?.map((e) => PlayerInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      coaches:
          (json['coaches'] as List<dynamic>?)
              ?.map((e) => PlayerInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      managers:
          (json['managers'] as List<dynamic>?)
              ?.map((e) => PlayerInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      playersCount: (json['players_count'] as num).toInt(),
      coachesCount: (json['coaches_count'] as num).toInt(),
      managersCount: (json['managers_count'] as num?)?.toInt() ?? 0,
      pendingInvitations:
          (json['pending_invitations'] as List<dynamic>?)
              ?.map((e) => Invitation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      childProfiles:
          (json['child_profiles'] as List<dynamic>?)
              ?.map((e) => ChildProfile.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      statistics: json['statistics'] as Map<String, dynamic>? ?? {},
    );

Map<String, dynamic> _$ClubDashboardToJson(ClubDashboard instance) =>
    <String, dynamic>{
      'club': instance.club,
      'academies': instance.academies,
      'teams': instance.teams,
      'players': instance.players,
      'coaches': instance.coaches,
      'managers': instance.managers,
      'players_count': instance.playersCount,
      'coaches_count': instance.coachesCount,
      'managers_count': instance.managersCount,
      'pending_invitations': instance.pendingInvitations,
      'child_profiles': instance.childProfiles,
      'statistics': instance.statistics,
    };
