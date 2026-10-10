import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/network/api_error_mapper.dart';
import 'package:developify_mobile/core/storage/token_storage.dart';

final class ApiClient {
  ApiClient({
    required AppEnvironment environment,
    required TokenStorage tokens,
    Dio? dio,
    Future<bool> Function()? onRefresh,
  }) : _environment = environment,
       _tokens = tokens,
       _onRefresh = onRefresh,
       _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: environment.apiUri?.toString() ?? '',
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      followRedirects: false,
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            if (options.extra['authenticated'] == true) {
              final token = await _tokens.readToken();
              if (token != null && token.isNotEmpty) {
                options.headers.addAll({
                  'Authorization': ['Bearer', token].join(' '),
                });
              }
            }
            if (kDebugMode) debugPrint('API request: ${options.method}');
            handler.next(options);
          } on Object {
            handler.reject(
              DioException(
                requestOptions: options,
                error: const AppFailure(
                  FailureKind.unauthenticated,
                  'Secure authentication is unavailable.',
                ),
              ),
            );
          }
        },
      ),
    );
  }

  final AppEnvironment _environment;
  final TokenStorage _tokens;
  final Dio _dio;
  Future<bool> Function()? _onRefresh;
  Future<bool>? _refreshInflight;

  void setRefreshHandler(Future<bool> Function() handler) {
    _onRefresh = handler;
  }

  Future<bool> _refreshOnce() async {
    final handler = _onRefresh;
    if (handler == null) return false;
    return _refreshInflight ??= handler().whenComplete(() {
      _refreshInflight = null;
    });
  }

  Future<Result<T>> request<T>({
    required String path,
    required T Function(Object? json) decode,
    String method = 'GET',
    Object? data,
    Map<String, Object?>? query,
    bool authenticated = true,
    CancelToken? cancelToken,
  }) async {
    final target = Uri.tryParse(path);
    if (_environment.apiUri == null ||
        target == null ||
        target.hasScheme ||
        target.hasAuthority ||
        !path.startsWith('/') ||
        path.startsWith('//')) {
      return const Failure(
        AppFailure(FailureKind.configuration, 'The API is not configured.'),
      );
    }
    final normalizedMethod = method.toUpperCase();
    final attempts = {'GET', 'HEAD'}.contains(normalizedMethod) ? 2 : 1;
    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        final response = await _dio.request<Object?>(
          path,
          data: data,
          queryParameters: query,
          cancelToken: cancelToken,
          options: Options(
            method: normalizedMethod,
            extra: {'authenticated': authenticated},
          ),
        );
        return Success(decode(response.data));
      } on DioException catch (error) {
        if (authenticated &&
            error.response?.statusCode == 401 &&
            await _refreshOnce()) {
          try {
            final response = await _dio.request<Object?>(
              path,
              data: data,
              queryParameters: query,
              cancelToken: cancelToken,
              options: Options(
                method: normalizedMethod,
                extra: {'authenticated': authenticated},
              ),
            );
            return Success(decode(response.data));
          } on DioException catch (retryError) {
            if (retryError.error case final AppFailure failure) {
              return Failure(failure);
            }
            return Failure(ApiErrorMapper.map(retryError));
          }
        }
        final retryable =
            error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout ||
            (error.response?.statusCode != null &&
                {502, 503, 504}.contains(error.response!.statusCode));
        if (attempt + 1 < attempts &&
            retryable &&
            !(cancelToken?.isCancelled ?? false)) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          continue;
        }
        if (error.error case final AppFailure failure) return Failure(failure);
        return Failure(ApiErrorMapper.map(error));
      } on Object catch (error) {
        return Failure(ApiErrorMapper.map(error));
      }
    }
    return const Failure(
      AppFailure(FailureKind.unknown, 'The request could not be completed.'),
    );
  }

  void dispose() => _dio.close(force: true);
}
