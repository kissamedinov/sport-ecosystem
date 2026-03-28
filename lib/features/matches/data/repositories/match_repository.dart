import '../../../../core/api/api_client.dart';
import '../models/match.dart';

class MatchRepository {
  final ApiClient _apiClient;

  MatchRepository(this._apiClient);

  Future<List<MatchModel>> getMatches({String? tournamentId}) async {
    final response = await _apiClient.get('/matches', queryParameters: {
      if (tournamentId != null) 'tournament_id': tournamentId,
    });
    final List<dynamic> data = response.data;
    return data.map((json) => MatchModel.fromJson(json)).toList();
  }

  Future<MatchModel> getMatchById(String id) async {
    final response = await _apiClient.get('/matches/$id');
    return MatchModel.fromJson(response.data);
  }

  Future<void> submitResult(String matchId, Map<String, dynamic> resultData) async {
    await _apiClient.post('/matches/$matchId/submit-result', data: resultData);
  }

  Future<void> finalizeResult(String matchId, Map<String, dynamic> resultData) async {
    await _apiClient.patch('/matches/$matchId/finalize-result', data: resultData);
  }

  Future<void> createMatchEvent(String matchId, Map<String, dynamic> eventData) async {
    await _apiClient.post('/matches/$matchId/events', data: eventData);
  }

  Future<List<dynamic>> getMatchEvents(String matchId) async {
    final response = await _apiClient.get('/matches/$matchId/events');
    return response.data;
  }

  Future<void> createLineup(String matchId, Map<String, dynamic> lineupData) async {
    await _apiClient.post('/matches/$matchId/lineup', data: lineupData);
  }

  Future<List<dynamic>> getMatchLineups(String matchId) async {
    final response = await _apiClient.get('/matches/$matchId/lineup');
    return response.data;
  }

  Future<Map<String, dynamic>> getMatchSheet(String matchId) async {
    final response = await _apiClient.get('/matches/$matchId/sheet');
    return response.data;
  }

  Future<void> submitMatchSheet(String matchId, Map<String, dynamic> sheetData) async {
    await _apiClient.post('/matches/$matchId/sheet', data: sheetData);
  }

  Future<void> assignTournamentAward(String tournamentId, Map<String, dynamic> awardData) async {
    await _apiClient.post('/tournaments/$tournamentId/awards', data: awardData);
  }
}
