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

    // Attach logging + basic 401 observation
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // comment: start timer for duration measurement
          options.extra['__sw'] = Stopwatch()..start();

          final method = options.method;
          final url = _fullUrl(options);
          final dataInfo = _briefData(options.data);
          // Console log
          // 🙂 Request log
          // ignore: avoid_print
          print('[API] → $method $url  data=$dataInfo');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          final sw = response.requestOptions.extra['__sw'] as Stopwatch?;
          sw?.stop();
          final ms = sw?.elapsedMilliseconds;
          final method = response.requestOptions.method;
          final url = _fullUrl(response.requestOptions);
          final status = response.statusCode;
          final size = _briefData(response.data);
          // 🙂 Response log
          // ignore: avoid_print
          print(
            '[API] ← $method $url  status=$status  ${ms != null ? 'in ${ms}ms' : ''}  data=$size',
          );
          return handler.next(response);
        },
        onError: (e, handler) {
          final sw = e.requestOptions.extra['__sw'] as Stopwatch?;
          sw?.stop();
          final ms = sw?.elapsedMilliseconds;
          final method = e.requestOptions.method;
          final url = _fullUrl(e.requestOptions);
          final status = e.response?.statusCode;
          final body = _briefData(e.response?.data);
          // ☠️ Error log
          // ignore: avoid_print
          print(
            '[API] ✖ $method $url  status=$status  ${ms != null ? 'in ${ms}ms' : ''}  error=${e.type}  data=$body',
          );
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

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.patch<T>(
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

  // comment: helpers for logging
  String _fullUrl(RequestOptions o) {
    // Dio will resolve baseUrl + path internally, but for logging we combine simply
    final p = o.path.startsWith('http')
        ? o.path
        : '${_dio.options.baseUrl}${o.path}';
    if (o.queryParameters.isEmpty) return p;
    return Uri.parse(p)
        .replace(
          queryParameters: o.queryParameters.map((k, v) => MapEntry(k, '$v')),
        )
        .toString();
  }

  String _briefData(dynamic data) {
    if (data == null) return 'null';
    final s = data.toString();
    if (s.length <= 200) return s;
    return '${s.substring(0, 197)}...';
  }
}
