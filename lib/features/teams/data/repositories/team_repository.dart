import '../../../../core/api/api_client.dart';
import '../models/team.dart';
import '../models/player_team.dart';

class TeamRepository {
  final ApiClient _apiClient;

  TeamRepository(this._apiClient);

  Future<List<Team>> getTeams({int page = 1, int limit = 10}) async {
    final response = await _apiClient.get('/teams', queryParameters: {
      'page': page,
      'limit': limit,
    });
    final List<dynamic> data = response.data;
    return data.map((json) => Team.fromJson(json)).toList();
  }

  Future<List<Team>> getMyTeams() async {
    final response = await _apiClient.get('/teams/mine');
    final List<dynamic> data = response.data;
    return data.map((json) => Team.fromJson(json)).toList();
  }

  Future<Team> getTeamById(String id) async {
    final response = await _apiClient.get('/teams/$id');
    return Team.fromJson(response.data);
  }

  Future<List<Team>> getTeamRankings() async {
    final response = await _apiClient.get('/teams/rankings');
    final List<dynamic> data = response.data;
    return data.map((json) => Team.fromJson(json)).toList();
  }

  Future<PlayerTeam> requestJoinTeam(String teamId, {String? childProfileId}) async {
    final response = await _apiClient.post(
      '/teams/$teamId/join',
      data: {'child_profile_id': childProfileId},
    );
    return PlayerTeam.fromJson(response.data);
  }

  Future<PlayerTeam> approveJoinRequest(String teamId, String requestId) async {
    final response = await _apiClient.patch('/teams/$teamId/join-request/$requestId/approve');
    return PlayerTeam.fromJson(response.data);
  }

  Future<PlayerTeam> rejectJoinRequest(String teamId, String requestId) async {
    final response = await _apiClient.patch('/teams/$teamId/join-request/$requestId/reject');
    return PlayerTeam.fromJson(response.data);
  }

  Future<Team> updateTeam(String teamId, Map<String, dynamic> data) async {
    final response = await _apiClient.patch('/teams/$teamId', data: data);
    return Team.fromJson(response.data);
  }
}
