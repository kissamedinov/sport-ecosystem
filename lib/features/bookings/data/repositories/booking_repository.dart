import '../../../../core/api/api_client.dart';
import '../models/booking_models.dart';

class BookingRepository {
  final ApiClient _apiClient;

  BookingRepository(this._apiClient);

  Future<List<FieldSlot>> getFieldSlots(String fieldId) async {
    final response = await _apiClient.get('/fields/$fieldId/slots');
    final List<dynamic> data = response.data;
    return data.map((json) => FieldSlot.fromJson(json)).toList();
  }

  Future<Booking> bookField(String fieldId, String slotId) async {
    final response = await _apiClient.post('/fields/$fieldId/book', data: {
      'slot_id': slotId,
    });
    return Booking.fromJson(response.data);
  }

  Future<List<Booking>> getFieldBookings(String fieldId) async {
    final response = await _apiClient.get('/fields/$fieldId/bookings');
    final List<dynamic> data = response.data;
    return data.map((json) => Booking.fromJson(json)).toList();
  }

  Future<Payment> createPayment(Map<String, dynamic> paymentData) async {
    final response = await _apiClient.post('/payments', data: paymentData);
    return Payment.fromJson(response.data);
  }

  Future<List<Payment>> getUserPayments(String userId) async {
    final response = await _apiClient.get('/users/$userId/payments');
    final List<dynamic> data = response.data;
    return data.map((json) => Payment.fromJson(json)).toList();
  }

  Future<void> confirmPayment(String paymentId) async {
    await _apiClient.post('/payments/$paymentId/confirm');
  }
}
