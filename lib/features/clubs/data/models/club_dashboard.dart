import 'package:json_annotation/json_annotation.dart';
import '../../../academies/data/models/academy.dart';
import '../../../teams/data/models/team.dart';
import 'club.dart';
import 'invitation.dart';
import 'player_info.dart';
import 'child_profile.dart';

part 'club_dashboard.g.dart';

@JsonSerializable()
class ClubDashboard {
  final Club club;
  @JsonKey(defaultValue: [])
  final List<Academy> academies;
  @JsonKey(defaultValue: [])
  final List<Team> teams;
  @JsonKey(defaultValue: [])
  final List<PlayerInfo> players;
  @JsonKey(defaultValue: [])
  final List<PlayerInfo> coaches;
  @JsonKey(defaultValue: [])
  final List<PlayerInfo> managers;
  @JsonKey(name: 'players_count')
  final int playersCount;
  @JsonKey(name: 'coaches_count')
  final int coachesCount;
  @JsonKey(name: 'managers_count', defaultValue: 0)
  final int managersCount;
  @JsonKey(name: 'pending_invitations', defaultValue: [])
  final List<Invitation> pendingInvitations;
  @JsonKey(name: 'child_profiles', defaultValue: [])
  final List<ChildProfile> childProfiles;
  @JsonKey(defaultValue: {})
  final Map<String, dynamic> statistics;

  ClubDashboard({
    required this.club,
    required this.academies,
    required this.teams,
    required this.players,
    required this.coaches,
    required this.managers,
    required this.playersCount,
    required this.coachesCount,
    required this.managersCount,
    required this.pendingInvitations,
    required this.childProfiles,
    required this.statistics,
  });

  factory ClubDashboard.fromJson(Map<String, dynamic> json) => _$ClubDashboardFromJson(json);
  Map<String, dynamic> toJson() => _$ClubDashboardToJson(this);
}
