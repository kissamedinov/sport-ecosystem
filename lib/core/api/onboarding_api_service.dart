import 'package:mobile/core/api/api_client.dart';

class OnboardingApiService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getStatus() async {
    final response = await _apiClient.get('/onboarding/status');
    return response.data;
  }

  Future<void> completeOnboarding() async {
    await _apiClient.post('/onboarding/complete', data: {});
  }

  Future<void> setupPlayer(String position) async {
    await _apiClient.post('/onboarding/player-setup', data: {
      'position': position,
    });
  }

  Future<void> addChild(String firstName, String lastName, DateTime dob, String position) async {
    await _apiClient.post('/onboarding/add-child', data: {
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dob.toIso8601String().split('T')[0],
      'position': position,
    });
  }

  Future<void> setupClub(String name, String address, String schedule) async {
    await _apiClient.post('/onboarding/club-setup', data: {
      'name': name,
      'address': address,
      'training_schedule': schedule,
    });
  }

  Future<void> requestCoachAccess() async {
    await _apiClient.post('/onboarding/coach-request', data: {});
  }
}
