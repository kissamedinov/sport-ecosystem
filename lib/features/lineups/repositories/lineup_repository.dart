import '../../../core/api/api_client.dart';
import '../models/lineup.dart';

class LineupRepository {
  final ApiClient _apiClient = ApiClient();

  Future<MatchLineup?> fetchTeamLineup(String matchId, String teamId) async {
    try {
      final response = await _apiClient.get('/matches/$matchId/lineup/$teamId');
      if (response.statusCode == 200) {
        return MatchLineup.fromJson(response.data);
      }
      return null;
    } catch (e) {
      if (e is ApiExceptions && e.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<List<MatchLineup>> fetchMatchLineups(String matchId) async {
    try {
      final response = await _apiClient.get('/matches/$matchId/lineup');
      if (response.statusCode == 200) {
        final List data = response.data;
        return data.map((json) => MatchLineup.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<void> submitLineup(String matchId, MatchLineup lineupRequest) async {
    try {
      await _apiClient.post(
        '/matches/$matchId/lineup',
        data: lineupRequest.toJson(),
      );
    } catch (e) {
      rethrow;
    }
  }
}
