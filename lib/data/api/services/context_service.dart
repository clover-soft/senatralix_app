import 'dart:convert';

import 'package:sentralix_app/data/api/api_client.dart';

/// ContextService handles domain/subscription context for current user
/// Endpoint: GET /me/context
class ContextService {
  ContextService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  /// Fetch user context
  /// Expected shape:
  /// {
  ///   "subscription": { "id": ..., "name": ..., "settings": "{\"menu\":[{\"key\":...,\"order\":...}]}" },
  ///   "domains": [ {"id":..., "name":..., "settings": "{}"} ]
  /// }
  Future<Map<String, dynamic>> getContext({String path = '/me/context'}) async {
    final r = await _api.get(path);
    final data = r.data;
    if (data is Map<String, dynamic>) {
      return data;
    }
    return <String, dynamic>{};
  }

  /// Helper: parse subscription.settings JSON string to Map
  Map<String, dynamic> parseSubscriptionSettings(dynamic subscription) {
    if (subscription is! Map) return const {};
    final raw = subscription['settings'];
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final parsed = jsonDecode(raw);
        if (parsed is Map<String, dynamic>) return parsed;
      } catch (_) {}
    }
    return const {};
  }
}
