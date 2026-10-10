import 'package:dio/dio.dart';
import 'package:developify_mobile/core/errors/result.dart';

abstract final class ApiErrorMapper {
  static AppFailure map(Object error) {
    if (error is! DioException) {
      return const AppFailure(
        FailureKind.unknown,
        'Something went wrong. Please try again.',
      );
    }
    final status = error.response?.statusCode;
    return switch (error.type) {
      DioExceptionType.cancel => const AppFailure(
        FailureKind.cancelled,
        'Request cancelled.',
      ),
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => const AppFailure(
        FailureKind.timeout,
        'The request timed out. Please try again.',
      ),
      DioExceptionType.connectionError => const AppFailure(
        FailureKind.network,
        'Unable to connect. Check your connection and try again.',
      ),
      DioExceptionType.badCertificate => const AppFailure(
        FailureKind.network,
        'A secure connection could not be established.',
      ),
      DioExceptionType.badResponse => switch (status) {
        401 => const AppFailure(
          FailureKind.unauthenticated,
          'Please sign in again.',
          statusCode: 401,
        ),
        403 => const AppFailure(
          FailureKind.forbidden,
          'You do not have access to this action.',
          statusCode: 403,
        ),
        404 => const AppFailure(
          FailureKind.notFound,
          'This item could not be found.',
          statusCode: 404,
        ),
        400 || 422 => AppFailure(
          FailureKind.validation,
          'Check the information and try again.',
          statusCode: status,
        ),
        _ => AppFailure(
          FailureKind.server,
          'The service is unavailable. Please try again.',
          statusCode: status,
        ),
      },
      DioExceptionType.unknown => const AppFailure(
        FailureKind.unknown,
        'Something went wrong. Please try again.',
      ),
    };
  }
}
