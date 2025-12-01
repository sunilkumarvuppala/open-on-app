import 'package:shared_preferences/shared_preferences.dart';
import 'package:openon_app/core/utils/logger.dart';

/// Service for storing and retrieving authentication tokens
class TokenStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  /// Save access token
  Future<void> saveAccessToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, token);
      Logger.debug('Access token saved');
    } catch (e, stackTrace) {
      Logger.error('Failed to save access token', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessTokenKey);
    } catch (e, stackTrace) {
      Logger.error('Failed to get access token', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_refreshTokenKey, token);
      Logger.debug('Refresh token saved');
    } catch (e, stackTrace) {
      Logger.error('Failed to save refresh token', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } catch (e, stackTrace) {
      Logger.error('Failed to get refresh token', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Save both tokens
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
    ]);
  }

  /// Clear all tokens
  Future<void> clearTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      Logger.debug('Tokens cleared');
    } catch (e, stackTrace) {
      Logger.error('Failed to clear tokens', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}

