import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/services/mock_behavior.dart';
import 'package:developify_mobile/core/services/session_service.dart';
import 'package:developify_mobile/features/authentication/data/mock_auth_repository.dart';
import 'package:developify_mobile/features/authentication/presentation/stores/auth_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/qa_credentials.dart';

void main() {
  test('Canonical QA login creates the normal mock session', () async {
    final repository = MockAuthRepository(MockBehavior(delay: Duration.zero));
    final session = SessionService();
    final store = AuthStore(repository, session);
    addTearDown(store.dispose);
    addTearDown(session.dispose);
    store.setEmail(QaCredentials.email);
    store.setPassword(QaCredentials.password);
    expect(store.canSubmit, isTrue);
    expect(await store.signIn(), isTrue);
    expect(session.isAuthenticated, isTrue);
    expect(session.user?.email, QaCredentials.email);
    expect(store.password, isEmpty);
    expect(
      await repository.requestRecovery(QaCredentials.email),
      isA<Success<void>>(),
    );
    expect(await repository.verifyRecovery('000000'), isA<Failure<void>>());
    expect(
      await repository.verifyRecovery(QaCredentials.verificationCode),
      isA<Success<void>>(),
    );
    expect(
      await repository.signIn('another@example.test', 'nonempty'),
      isA<Success>(),
    );
    expect(await repository.signIn('invalid', ''), isA<Failure>());
  });
}
