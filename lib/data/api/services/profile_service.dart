import 'package:sentralix_app/data/api/api_client.dart';

/// ProfileService реализует методы работы с профилем пользователя согласно apidoc.txt
/// - GET /me/profile — получение профиля
/// - PATCH /me/profile — обновление имени пользователя (username)
/// - POST /me/password — смена пароля (old_password/new_password)
class ProfileService {
  ProfileService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  /// Получить профиль текущего пользователя
  Future<Map<String, dynamic>> getProfile({String path = '/me/profile'}) async {
    final r = await _api.get(path);
    final data = r.data;
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  /// Обновить имя пользователя (ФИО = username)
  /// Возвращает актуальный профиль
  Future<Map<String, dynamic>> updateName({required String username, String path = '/me/profile'}) async {
    final r = await _api.patch(path, data: {
      'username': username,
    });
    final data = r.data;
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  /// Смена пароля
  /// Возвращает { "ok": true } при успехе
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
    String path = '/me/password',
  }) async {
    final r = await _api.post(path, data: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
    final data = r.data;
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }
}
