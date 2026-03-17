import 'package:flutter/material.dart';
import '../data/repositories/field_repository.dart';
import '../data/models/field.dart';
import '../data/models/booking.dart';

class BookingProvider extends ChangeNotifier {
  final FieldRepository _repository;
  List<Field> _fields = [];
  List<Booking> _myBookings = [];
  bool _isLoading = false;
  String? _error;

  BookingProvider(this._repository);

  List<Field> get fields => _fields;
  List<Booking> get myBookings => _myBookings;
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

  Future<void> bookField(String fieldId, String start, String end) async {
    _setLoading(true);
    _error = null;
    try {
      final booking = await _repository.createBooking(fieldId, start, end);
      _myBookings.add(booking);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
