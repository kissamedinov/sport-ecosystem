import 'package:flutter/material.dart';
import '../data/repositories/field_repository.dart';
import '../data/models/field.dart';
import '../data/models/booking.dart';

class BookingProvider extends ChangeNotifier {
  final FieldRepository _repository;
  List<Field> _fields = [];
  final List<Booking> _myBookings = [];
  final List<Booking> _ownerBookings = [];
  bool _isLoading = false;
  String? _error;

  BookingProvider(this._repository);

  List<Field> get fields => _fields;
  List<Booking> get myBookings => _myBookings;
  List<Booking> get ownerBookings => _ownerBookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchFields() async {
    _setLoading(true);
    _error = null;
    try {
      _fields = await _repository.getFields();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchMyBookings() async {
    _setLoading(true);
    _error = null;
    try {
      final bookings = await _repository.getMyBookings();
      _myBookings.clear();
      _myBookings.addAll(bookings);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchOwnerBookings(String userId) async {
    _setLoading(true);
    _error = null;
    try {
      final List<Booking> allBookings = [];
      var ownerFields = _fields.where((f) => f.ownerId == userId).toList();
      if (ownerFields.isEmpty) {
        ownerFields = _fields;
      }
      for (final field in ownerFields) {
        if (field.id.startsWith('field-')) continue;
        try {
          final bookings = await _repository.getFieldBookings(field.id);
          allBookings.addAll(bookings);
        } catch (e) {
          // ignore or log
        }
      }
      _ownerBookings.clear();
      _ownerBookings.addAll(allBookings);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> bookField(String fieldId, String start, String end) async {
    _setLoading(true);
    _error = null;
    try {
      await _repository.createBooking(fieldId, start, end);
      await fetchMyBookings();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    _setLoading(true);
    _error = null;
    try {
      await _repository.cancelBooking(bookingId);
      await fetchMyBookings();
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> generateFieldSlots(String fieldId, Map<String, dynamic> data) async {
    _setLoading(true);
    _error = null;
    try {
      await _repository.generateSlots(fieldId, data);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
