import '../../../../core/api/api_client.dart';
import '../models/notification.dart';

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository(this._apiClient);

  Future<List<NotificationModel>> getNotifications({int page = 1, int limit = 20}) async {
    final response = await _apiClient.get('/notifications', queryParameters: {
      'page': page,
      'limit': limit,
    });
    
    final List<dynamic> data = response.data;
    return data.map((json) => NotificationModel.fromJson(json)).toList();
  }

  Future<void> markAsRead(String id) async {
    await _apiClient.patch('/notifications/$id/read');
  }

  Future<int> getUnreadCount() async {
    final response = await _apiClient.get('/notifications/unread-count');
    return response.data['count'] ?? 0;
  }

  Future<List<NotificationModel>> getNotificationsForUser(String userId) async {
    final response = await _apiClient.get('/notifications/user/$userId');
    final List<dynamic> data = response.data;
    return data.map((json) => NotificationModel.fromJson(json)).toList();
  }
}
