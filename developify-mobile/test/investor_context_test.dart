import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/services/mock_behavior.dart';
import 'package:developify_mobile/core/services/session_service.dart';
import 'package:developify_mobile/core/utils/cancellation.dart';
import 'package:developify_mobile/features/investor/domain/investor_account_context.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Residency overlays remain independent and clear on logout', () {
    final session = SessionService();
    final context = InvestorAccountContext(session);
    session.signIn(
      const AppUser(
        id: 'resident',
        name: 'Investor',
        email: 'investor@example.test',
        nonResident: true,
      ),
    );
    expect(context.nonResident, true);
    context.selectEntity(EntityType.trust);
    expect(context.nonResident, false);
    context.selectEntity(EntityType.trust, nonResident: true);
    final previous = context.scope!;
    context.selectEntity(EntityType.trust, nonResident: false);
    expect(context.isCurrent(previous), false);
    context.selectEntity(EntityType.individual);
    expect(context.nonResident, true);
    context.selectEntity(EntityType.trust);
    expect(context.nonResident, false);
    session.signOut();
    expect(context.nonResidentFor(EntityType.individual), false);
    context.dispose();
    session.dispose();
  });
  test(
    'Entity switches retain authentication and invalidate prior requests',
    () async {
      final session = SessionService();
      final context = InvestorAccountContext(session);
      session.signIn(
        const AppUser(
          id: 'test',
          name: 'Investor',
          email: 'investor@example.test',
        ),
      );
      final personal = context.scope!;
      context.selectEntity(EntityType.trust);
      expect(session.isAuthenticated, true);
      expect(session.user!.id, 'test');
      expect(context.entity, EntityType.trust);
      expect(context.isCurrent(personal), false);
      final trust = context.scope!;
      session.signOut();
      expect(context.scope, isNull);
      expect(context.isCurrent(trust), false);
      context.dispose();
      session.dispose();
    },
  );

  test(
    'Cancelling a delayed mock operation prevents its mutation and preserves retry failure',
    () async {
      final behavior = MockBehavior(
        delay: const Duration(milliseconds: 20),
        failures: 1,
      );
      final cancellation = Cancellation();
      var mutations = 0;
      final pending = behavior.run(
        () => mutations++,
        cancellation: cancellation,
      );
      cancellation.cancel();
      final cancelled = await pending;
      expect((cancelled as Failure<int>).error.kind, FailureKind.cancelled);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(mutations, 0);
      expect(await behavior.run(() => mutations++), isA<Failure<int>>());
      expect(await behavior.run(() => mutations++), isA<Success<int>>());
      expect(mutations, 1);
    },
  );

  test(
    'An already-cancelled request never starts a timer or operation',
    () async {
      final cancellation = Cancellation()..cancel();
      var invoked = false;
      final result = await MockBehavior(delay: const Duration(days: 1)).run(() {
        invoked = true;
        return true;
      }, cancellation: cancellation);
      expect(result, isA<Failure<bool>>());
      expect(invoked, false);
    },
  );
}
