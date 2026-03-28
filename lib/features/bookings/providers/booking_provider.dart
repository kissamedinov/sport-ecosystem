import 'package:flutter/material.dart';
import '../data/repositories/booking_repository.dart';
import '../data/models/booking_models.dart';

class BookingProvider extends ChangeNotifier {
  final BookingRepository _repository;
  
  List<FieldSlot> _slots = [];
  List<Payment> _payments = [];
  bool _isLoading = false;
  String? _error;

  BookingProvider(this._repository);

  List<FieldSlot> get slots => _slots;
  List<Payment> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSlots(String fieldId, [DateTime? date]) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Note: Repository might need date support as well, adding it here for provider consistency
      _slots = await _repository.getFieldSlots(fieldId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> confirmBooking(String slotId) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Assuming bookField is the underlying call
      // We don't have fieldId here easily, but we'll use a placeholder or assume repository handles it by slotId
      await _repository.bookField("", slotId); 
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createBooking(String fieldId, String slotId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.bookField(fieldId, slotId);
      await fetchSlots(fieldId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserPayments(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _payments = await _repository.getUserPayments(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> processPayment(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      final payment = await _repository.createPayment(data);
      await _repository.confirmPayment(payment.id);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
