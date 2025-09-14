import 'package:sentralix_app/data/api/api_client.dart';

/// AuthService encapsulates auth-related API calls.
/// Uses httpOnly cookie session on the backend, so no tokens are handled here.
class AuthService {
  AuthService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  /// Perform login with email/password.
  /// Backend is expected to set httpOnly session cookie via Set-Cookie.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String path = '/auth/login',
  }) async {
    final r = await _api.post(
      path,
      data: {'email': email, 'password': password},
    );
    // Response may include user info; return as Map for flexibility.
    final data = r.data;
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  /// Logout current session (server will clear session and delete cookie).
  Future<void> logout({String path = '/auth/logout'}) async {
    await _api.post(path);
  }

  /// Get current user info; 200 if authorized, 401 otherwise.
  Future<Map<String, dynamic>> me({String path = '/me'}) async {
    final r = await _api.get(path);
    final data = r.data;
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }
}
