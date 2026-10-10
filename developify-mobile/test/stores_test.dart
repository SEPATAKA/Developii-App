import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/services/mock_behavior.dart';
import 'package:developify_mobile/core/services/session_service.dart';
import 'package:developify_mobile/features/authentication/data/mock_auth_repository.dart';
import 'package:developify_mobile/features/authentication/domain/landowner_registration.dart';
import 'package:developify_mobile/features/authentication/presentation/stores/auth_store.dart';
import 'package:developify_mobile/features/authentication/presentation/stores/recovery_store.dart';
import 'package:developify_mobile/features/landowner/data/mock_landowner_repository.dart';
import 'package:developify_mobile/features/landowner/presentation/stores/home_store.dart';
import 'package:developify_mobile/features/landowner/presentation/stores/properties_store.dart';
import 'package:developify_mobile/features/landowner/presentation/stores/earnings_store.dart';
import 'package:developify_mobile/features/landowner/presentation/stores/submission_store.dart';
import 'package:developify_mobile/features/notifications/data/mock_notification_repository.dart';
import 'package:developify_mobile/features/notifications/presentation/notifications_store.dart';
import 'package:developify_mobile/features/onboarding/presentation/onboarding_store.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'package:developify_mobile/features/shared/presentation/experience_store.dart';
import 'package:developify_mobile/features/profile/data/mock_profile_repository.dart';
import 'package:developify_mobile/features/profile/presentation/stores/security_store.dart';
import 'package:developify_mobile/features/profile/presentation/stores/payout_store.dart';

MockBehavior behavior({bool empty = false}) =>
    MockBehavior(delay: Duration.zero, empty: empty);
