import '../../../../core/api/api_client.dart';
import '../models/team.dart';

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
}
