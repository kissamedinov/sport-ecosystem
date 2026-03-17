import '../../../../core/api/api_client.dart';
import '../models/academy.dart';
import '../models/academy_team.dart';

class AcademyRepository {
  final ApiClient _apiClient;

  AcademyRepository(this._apiClient);

  Future<List<Academy>> getAcademies({int page = 1, int limit = 10}) async {
    final response = await _apiClient.get('/academies', queryParameters: {
      'page': page,
      'limit': limit,
    });
    final List<dynamic> data = response.data;
    return data.map((json) => Academy.fromJson(json)).toList();
  }

  Future<Academy> getAcademyById(String id) async {
    final response = await _apiClient.get('/academies/$id');
    return Academy.fromJson(response.data);
  }

  Future<Academy?> getMyAcademy() async {
    final response = await _apiClient.get('/academies/mine');
    if (response.data == null) return null;
    return Academy.fromJson(response.data);
  }

  Future<List<AcademyTeam>> getAcademyTeams(String academyId) async {
    final response = await _apiClient.get('/academies/$academyId/teams');
    final List<dynamic> data = response.data;
    return data.map((json) => AcademyTeam.fromJson(json)).toList();
  }

  Future<AcademyTeam> createAcademyTeam(String academyId, Map<String, dynamic> teamData) async {
    final response = await _apiClient.post('/academies/$academyId/teams', data: teamData);
    return AcademyTeam.fromJson(response.data);
  }

  Future<List<AcademyPlayer>> getAcademyPlayers(String academyId) async {
    final response = await _apiClient.get('/academies/$academyId/players');
    final List<dynamic> data = response.data;
    return data.map((json) => AcademyPlayer.fromJson(json)).toList();
  }

  Future<AcademyPlayer> addPlayerToAcademy(String academyId, Map<String, dynamic> playerData) async {
    final response = await _apiClient.post('/academies/$academyId/players', data: playerData);
    return AcademyPlayer.fromJson(response.data);
  }

  Future<List<TrainingSession>> getTrainingSessions(String academyId, {String? teamId}) async {
    final response = await _apiClient.get('/academies/$academyId/training', queryParameters: {
      if (teamId != null) 'team_id': teamId,
    });
    final List<dynamic> data = response.data;
    return data.map((json) => TrainingSession.fromJson(json)).toList();
  }

  Future<TrainingSession> createTrainingSession(String academyId, Map<String, dynamic> sessionData) async {
    final response = await _apiClient.post('/academies/$academyId/training', data: sessionData);
    return TrainingSession.fromJson(response.data);
  }
  Future<List<AcademyTeamPlayer>> getTeamPlayers(String teamId) async {
    final response = await _apiClient.get('/academies/teams/$teamId/players');
    final List<dynamic> data = response.data;
    return data.map((json) => AcademyTeamPlayer.fromJson(json)).toList();
  }

  Future<AcademyTeamPlayer> addPlayerToTeam(String teamId, Map<String, dynamic> playerData) async {
    final response = await _apiClient.post('/academies/teams/$teamId/players', data: playerData);
    return AcademyTeamPlayer.fromJson(response.data);
  }
}
