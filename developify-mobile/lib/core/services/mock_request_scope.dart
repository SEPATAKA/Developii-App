import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/services/mock_behavior.dart';
import 'package:developify_mobile/core/utils/cancellation.dart';

final class MockRequestScope {
  final _pending = <Cancellation>{};
  Future<Result<T>> run<T>(
    MockBehavior behavior,
    T Function() operation,
  ) async {
    final cancellation = Cancellation();
    _pending.add(cancellation);
    try {
      return await behavior.run(operation, cancellation: cancellation);
    } finally {
      _pending.remove(cancellation);
    }
  }

  void cancel() {
    for (final cancellation in _pending.toList()) {
      cancellation.cancel();
    }
  }
}
