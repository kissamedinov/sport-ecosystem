import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../models/media_item.dart';

class MediaRepository {
  final ApiClient _apiClient;

  MediaRepository(this._apiClient);

  Future<List<MediaItem>> getUserMedia(String userId) async {
    final response = await _apiClient.get('/media/users/$userId');
    final List<dynamic> data = response.data;
    return data.map((json) => MediaItem.fromJson(json)).toList();
  }

  Future<List<MediaItem>> getClubMedia(String clubId) async {
    final response = await _apiClient.get('/media/clubs/$clubId');
    final List<dynamic> data = response.data;
    return data.map((json) => MediaItem.fromJson(json)).toList();
  }

  Future<List<MediaItem>> getTournamentMedia(String tournamentId) async {
    final response = await _apiClient.get('/media/tournaments/$tournamentId');
    final List<dynamic> data = response.data;
    return data.map((json) => MediaItem.fromJson(json)).toList();
  }

  Future<MediaItem> uploadMedia({
    required File file,
    String? title,
    String? description,
    String? clubId,
    String? tournamentId,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (clubId != null) 'club_id': clubId,
      if (tournamentId != null) 'tournament_id': tournamentId,
    });

    // Use ApiClient's post method which handles the Dio call
    final response = await _apiClient.post(
      '/media/upload',
      data: formData,
    );
    
    return MediaItem.fromJson(response.data);
  }

  Future<void> deleteMedia(String mediaId) async {
    await _apiClient.delete('/media/$mediaId');
  }

  Future<MediaItem> updateMedia(String mediaId, Map<String, dynamic> updateData) async {
    final response = await _apiClient.patch('/media/$mediaId', data: updateData);
    return MediaItem.fromJson(response.data);
  }
}
