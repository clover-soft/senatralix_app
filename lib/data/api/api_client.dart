// Lightweight API client built on top of Dio.
// Accepts backend base URL in the constructor and exposes simple helpers.

import 'package:dio/dio.dart';
import 'package:dio_web_adapter/dio_web_adapter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message)';
}

class ApiClient {
  final Dio _dio;

  ApiClient({
    Map<String, dynamic>? defaultHeaders,
    Duration? connectTimeout,
    Duration? receiveTimeout,
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: 'https://api.sentralix.ru',
            connectTimeout: connectTimeout ?? const Duration(seconds: 10),
            receiveTimeout: receiveTimeout ?? const Duration(seconds: 20),
            headers: {'Content-Type': 'application/json', ...?defaultHeaders},
            // For fetch adapter, ensure credentials are included as well
            extra: const {'withCredentials': true},
          ),
        ) {
    // Enable cookies on Web by using BrowserHttpClientAdapter
    if (kIsWeb) {
      _dio.httpClientAdapter = BrowserHttpClientAdapter()
        ..withCredentials = true; // attach cookies to requests
    }

    // Optionally, attach an interceptor to observe 401s
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (e, handler) {
          // NOTE: Auth state should be updated by higher-level providers.
          // Here we just pass the error through.
          return handler.next(e);
        },
      ),
    );
  }

  // Expose underlying Dio if advanced usage is needed.
  Dio get dio => _dio;

  // Set or clear bearer token used for authorization.
  void setAuthToken(String? token) {
    if (token == null || token.isEmpty) {
      _dio.options.headers.remove('Authorization');
    } else {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: query,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: query,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    final response = e.response;
    final status = response?.statusCode;
    final data = response?.data;
    final msg = switch (e.type) {
      DioExceptionType.connectionTimeout => 'Connection timeout',
      DioExceptionType.sendTimeout => 'Send timeout',
      DioExceptionType.receiveTimeout => 'Receive timeout',
      DioExceptionType.badResponse => 'Bad response',
      DioExceptionType.badCertificate => 'Bad certificate',
      DioExceptionType.connectionError => 'Connection error',
      DioExceptionType.cancel => 'Request cancelled',
      DioExceptionType.unknown => e.message ?? 'Unknown error',
    };
    return ApiException(msg, statusCode: status, data: data);
  }
}
