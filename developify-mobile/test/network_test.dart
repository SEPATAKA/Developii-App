import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/network/api_client.dart';
import 'package:developify_mobile/core/network/api_error_mapper.dart';
import 'package:developify_mobile/core/storage/token_storage.dart';
import 'package:developify_mobile/features/authentication/data/api_auth_repository.dart';
import 'package:developify_mobile/features/authentication/data/mock_auth_repository.dart';
import 'package:developify_mobile/features/authentication/domain/auth_repository.dart';

class RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  int failures = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (failures-- > 0) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      '{"value":42}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('Live mode is the default when launch defines are not overridden', () {
    expect(AppEnvironment.fromDefines().mockMode, isFalse);
  });

  test('Live mode never silently falls back to mock repositories', () async {
    await expectLater(
      AppDependencies.create(
        environment: const AppEnvironment(mockMode: false),
        tokenStorage: MemoryTokenStorage(),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test(
    'A configured API URL selects live auth unless mock mode is explicit',
    () async {
      final live = await AppDependencies.create(
        environment: const AppEnvironment(
          apiBaseUrl: 'https://api.example.test',
          mockMode: false,
        ),
        tokenStorage: MemoryTokenStorage(),
      );
      try {
        expect(live.container<AuthRepository>(), isA<ApiAuthRepository>());
      } finally {
        await live.dispose();
      }

      final mock = await AppDependencies.create(
        environment: const AppEnvironment(
          apiBaseUrl: 'https://api.example.test',
          mockMode: true,
        ),
        tokenStorage: MemoryTokenStorage(),
      );
      try {
        expect(mock.container<AuthRepository>(), isA<MockAuthRepository>());
      } finally {
        await mock.dispose();
      }
    },
  );

  test('Configuration rejects insecure and credential-bearing base URLs', () {
    for (final url in [
      '',
      'http://example.test',
      'https://user:password@example.test',
      'https://example.test?secret=x',
    ]) {
      expect(AppEnvironment(apiBaseUrl: url).apiUri, isNull);
    }
    expect(
      const AppEnvironment(apiBaseUrl: 'https://example.test/api').apiUri,
      isNotNull,
    );
  });
  test(
    'Client attaches token only to same-origin paths and retries only reads',
    () async {
      final adapter = RecordingAdapter()..failures = 1;
      final dio = Dio()..httpClientAdapter = adapter;
      final tokens = MemoryTokenStorage();
      await tokens.writeToken('test-token');
      final client = ApiClient(
        environment: const AppEnvironment(apiBaseUrl: 'https://example.test'),
        tokens: tokens,
        dio: dio,
      );
      final result = await client.request(
        path: '/properties',
        decode: (json) => (json! as Map<String, dynamic>)['value'],
      );
      expect(result, isA<Success<dynamic>>());
      expect(adapter.requests.length, 2);
      expect(
        adapter.requests.last.headers['Authorization'],
        ['Bearer', 'test-token'].join(' '),
      );
      expect(
        await client.request(
          path: 'https://other.test/',
          decode: (json) => json,
        ),
        isA<Failure<Object?>>(),
      );
      expect(adapter.requests.length, 2);
      adapter.failures = 1;
      await client.request(
        path: '/properties',
        method: 'POST',
        decode: (json) => json,
      );
      expect(adapter.requests.length, 3);
      client.dispose();
    },
  );
  test('Network errors normalize to user-safe typed failures', () {
    final request = RequestOptions(path: '/');
    expect(
      ApiErrorMapper.map(
        DioException(requestOptions: request, type: DioExceptionType.cancel),
      ).kind,
      FailureKind.cancelled,
    );
    expect(
      ApiErrorMapper.map(
        DioException(
          requestOptions: request,
          type: DioExceptionType.receiveTimeout,
        ),
      ).kind,
      FailureKind.timeout,
    );
    expect(
      ApiErrorMapper.map(
        DioException(
          requestOptions: request,
          response: Response(requestOptions: request, statusCode: 401),
          type: DioExceptionType.badResponse,
        ),
      ).kind,
      FailureKind.unauthenticated,
    );
  });
}
