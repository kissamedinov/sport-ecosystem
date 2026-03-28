import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  final _storage = const FlutterSecureStorage();
  static const _keyToken = 'jwt_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyOnboarding = 'onboarding_completed';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  Future<void> deleteTokens() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyRefreshToken);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOnboarding);
  }

  Future<void> setOnboardingCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboarding, value);
  }

  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboarding) ?? false;
  }
}
