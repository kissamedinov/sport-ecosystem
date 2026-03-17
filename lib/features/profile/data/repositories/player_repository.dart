import '../../../../core/api/api_client.dart';
import '../models/player.dart';

class PlayerRepository {
  final ApiClient _apiClient;

  PlayerRepository(this._apiClient);

  Future<List<Player>> getPlayers({int page = 1, int limit = 10}) async {
    final response = await _apiClient.get('/search', queryParameters: {
      'type': 'PLAYER',
      'page': page,
      'limit': limit,
    });
    final List<dynamic> data = response.data;
    return data.map((json) => Player.fromJson(json)).toList();
  }

  Future<Player> getPlayerById(String id) async {
    final response = await _apiClient.get('/users/$id'); // Players are users with roles
    return Player.fromJson(response.data);
  }
}
