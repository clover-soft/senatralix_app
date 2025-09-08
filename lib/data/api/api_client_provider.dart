// Провайдер ApiClient для DI
// Импорты делать из корня пакета
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/data/api/api_client.dart';

/// Глобальный провайдер API-клиента
/// В дальнейшем можно прокинуть конфиги из core/config.dart
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});
