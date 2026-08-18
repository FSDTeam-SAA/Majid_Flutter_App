//============================= new code ===================
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'api_endpoints.dart';

import 'token_meneger.dart';

class ApiClient {
  final Dio dio;
  bool _isRefreshing = false;
  final List<Completer<void>> _refreshCompleters = [];

  ApiClient(String baseUrl)
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: Duration(seconds: 60),
          sendTimeout: Duration(seconds: 60),
          receiveTimeout: Duration(seconds: 90),
        ),
      ) {
    if (kDebugMode) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
        ),
      );
    }

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenManager.getToken();
          if (token != null && !_shouldSkipAuthHeader(options.path)) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          if (kDebugMode) {
            debugPrint("➡ [REQUEST] ${options.method} ${options.uri}");
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint("[RESPONSE] ${response.statusCode} ${response.data}");
          }
          return handler.next(response);
        },
        onError: (DioException err, ErrorInterceptorHandler handler) async {
          final isRefreshRequest =
              err.requestOptions.path.contains(AuthEndpoints.refreshToken) ||
              err.requestOptions.path.endsWith('/auth/refresh-token') ||
              err.requestOptions.path.endsWith('/api/v1/auth/refresh-token');

          if (isRefreshRequest) {
            return handler.reject(err);
          }

          if (err.type == DioExceptionType.connectionTimeout) {
            final retryResponse = await _retryRequestOnTransientFailure(
              err.requestOptions,
            );
            if (retryResponse != null) {
              return handler.resolve(retryResponse);
            }
          }

          // Retry once on 502/503/504 (Render server waking up)
          final statusCode = err.response?.statusCode;
          if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
            final retryResponse = await _retryRequestOnTransientFailure(
              err.requestOptions,
            );
            if (retryResponse != null) {
              return handler.resolve(retryResponse);
            }
          }

          if (err.response?.statusCode == 401) {
            final currentToken = await TokenManager.getToken();
            final storedRefreshToken = await TokenManager.getRefreshToken();
            // Only worth a refresh round-trip when we actually hold a refresh
            // token. The forgot-password flow stores an access token on its
            // own, so without this guard every 401 there ran a refresh that
            // could never succeed.
            if (currentToken != null &&
                storedRefreshToken != null &&
                storedRefreshToken.isNotEmpty) {
              try {
                await _handleRefresh();

                final clonedRequest = err.requestOptions;
                final newToken = await TokenManager.getToken();
                clonedRequest.headers['Authorization'] = 'Bearer $newToken';

                final clonedResponse = await dio.fetch(clonedRequest);
                return handler.resolve(clonedResponse);
              } catch (refreshError) {
                // Keep the session and surface the original 401. Clearing here
                // dropped the access token, so every later request went out
                // with no Authorization header and the whole screen answered
                // "You are not authorized" instead of the real error.
                return handler.reject(err);
              }
            }
          }

          return handler.reject(err);
        },
      ),
    );
  }

  Future<Response<dynamic>?> _retryRequestOnTransientFailure(
    RequestOptions requestOptions,
  ) async {
    final retryCount = (requestOptions.extra['retryCount'] as int?) ?? 0;
    if (retryCount >= 2) {
      return null;
    }

    final retryOptions = requestOptions.copyWith();
    retryOptions.extra['retryCount'] = retryCount + 1;

    await Future.delayed(Duration(seconds: 2 + retryCount));

    try {
      return await dio.fetch(retryOptions);
    } on DioException {
      return null;
    }
  }

  /// Refresh token logic – race condition prevent
  Future<void> _handleRefresh() async {
    if (_isRefreshing) {
      // Already refreshing → wait for it to finish
      final completer = Completer<void>();
      _refreshCompleters.add(completer);
      await completer.future;
      return;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await TokenManager.getRefreshToken();
      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final refreshDio = Dio(
        BaseOptions(
          baseUrl: dio.options.baseUrl,
          connectTimeout: dio.options.connectTimeout,
          receiveTimeout: dio.options.receiveTimeout,
        ),
      );

      final response = await refreshDio.post(
        AuthEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
        cancelToken: CancelToken(),
      );

      final data = response.data['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Invalid refresh token response');
      }

      await TokenManager.accessToken(data['accessToken'] as String);
      final newRefreshToken = data['refreshToken'] as String?;
      await TokenManager.refreshToken(newRefreshToken ?? refreshToken);

      // Complete all waiting requests
      for (var completer in _refreshCompleters) {
        completer.complete();
      }
      _refreshCompleters.clear();
    } catch (e) {
      debugPrint('Refresh failed: $e');
      for (var completer in _refreshCompleters) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      }
      _refreshCompleters.clear();
      // Deliberately not clearing the session here — a failed refresh should
      // not log the user out mid-flow. The caller decides what to do.
      rethrow;
    } finally {
      _isRefreshing = false;
    }
  }

  bool _shouldSkipAuthHeader(String path) {
    return path.contains('/auth/login') ||
        path.contains('/auth/forgot-password') ||
        path.contains('/auth/refresh-token') ||
        path.contains('/user/register');
  }

  // API methods
  Future<Response> get(String path, {Map<String, dynamic>? query}) async {
    return await dio.get(path, queryParameters: query);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await dio.put(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return await dio.patch(path, data: data);
  }

  Future<Response> delete(String path, {dynamic data}) async {
    return await dio.delete(path, data: data);
  }
}
