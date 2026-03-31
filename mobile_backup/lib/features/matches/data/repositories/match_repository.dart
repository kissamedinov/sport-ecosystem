import '../../../../core/api/api_client.dart';
import '../models/match.dart';

class MatchRepository {
  final ApiClient _apiClient;

  MatchRepository(this._apiClient);

  Future<List<MatchModel>> getMatches({String? tournamentId}) async {
    final response = await _apiClient.get('/matches', queryParameters: {
      'tournament_id': ?tournamentId,
    });
    final List<dynamic> data = response.data;
    return data.map((json) => MatchModel.fromJson(json)).toList();
  }

  Future<MatchModel> getMatchById(String id) async {
    final response = await _apiClient.get('/matches/$id');
    return MatchModel.fromJson(response.data);
  }
}
