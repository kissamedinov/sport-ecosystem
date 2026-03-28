import '../../../../core/api/api_client.dart';

class AdminRepository {
  final ApiClient _apiClient;

  AdminRepository(this._apiClient);

  Future<List<dynamic>> getClubRequests() async {
    final response = await _apiClient.get('/clubs/admin/requests');
    return response.data;
  }

  Future<void> approveClubRequest(String requestId) async {
    await _apiClient.post('/clubs/admin/requests/$requestId/approve');
  }

  Future<void> rejectClubRequest(String requestId) async {
    await _apiClient.post('/clubs/admin/requests/$requestId/reject');
  }

  // Add more admin methods as needed (e.g., tournament series management)
  Future<void> createTournamentSeries(Map<String, dynamic> seriesData) async {
    await _apiClient.post('/tournaments/series', data: seriesData);
  }
}
