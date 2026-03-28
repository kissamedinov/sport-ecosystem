import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/features/clubs/data/models/child_profile.dart';
import 'package:mobile/features/clubs/data/models/club_dashboard.dart';
import 'package:mobile/features/teams/data/models/team.dart';
import 'package:mobile/features/matches/data/models/match.dart';

class ProfileApiService {
  final ApiClient _apiClient = ApiClient();

  /// Fetch profiles for a parent's children
  Future<List<ChildProfile>> getChildProfiles() async {
    final response = await _apiClient.get('/child-profiles/me');
    return (response.data as List).map((e) => ChildProfile.fromJson(e)).toList();
  }

  /// Fetch dashboard for club owner
  Future<ClubDashboard> getClubDashboard() async {
    final response = await _apiClient.get('/clubs/dashboard');
    return ClubDashboard.fromJson(response.data);
  }

  /// Fetch managed teams for coach/manager
  Future<List<Team>> getManagedTeams() async {
    final response = await _apiClient.get('/teams/managed/me');
    return (response.data as List).map((e) => Team.fromJson(e)).toList();
  }

  /// Fetch recent matches for specific context (player/team)
  Future<List<MatchModel>> getRecentMatches() async {
    final response = await _apiClient.get('/matches/recent/me');
    return (response.data as List).map((e) => MatchModel.fromJson(e)).toList();
  }

  /// Fetch upcoming matches of children for parents
  Future<List<MatchModel>> getChildrenUpcomingMatches() async {
    final response = await _apiClient.get('/matches/upcoming/children');
    return (response.data as List).map((e) => MatchModel.fromJson(e)).toList();
  }
}
