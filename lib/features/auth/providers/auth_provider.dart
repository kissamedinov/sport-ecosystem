import 'package:flutter/material.dart';
import '../data/repositories/auth_repository.dart';
import '../data/models/user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  User? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._repository);

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> tryAutoLogin() async {
    try {
      _user = await _repository.getCurrentUser();
      notifyListeners();
    } catch (_) {
      _user = null;
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      _user = await _repository.login(email, password);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    _setLoading(true);
    _error = null;
    try {
      await _repository.register(userData);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _user = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
