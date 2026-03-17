import '../../../../core/api/api_client.dart';
import '../models/player_profile.dart';

class PlayerRepository {
  final ApiClient _apiClient;

  PlayerRepository(this._apiClient);

  Future<PlayerProfile> getPlayerProfile(String userId) async {
    final response = await _apiClient.get('/users/$userId/profile');
    return PlayerProfile.fromJson(response.data);
  }
}
