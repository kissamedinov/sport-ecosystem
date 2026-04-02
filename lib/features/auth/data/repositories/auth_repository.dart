import '../../../../core/api/api_client.dart';
import '../../../../core/services/token_service.dart';
import '../models/user.dart';
import 'dart:io';

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

  Future<List<dynamic>> getMyChildren() async {
    final response = await _apiClient.get('/users/my-children');
    return response.data;
  }

  Future<void> linkChild(String childId) async {
    await _apiClient.post('/users/link-child/$childId');
  }

  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final response = await _apiClient.get('/users/$userId/profile');
    return response.data;
  }

  Future<List<dynamic>> getParentRequests() async {
    final response = await _apiClient.get('/users/parent-requests');
    return response.data;
  }

  Future<void> acceptParentRequest(String requestId) async {
    await _apiClient.post('/users/parent-requests/$requestId/accept');
  }

  Future<void> rejectParentRequest(String requestId) async {
    await _apiClient.post('/users/parent-requests/$requestId/reject');
  }

  Future<void> createChildAccount(Map<String, dynamic> data) async {
    await _apiClient.post('/users/create-child', data: data);
  }

  Future<void> linkChildByEmail(String email) async {
    await _apiClient.post('/users/link-child-by-email', data: {'email': email});
  }

  Future<List<dynamic>> getMyParents() async {
    final response = await _apiClient.get('/users/parents');
    return response.data;
  }

  Future<User> updateProfile(Map<String, dynamic> data) async {
    final response = await _apiClient.patch('/users/me', data: data);
    return User.fromJson(response.data);
  }

  Future<User> updateUserProfile(String userId, Map<String, dynamic> data) async {
    final response = await _apiClient.patch('/users/$userId', data: data);
    return User.fromJson(response.data);
  }

  Future<String> uploadAvatar(String filePath) async {
    final file = File(filePath);
    final response = await _apiClient.multipartPost(
      '/media/upload', 
      file, 
      'AVATAR', 
      extraData: {'user_id': (await getCurrentUser()).id},
    );
    return response.data['url'];
  }
}
