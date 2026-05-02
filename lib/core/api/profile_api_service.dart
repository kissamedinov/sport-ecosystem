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

  /// Fetch dashboard for coach
  Future<Map<String, dynamic>> getCoachDashboard() async {
    final response = await _apiClient.get('/clubs/coach-dashboard');
    return response.data;
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

  /// Fetch referee dashboard
  Future<Map<String, dynamic>> getRefereeDashboard() async {
    final response = await _apiClient.get('/referee/dashboard');
    return response.data;
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _apiClient.patch('/users/me', data: data);
    return response.data;
  }

  /// Fetch list of all referees
  Future<List<Map<String, dynamic>>> getReferees() async {
    final response = await _apiClient.get('/users/referees');
    return (response.data as List).map((e) => e as Map<String, dynamic>).toList();
  }

  /// Link a child by email
  Future<Map<String, dynamic>> linkChildByEmail(String email) async {
    final response = await _apiClient.post('/users/link-child-by-email', data: {'email': email});
    return response.data;
  }
}
