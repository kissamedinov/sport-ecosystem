import '../../../../core/api/api_client.dart';
import '../../models/child.dart';

class ChildRepository {
  final ApiClient _apiClient;

  ChildRepository(this._apiClient);

  Future<List<Child>> getMyChildren() async {
    final response = await _apiClient.get('/users/my-children');
    final List<dynamic> data = response.data;
    return data.map((json) => Child.fromJson(json)).toList();
  }

  Future<List<Map<String, dynamic>>> getChildActivities(String childId) async {
    final response = await _apiClient.get('/stats/matches', queryParameters: {'player_id': childId});
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<Map<String, dynamic>>> getChildAwards(String childId) async {
    final response = await _apiClient.get('/tournaments/player/$childId/awards');
    return List<Map<String, dynamic>>.from(response.data);
  }
}
