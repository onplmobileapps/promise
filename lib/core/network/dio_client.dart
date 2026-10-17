// core/api_client.dart
import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:railway_hrms/core/error/api_error_text.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/navigation/app_routes.dart';
import 'package:railway_hrms/core/navigation/navigator_key.dart';
import 'package:railway_hrms/core/network/api_endpoints.dart';
import 'package:railway_hrms/core/network/network_monitor.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';

class DioClient {
  late Dio _dio;

  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  late final Dio _refreshDio;

  DioClient._internal() {
    _refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.base,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.base,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _NetworkReportInterceptor(),
      TokenInterceptor(),
      RefreshTokenInterceptor(dio: _dio, refreshDio: _refreshDio),
      // Bodies include passwords and tokens: never log them in release.
      if (kDebugMode)
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
    ]);
  }

  Dio get dio => _dio;

  /// The client that renews the session, for tests to stand a network in.
  @visibleForTesting
  Dio get refreshDio => _refreshDio;

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw AppException('Unexpected error: $e');
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw AppException('Unexpected error: $e');
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw AppException('Unexpected error: $e');
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw AppException('Unexpected error: $e');
    }
  }

  Future<Response> postFormData(
    String path, {
    required Map<String, dynamic> fields,
    required List<MapEntry<String, MultipartFile>> files,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final formData = FormData();
      fields.forEach((key, value) {
        formData.fields.add(MapEntry(key, value.toString()));
      });
      for (var file in files) {
        formData.files.add(file);
      }
      return await dio.post(
        path,
        data: formData,
        options: options ?? Options(contentType: 'multipart/form-data'),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw AppException('Unexpected error: $e');
    }
  }

  /// [error] as the app's own failure: a lost connection as a
  /// [NetworkException], a refusal as a [ServerException] carrying the
  /// status, the answer, and what the server said in words.
  AppException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('Connection timeout');
      case DioExceptionType.unknown:
        final cause = error.error;
        if (cause is SocketException || cause is HttpException) {
          return NetworkException(_offlineMessage);
        }
        return NetworkException('Network error, please try again');
      case DioExceptionType.connectionError:
        return NetworkException(_offlineMessage);
      case DioExceptionType.transformTimeout:
        return NetworkException('Transforming Timeout');
      case DioExceptionType.cancel:
        return AppException('Request cancelled');
      case DioExceptionType.badCertificate:
        return AppException('Invalid server certificate');
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        final data = error.response?.data;
        if (status == 403 &&
            data is Map &&
            data['detail'] == 'User has been logged out, needs to login again') {
          _forceLogout();
        }
        final message =
            ApiErrorText.of(data) ??
            switch (status) {
              400 => 'Bad request',
              401 => 'Your session has ended. Please sign in again.',
              403 => 'Not allowed',
              404 => 'Not found',
              405 => 'This action is not allowed by the server',
              422 => 'Validation error',
              500 => 'Internal server error',
              502 || 503 || 504 => 'The server is not available right now',
              _ => 'Server error: $status',
            };
        return ServerException(
          message,
          status?.toString(),
          data is Map ? Map<String, dynamic>.from(data) : null,
        );
    }
  }

  static const String _offlineMessage =
      "Can't reach the server. Check your internet connection and try again.";

  void _forceLogout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StorageService.clearAuthData();
      navigatorKey.currentState?.pushReplacementNamed(AppRoutes.login);
    });
  }
}

/// Tells [NetworkMonitor] how long API calls take, and when they can't
/// reach the server.
class _NetworkReportInterceptor extends Interceptor {
  static const _startedAt = 'network_report_started_at';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAt] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final options = response.requestOptions;
    final started = options.extra[_startedAt];
    // Uploads are slow for their size, not because of the network.
    if (started is DateTime && options.data is! FormData) {
      NetworkMonitor.instance.reportRequest(DateTime.now().difference(started));
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final unreachable = switch (err.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout => true,
      DioExceptionType.unknown => err.error is SocketException,
      _ => false,
    };
    if (unreachable) {
      NetworkMonitor.instance.reportUnreachable();
    } else if (err.type == DioExceptionType.badResponse) {
      // Turned down, but answered: the internet works.
      NetworkMonitor.instance.reportRequest();
    }
    handler.next(err);
  }
}

class TokenInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.path.contains('/login') || options.path.contains('/refresh')) {
      return handler.next(options);
    }
    final token = await StorageService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class RefreshTokenInterceptor extends Interceptor {
  RefreshTokenInterceptor({required this.dio, required this.refreshDio});

  final Dio dio;
  final Dio refreshDio;

  Future<String?>? _refreshFuture;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final isRefreshCall = err.requestOptions.path.contains('/refresh');
    final alreadyRetried =
        err.requestOptions.extra['retriedAfterRefresh'] == true;
    // Sent without a token, as by a traveller on train tracking, there is
    // no session to renew or end: the error is the caller's to show.
    final hadToken = err.requestOptions.headers['Authorization'] != null;

    if (!isUnauthorized || isRefreshCall || alreadyRetried || !hadToken) {
      return handler.next(err);
    }

    final newToken = await _refreshAccessToken();
    if (newToken == null) {
      await _handleRefreshFailure();
      return handler.next(err);
    }

    final retryOptions = err.requestOptions
      ..headers['Authorization'] = 'Bearer $newToken'
      ..extra['retriedAfterRefresh'] = true;
    // A form is read once, as it is sent: a fresh copy of it goes again,
    // files and all.
    if (retryOptions.data case final FormData form) {
      retryOptions.data = form.clone();
    }
    try {
      return handler.resolve(await dio.fetch(retryOptions));
    } on DioException catch (refused) {
      // The session was renewed and the request still refused, as a wrong
      // old password is: that is the request's own answer to show, not a
      // reason to sign the user out.
      return handler.next(refused);
    }
  }

  Future<String?> _refreshAccessToken() {
    // Coalesce concurrent 401s into a single refresh call.
    _refreshFuture ??= _performRefresh();
    return _refreshFuture!.whenComplete(() => _refreshFuture = null);
  }

  Future<String?> _performRefresh() async {
    final refreshToken = await StorageService.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final response = await refreshDio.post(
        '/account/refresh',
        data: {'refresh_token': refreshToken},
      );

      final newAccessToken = response.data['access'] as String?;
      final newRefreshToken = response.data['refresh'] as String?;
      final newcsrfToken = response.data['csrf_token'] as String?;

      if (newAccessToken == null ||
          newRefreshToken == null ||
          newcsrfToken == null) {
        return null;
      }

      await StorageService.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
        csrfToken: newcsrfToken,
      );

      dio.options.headers['Authorization'] = 'Bearer $newAccessToken';
      return newAccessToken;
    } on Object catch (e) {
      log('Token refresh failed: $e');
      return null;
    }
  }

  Future<void> _handleRefreshFailure() async {
    await StorageService.clearAuthData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pushReplacementNamed(AppRoutes.login);
    });
  }
}
