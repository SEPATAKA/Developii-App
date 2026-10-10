enum FailureKind {
  validation,
  network,
  timeout,
  unauthenticated,
  forbidden,
  notFound,
  server,
  cancelled,
  configuration,
  unknown,
}

final class AppFailure {
  const AppFailure(
    this.kind,
    this.message, {
    this.statusCode,
    this.fields = const {},
  });
  final FailureKind kind;
  final String message;
  final int? statusCode;
  final Map<String, String> fields;
}

sealed class Result<T> {
  const Result();
  bool get isSuccess => this is Success<T>;
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);
  final AppFailure error;
}

enum LoadStatus { initial, loading, success, empty, error }
