import 'package:flutter/material.dart';
import '../data/repositories/admin_repository.dart';

class AdminProvider extends ChangeNotifier {
  final AdminRepository _repository;
  List<dynamic> _requests = [];
  bool _isLoading = false;
  String? _error;

  AdminProvider(this._repository);

  List<dynamic> get requests => _requests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchClubRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _requests = await _repository.getClubRequests();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveRequest(String id) async {
    try {
      await _repository.approveClubRequest(id);
      await fetchClubRequests();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectRequest(String id) async {
    try {
      await _repository.rejectClubRequest(id);
      await fetchClubRequests();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
