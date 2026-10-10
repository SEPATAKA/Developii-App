import 'dart:async';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/utils/cancellation.dart';

final class MockBehavior {
  MockBehavior({
    this.delay = const Duration(milliseconds: 350),
    this.empty = false,
    this.available = true,
    int failures = 0,
  }) : _failuresRemaining = failures;

  factory MockBehavior.fromEnvironment(AppEnvironment environment) =>
      MockBehavior(
        delay: environment.mockDelay,
        available: environment.mockMode,
        empty: environment.mockScenario == MockScenario.empty,
        failures: environment.mockScenario == MockScenario.networkFailure
            ? 1
            : 0,
      );

  final Duration delay;
  final bool empty;
  final bool available;
  int _failuresRemaining;

  void failNext([int count = 1]) => _failuresRemaining = count;

  Future<Result<T>> run<T>(
    T Function() operation, {
    Cancellation? cancellation,
  }) {
    final completer = Completer<Result<T>>();
    Timer? timer;
    void Function()? stopListening;
    void complete(Result<T> result) {
      if (completer.isCompleted) return;
      timer?.cancel();
      stopListening?.call();
      completer.complete(result);
    }

    stopListening = cancellation?.listen(
      () => complete(
        const Failure(AppFailure(FailureKind.cancelled, 'Action cancelled.')),
      ),
    );
    if (completer.isCompleted) return completer.future;
    timer = Timer(delay, () {
      if (!available) {
        complete(
          const Failure(
            AppFailure(
              FailureKind.configuration,
              'The production service is not connected. Run with MOCK_MODE=true.',
            ),
          ),
        );
      } else if (_failuresRemaining > 0) {
        _failuresRemaining--;
        complete(
          const Failure(
            AppFailure(
              FailureKind.network,
              'Unable to connect. Please try again.',
            ),
          ),
        );
      } else {
        try {
          complete(Success(operation()));
        } on Object catch (error, stack) {
          stopListening?.call();
          completer.completeError(error, stack);
        }
      }
    });
    return completer.future;
  }
}
