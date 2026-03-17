import '../../../../core/api/api_client.dart';
import '../models/field.dart';
import '../models/booking.dart';

class FieldRepository {
  final ApiClient _apiClient;

  FieldRepository(this._apiClient);

  Future<List<Field>> getFields() async {
    final response = await _apiClient.get('/fields');
    final List<dynamic> data = response.data;
    return data.map((json) => Field.fromJson(json)).toList();
  }

  Future<List<Booking>> getFieldBookings(String fieldId) async {
    final response = await _apiClient.get('/fields/$fieldId/bookings');
    final List<dynamic> data = response.data;
    return data.map((json) => Booking.fromJson(json)).toList();
  }

  Future<Booking> createBooking(String fieldId, String startTime, String endTime) async {
    final response = await _apiClient.post('/bookings', data: {
      'field_id': fieldId,
      'start_time': startTime,
      'end_time': endTime,
    });
    return Booking.fromJson(response.data);
  }
}
