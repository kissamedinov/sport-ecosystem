import '../../../../core/api/api_client.dart';
import '../models/academy.dart';
import '../models/academy_team.dart' hide AcademyPlayer, TrainingSession;
import '../models/crm_models.dart';

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

  Future<List<AcademyCompositePlayer>> getCompositeTrainingPlayers(String sessionId) async {
    final response = await _apiClient.get('/academies/training/$sessionId/players');
    final List<dynamic> data = response.data;
    return data.map((json) => AcademyCompositePlayer.fromJson(json)).toList();
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

  Future<void> recordTrainingAttendance(Map<String, dynamic> attendanceData) async {
    await _apiClient.post('/academies/attendance', data: attendanceData);
  }

  Future<void> submitCoachFeedback(Map<String, dynamic> feedbackData) async {
    await _apiClient.post('/academies/feedback', data: feedbackData);
  }

  // --- CRM Methods ---

  Future<List<TrainingSchedule>> getAcademySchedules(String academyId, {String? teamId}) async {
    final response = await _apiClient.get('/academies/$academyId/schedules', queryParameters: {
      if (teamId != null) 'team_id': teamId,
    });
    final List<dynamic> data = response.data;
    return data.map((json) => TrainingSchedule.fromJson(json)).toList();
  }

  Future<List<TrainingSchedule>> createAcademySchedulesBatch(String academyId, List<Map<String, dynamic>> schedules) async {
    final response = await _apiClient.post('/academies/$academyId/schedules/batch', data: {'schedules': schedules});
    final List<dynamic> data = response.data;
    return data.map((json) => TrainingSchedule.fromJson(json)).toList();
  }

  Future<List<AcademyBranch>> getAcademyBranches(String academyId) async {
    final response = await _apiClient.get('/academies/$academyId/branches');
    final List<dynamic> data = response.data;
    return data.map((json) => AcademyBranch.fromJson(json)).toList();
  }

  Future<AcademyBranch> createAcademyBranch(String academyId, Map<String, dynamic> branchData) async {
    final response = await _apiClient.post('/academies/$academyId/branches', data: branchData);
    return AcademyBranch.fromJson(response.data);
  }

  Future<TrainingSchedule> createAcademySchedule(String academyId, Map<String, dynamic> scheduleData) async {
    final response = await _apiClient.post('/academies/$academyId/schedules', data: scheduleData);
    return TrainingSchedule.fromJson(response.data);
  }

  Future<void> generateSessions(String academyId, DateTime start, DateTime end) async {
    await _apiClient.post('/academies/$academyId/generate-sessions', queryParameters: {
      'start_date': start.toIso8601String().split('T').first,
      'end_date': end.toIso8601String().split('T').first,
    });
  }

  Future<AcademyTeamPlayer> reassignPlayerTeam(String playerProfileId, String targetTeamId) async {
    final response = await _apiClient.patch('/academies/players/$playerProfileId/team', queryParameters: {
      'target_team_id': targetTeamId,
    });
    return AcademyTeamPlayer.fromJson(response.data);
  }

  Future<AcademyBillingConfig?> getBillingConfig(String academyId) async {
    try {
      final response = await _apiClient.get('/academies/$academyId/billing/config');
      if (response.data == null) return null;
      return AcademyBillingConfig.fromJson(response.data);
    } catch (_) {
      return null;
    }
  }

  Future<AcademyBillingConfig> updateBillingConfig(String academyId, Map<String, dynamic> configData) async {
    final response = await _apiClient.put('/academies/$academyId/billing/config', data: configData);
    return AcademyBillingConfig.fromJson(response.data);
  }

  Future<BillingSummary> getPlayerBillingReport(String academyId, String playerId, int month, int year) async {
    final response = await _apiClient.get('/academies/$academyId/billing/report/$playerId', queryParameters: {
      'month': month,
      'year': year,
    });
    return BillingSummary.fromJson(response.data);
  }
}
