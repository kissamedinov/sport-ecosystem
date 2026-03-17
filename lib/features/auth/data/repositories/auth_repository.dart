import '../../../../core/api/api_client.dart';
import '../../../../core/services/token_service.dart';
import '../models/user.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final TokenService _tokenService = TokenService();

  AuthRepository(this._apiClient);

  Future<User> login(String email, String password) async {
    // The backend uses a standard JSON payload with UserLogin schema
    final response = await _apiClient.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    final token = response.data['access_token'];
    await _tokenService.saveToken(token);
    // Give storage a moment to persist before next request
    await Future.delayed(const Duration(milliseconds: 100));

    // After login, fetch the actual user profile
    return await getCurrentUser();
  }

  Future<User> getCurrentUser() async {
    final response = await _apiClient.get('/auth/me');
    return User.fromJson(response.data);
  }

  Future<void> register(Map<String, dynamic> userData) async {
    await _apiClient.post('/auth/register', data: userData);
  }

  Future<void> logout() async {
    await _tokenService.deleteTokens();
  }
}
