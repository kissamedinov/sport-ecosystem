import 'package:flutter/material.dart';
import 'package:mobile/core/services/token_service.dart';
import '../data/repositories/auth_repository.dart';
import '../data/models/user.dart';
import 'dart:developer' as dev;

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  final TokenService _tokenService = TokenService();
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isOnboardingCompletedLocally = false;
  List<dynamic> _parentRequests = [];
  List<dynamic> _myParents = [];

  AuthProvider(this._repository);

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic> get parentRequests => _parentRequests;
  List<dynamic> get myParents => _myParents;
  bool get isAuthenticated => _user != null;
  bool get isOnboardingCompletedLocally => _isOnboardingCompletedLocally;

  Future<void> checkAuthStatus() async {
    dev.log('AuthProvider: Checking auth status...', name: 'auth');
    try {
      _user = await _repository.getCurrentUser();
      if (_user != null) {
        dev.log('AuthProvider: User found: ${_user!.email}, Onboarding: ${_user!.onboardingCompleted}', name: 'auth');
        await _tokenService.setOnboardingCompleted(_user!.onboardingCompleted);
        _isOnboardingCompletedLocally = _user!.onboardingCompleted;
      }
      notifyListeners();
    } catch (e) {
      dev.log('AuthProvider: No user or error: $e', name: 'auth');
      _user = null;
      _isOnboardingCompletedLocally = await _tokenService.isOnboardingCompleted();
      notifyListeners();
    }
  }

  Future<void> tryAutoLogin() => checkAuthStatus();

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;
    dev.log('AuthProvider: Attempting login for $email', name: 'auth');
    try {
      _user = await _repository.login(email, password);
      if (_user != null) {
        dev.log('AuthProvider: Login successful, Onboarding: ${_user!.onboardingCompleted}', name: 'auth');
        await _tokenService.setOnboardingCompleted(_user!.onboardingCompleted);
        _isOnboardingCompletedLocally = _user!.onboardingCompleted;
      }
      return true;
    } catch (e) {
      dev.log('AuthProvider: Login failed: $e', name: 'auth');
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

  Future<List<dynamic>> fetchMyChildren() async {
    return await _repository.getMyChildren();
  }

  Future<bool> linkChild(String childId) async {
    _setLoading(true);
    try {
      await _repository.linkChild(childId);
      await checkAuthStatus();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> linkChildByEmail(String email) async {
    _setLoading(true);
    // Clear any previous error before starting
    _error = null;
    try {
      await _repository.linkChildByEmail(email);
      await checkAuthStatus();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    return await _repository.getUserProfile(userId);
  }

  Future<List<dynamic>> getParentRequests() async {
    return await _repository.getParentRequests();
  }

  Future<void> fetchParentRequests() async {
    _setLoading(true);
    try {
      _parentRequests = await _repository.getParentRequests();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _setLoading(true);
    _error = null;
    try {
      _user = await _repository.updateProfile(data);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateUserProfile(String userId, Map<String, dynamic> data) async {
    _setLoading(true);
    _error = null;
    try {
      await _repository.updateUserProfile(userId, data);
      // If we are updating a child, we don't necessarily want to update the current_user object
      // which is the parent. But we might want to refresh child lists.
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchMyParents() async {
    _setLoading(true);
    try {
      _myParents = await _repository.getMyParents();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> acceptRequest(String requestId) async {
    _setLoading(true);
    try {
      await _repository.acceptParentRequest(requestId);
      _parentRequests.removeWhere((req) => req['id'] == requestId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> rejectRequest(String requestId) async {
    _setLoading(true);
    try {
      await _repository.rejectParentRequest(requestId);
      _parentRequests.removeWhere((req) => req['id'] == requestId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createChild({
    required String firstName,
    required String lastName,
    required DateTime dob,
    required String email,
    required String password,
    String? inviteCode,
  }) async {
    _setLoading(true);
    try {
      await _repository.createChildAccount({
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'date_of_birth': dob.toIso8601String().split('T')[0], // YYYY-MM-DD
        'academy_invite_code': inviteCode,
      });
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> uploadAvatar(String filePath) async {
    _setLoading(true);
    _error = null;
    try {
      final url = await _repository.uploadAvatar(filePath);
      _user = await _repository.updateProfile({"avatar_url": url});
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
