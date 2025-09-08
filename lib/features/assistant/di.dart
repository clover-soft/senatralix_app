// DI надфичи Assistant
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentralix_app/data/api/api_client_provider.dart';

/// Пример общего сервиса ассистента
class AssistantService {
  AssistantService({required this.baseUrl});
  final String baseUrl;
}

/// Провайдер общего сервиса ассистента
final assistantServiceProvider = Provider<AssistantService>((ref) {
  // В данном месте можно получить ApiClient и/или конфиг, пока заглушка
  final api = ref.watch(apiClientProvider);
  // baseUrl из ApiClient
  final url = api.dio.options.baseUrl;
  return AssistantService(baseUrl: url);
});
