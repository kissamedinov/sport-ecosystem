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
  final List<Academy> academies;
  final List<Team> teams;
  final List<PlayerInfo> players;
  final List<PlayerInfo> coaches;
  @JsonKey(name: 'players_count')
  final int playersCount;
  @JsonKey(name: 'coaches_count')
  final int coachesCount;
  @JsonKey(name: 'pending_invitations')
  final List<Invitation> pendingInvitations;
  @JsonKey(name: 'child_profiles')
  final List<ChildProfile> childProfiles;
  final Map<String, dynamic> statistics;

  ClubDashboard({
    required this.club,
    required this.academies,
    required this.teams,
    required this.players,
    required this.coaches,
    required this.playersCount,
    required this.coachesCount,
    required this.pendingInvitations,
    required this.childProfiles,
    required this.statistics,
  });

  factory ClubDashboard.fromJson(Map<String, dynamic> json) => _$ClubDashboardFromJson(json);
  Map<String, dynamic> toJson() => _$ClubDashboardToJson(this);
}