void main() {
  test('Onboarding progression and completion update a domain service', () {
    final session = SessionService();
    final store = OnboardingStore(session);
    store.setPage(3);
    expect(store.isLast, true);
    store.finish();
    expect(session.onboardingComplete, true);
    session.dispose();
  });
  test(
    'Authentication validates, exposes loading, retries and clears password',
    () async {
      final mock = behavior()..failNext();
      final session = SessionService();
      final store = AuthStore(MockAuthRepository(mock), session);
      expect(await store.signIn(), false);
      expect(store.emailError, isNotNull);
      store.setEmail('landowner@example.test');
      store.setPassword('password1');
      final request = store.signIn();
      expect(store.status, LoadStatus.loading);
      expect(await request, false);
      expect(store.status, LoadStatus.error);
      expect(await store.signIn(), true);
      expect(session.isAuthenticated, true);
      expect(store.password, isEmpty);
      store.dispose();
      session.dispose();
    },
  );
  test('Disposed async stores ignore late results', () async {
    final store = HomeStore(MockLandownerRepository(behavior()));
    final pending = store.load();
    store.dispose();
    await pending;
    expect(store.data, isNull);
  });
  test(
    'Recovery rejects wrong codes and password mismatch, then completes',
    () async {
      final store = RecoveryStore(MockAuthRepository(behavior()));
      store.setEmail('landowner@example.test');
      await store.submit();
      expect(store.stage, 1);
      expect(store.resendSeconds, 48);
      store.setCode('000000');
      await store.submit();
      expect(store.status, LoadStatus.error);
      store.setCode('123456');
      await store.submit();
      expect(store.stage, 2);
      store.setPassword('new-password');
      store.setConfirmation('different');
      expect(await store.submit(), false);
      store.setConfirmation('new-password');
      expect(await store.submit(), true);
      store.dispose();
    },
  );
  for (final empty in [false, true]) {
    test(
      'Home, properties and earnings support ${empty ? 'empty' : 'success'} data',
      () async {
        final repository = MockLandownerRepository(behavior(empty: empty));
        final home = HomeStore(repository);
        final properties = PropertiesStore(repository);
        final earnings = EarningsStore(repository);
        await Future.wait([home.load(), properties.load(), earnings.load()]);
        expect(home.data!.properties.isEmpty, empty);
        expect(
          properties.status,
          empty ? LoadStatus.empty : LoadStatus.success,
        );
        expect(earnings.status, empty ? LoadStatus.empty : LoadStatus.success);
        home.dispose();
        properties.dispose();
        earnings.dispose();
      },
    );
  }
  test('A newly created account starts the landowner portal at zero', () async {
    final session = SessionService();
    final auth = MockAuthRepository(behavior());
    final landowner = MockLandownerRepository(behavior(), session: session);
    final profile = MockProfileRepository(behavior(), session);
    final created = await auth.registerLandowner(
      const LandownerRegistration(
        name: 'Amina Dlamini',
        email: 'amina@example.test',
        phone: '+27 82 000 0000',
        password: 'Password1',
        entity: EntityType.individual,
      ),
    );
    final user = switch (created) {
      Success(:final value) => value,
      Failure(:final error) => fail(error.message),
    };
    session.signIn(user, experience: Experience.landowner);
    final overview = await landowner.overview();
    final earnings = await landowner.earnings();
    final properties = await landowner.properties();
    switch (overview) {
      case Success(:final value):
        expect(value.propertyCount, 0);
        expect(value.approvedCount, 0);
        expect(value.earnedCents, 0);
        expect(value.nextPayoutCents, 0);
        expect(value.properties, isEmpty);
      case Failure(:final error):
        fail(error.message);
    }
    switch (earnings) {
      case Success(:final value):
        expect(value.totalCents, 0);
        expect(value.payouts, isEmpty);
      case Failure(:final error):
        fail(error.message);
    }
    switch (properties) {
      case Success(:final value):
        expect(value, isEmpty);
      case Failure(:final error):
        fail(error.message);
    }
    expect(profile.payoutAccount, isNull);
    session.signIn(
      const AppUser(
        id: 'local-investor-registration-1',
        name: 'Amina Dlamini',
        email: 'amina@example.test',
      ),
      experience: Experience.landowner,
    );
    final investorPortal = await landowner.overview();
    switch (investorPortal) {
      case Success(:final value):
        expect(value.earnedCents, 0);
        expect(value.propertyCount, 0);
      case Failure(:final error):
        fail(error.message);
    }
    session.signIn(
      const AppUser(
        id: 'local-landowner',
        name: 'Babatunde Yusuf',
        email: 'bafreka@gmail.com',
      ),
      experience: Experience.landowner,
    );
    final seeded = await landowner.overview();
    switch (seeded) {
      case Success(:final value):
        expect(value.propertyCount, 5);
        expect(value.earnedCents, 48000001);
      case Failure(:final error):
        fail(error.message);
    }
    expect(profile.payoutAccount?.number, '0000001293');
    await landowner.dispose();
    profile.dispose();
    session.dispose();
  });
  test('Notifications persist read state across independent stores', () async {
    final repository = MockNotificationRepository(behavior());
    final first = NotificationsStore(repository);
    await first.load();
    final unread = first.unreadCount;
    expect(unread, greaterThan(0));
    await first.markRead(first.items.first.id);
    final second = NotificationsStore(repository);
    await second.load();
    expect(second.unreadCount, unread - 1);
    await second.markRead();
    expect(second.unreadCount, 0);
    first.dispose();
    second.dispose();
  });
  test(
    'Submission validates, persists draft, requires documents, and submits',
    () async {
      final repository = MockLandownerRepository(behavior());
      final store = SubmissionStore(repository, 'test-draft');
      expect(store.next(), false);
      expect(store.errors['name'], isNotNull);
      for (final entry in {
        'name': 'Marula Heights',
        'number': '12',
        'type': 'Vacant land',
        'size': '1.4',
        'unit': 'Hectares',
        'deeds': 'Johannesburg',
        'address': 'Malibongwe Drive',
        'city': 'Johannesburg',
        'province': 'Gauteng',
        'latitude': '-26.076',
        'longitude': '27.958',
      }.entries) {
        store.setField(entry.key, entry.value);
      }
      expect(store.next(), true);
      store.setStep(2);
      expect(store.next(), true);
      store.setField('latitude', 'NaN');
      expect(store.next(), false);
      store.setField('latitude', '-26.076');
      store.addSamplePhotos();
      store.save();
      final resumed = SubmissionStore(repository, 'test-draft');
      expect(resumed.draft.photos.length, 4);
      resumed.setStep(7);
      expect(resumed.next(), false);
      resumed.addDocument('identity');
      expect(resumed.next(), true);
      resumed.setStep(9);
      expect(await resumed.submit(), isNull);
      resumed.update(resumed.draft.copyWith(accepted: true));
      expect(await resumed.submit(), isNotNull);
      expect(repository.readDraft('test-draft').name, isEmpty);
      store.dispose();
      resumed.dispose();
    },
  );
  test('Investor selection confirms the requested experience', () {
    final store = ExperienceStore();
    store.select(Experience.investor);
    expect(store.confirm(), true);
    expect(store.selected, Experience.investor);
    expect(store.investorUnavailable, false);
  });
  test(
    'Security preferences survive route stores and failed verification cannot enable 2FA',
    () async {
      final session = SessionService();
      final repository = MockProfileRepository(behavior(), session);
      final first = SecurityStore(repository);
      first.toggleBiometric('Use for login', true);
      first.removeDevice('previous-1');
      first.setCode('000000');
      expect(await first.perform('verify-code'), false);
      expect(first.twoFactorEnabled, false);
      first.setCode('123456');
      expect(await first.perform('verify-code'), true);
      first.dispose();
      final second = SecurityStore(repository);
      expect(second.biometrics['Use for login'], true);
      expect(second.previousDevices, isNot(contains('previous-1')));
      expect(second.twoFactorEnabled, true);
      second.dispose();
      session.dispose();
    },
  );
  test(
    'Payout validation and retry preserve data and create an account from empty mode',
    () async {
      final session = SessionService();
      final mock = behavior(empty: true);
      final repository = MockProfileRepository(mock, session);
      final store = PayoutStore(repository);
      expect(repository.payoutAccount, isNull);
      expect(await store.submit(), false);
      store.setBank('Standard Bank');
      store.setNumber('1234567890');
      store.setType('Cheque / Current');
      store.setBranch('051001');
      store.attachProof(true);
      mock.failNext();
      expect(await store.submit(), false);
      expect(store.status, LoadStatus.error);
      expect(repository.payoutAccount, isNull);
      expect(await store.submit(), true);
      expect(repository.payoutAccount!.lastFour, '7890');
      store.dispose();
      session.dispose();
    },
  );
}
