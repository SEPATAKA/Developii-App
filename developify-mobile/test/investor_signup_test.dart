import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/core/services/mock_behavior.dart';
import 'package:developify_mobile/core/services/session_service.dart';
import 'package:developify_mobile/core/services/transaction_authorization.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/features/authentication/data/mock_auth_repository.dart';
import 'package:developify_mobile/features/authentication/domain/auth_repository.dart';
import 'package:developify_mobile/features/authentication/presentation/recovery_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/investor_signup_screen.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investor_signup_store.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'helpers/fonts.dart';

void main() {
  setUpAll(loadAppFonts);
  Future<(AppDependencies, GoRouter)> mount(
    WidgetTester tester,
    double width, {
    bool company = false,
    Duration delay = Duration.zero,
  }) async {
    tester.view.physicalSize = Size(width, 852);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 56, bottom: 34);
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    final dependencies = await AppDependencies.create(
      environment: AppEnvironment(mockDelay: delay),
    );
    dependencies.session.completeOnboarding();
    final router = createAppRouter(
      dependencies,
      initialLocation:
          '/investor/create-account${company ? '?entity=company' : ''}',
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await tester.runAsync(dependencies.dispose);
    });
    await tester.pumpWidget(
      DevelopifyApp(dependencies: dependencies, router: router),
    );
    await tester.pumpAndSettle();
    return (dependencies, router);
  }

  Future<void> enter(WidgetTester tester, Finder finder, String value) async {
    await tester.ensureVisible(finder);
    await tester.enterText(finder, value);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: finder.toString());
  }

  Finder button(String label) => find.widgetWithText(AppButton, label).last;
  Finder field(String label) => find.byKey(ValueKey('field-$label'));
  Finder code() => find.descendant(
    of: find.byType(CodeField),
    matching: find.byType(TextField),
  );

  for (final width in [360.0, 393.0, 430.0]) {
    testWidgets(
      'Company signup validates representatives and completes demo security at $width',
      (tester) async {
        final (dependencies, router) = await mount(
          tester,
          width,
          company: true,
        );
        final store = tester
            .widget<InvestorSignupScreen>(find.byType(InvestorSignupScreen))
            .store;
        final repository =
            dependencies.container<AuthRepository>() as MockAuthRepository;
        expect(store.representatives.length, 1);
        for (final entry in {
          'Registration Number': '2026/123456/07',
          'Company Name': 'Saffron Property Company',
          'Company Email Address': 'company@example.test',
          'Company Phone Number': '821234567',
          'Password': 'Password123!',
          'Confirm Password': 'Password123!',
        }.entries) {
          await enter(tester, field(entry.key), entry.value);
        }
        expect(
          tester.widget<AppButton>(button('Create account')).onPressed,
          isNotNull,
        );
        await tap(tester, button('Create account'));
        expect(
          find.text('Enter a name and ID for each representative.'),
          findsOneWidget,
        );
        await tap(tester, find.widgetWithText(TextButton, 'Add'));
        await enter(
          tester,
          find.byKey(const ValueKey('representative-name-0')),
          'Director One',
        );
        await enter(
          tester,
          find.byKey(const ValueKey('representative-id-0')),
          '9001011234088',
        );
        await enter(
          tester,
          find.byKey(const ValueKey('representative-name-1')),
          'Director Two',
        );
        await enter(
          tester,
          find.byKey(const ValueKey('representative-id-1')),
          '9101011234088',
        );
        await tap(tester, find.widgetWithText(TextButton, 'Delete').first);
        expect(store.representatives.single.name, 'Director Two');
        expect(
          tester
              .widgetList<EditableText>(find.byType(EditableText))
              .any((text) => text.controller.text == 'Director Two'),
          true,
        );
        repository.behavior.failNext();
        await tap(tester, button('Create account'));
        expect(store.stage, InvestorSignupStage.details);
        expect(
          find.text('Unable to connect. Please try again.'),
          findsOneWidget,
        );
        await tap(tester, button('Create account'));
        expect(store.stage, InvestorSignupStage.verification);
        expect(
          find.text('Demo verification: use 123456. No email or SMS is sent.'),
          findsOneWidget,
        );
        await tester.tap(find.widgetWithText(TextButton, 'Dismiss'));
        await tester.pumpAndSettle();
        await enter(tester, code(), '000000');
        await tap(tester, button('Verify'));
        expect(store.error, isNotNull);
        expect(tester.widget<AppButton>(button('Verify')).onPressed, isNull);
        expect(await store.verify(), false);
        await enter(tester, code(), '123456');
        repository.behavior.failNext();
        await tap(tester, button('Verify'));
        expect(store.stage, InvestorSignupStage.verification);
        expect(store.codeRejected, false);
        expect(tester.widget<AppButton>(button('Verify')).onPressed, isNotNull);
        await tap(tester, button('Verify'));
        expect(find.text('You’re verified'), findsOneWidget);
        await tap(tester, button('Continue'));
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await enter(tester, code(), '9876');
        await tap(tester, button('Continue'));
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        expect(store.stage, InvestorSignupStage.biometrics);
        await tap(tester, button('Continue'));
        expect(store.stage, InvestorSignupStage.fingerprint);
        await tap(tester, find.text('Terms'));
        expect(find.text('Terms & Condition'), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tap(tester, find.bySemanticsLabel('Simulate fingerprint setup'));
        await tap(tester, button('Continue'));
        expect(store.stage, InvestorSignupStage.faceCamera);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(store.stage, InvestorSignupStage.face);
        await tap(tester, button('Continue'));
        await tap(tester, find.bySemanticsLabel('Simulate face capture'));
        expect(store.stage, InvestorSignupStage.faceComplete);
        expect(store.faceProgress, 100);
        await tap(tester, button('Continue'));
        await tap(tester, find.bySemanticsLabel('Close'));
        expect(find.text('Account ready'), findsOneWidget);
        expect(find.text('Verification in progress'), findsNothing);
        await tap(tester, button('Continue'));
        repository.behavior.failNext();
        await tap(tester, button('Continue'));
        expect(dependencies.session.isAuthenticated, false);
        expect(find.text('Unable to connect. Please try again.'), findsWidgets);
        await tap(tester, button('Continue'));
        expect(dependencies.session.isAuthenticated, true);
        expect(dependencies.session.user!.entity, EntityType.company);
        expect(dependencies.session.experience, Experience.investor);
        expect(
          dependencies.container<TransactionAuthorization>().verifyPin('9876'),
          true,
        );
        expect(store.isDisposed, true);
        expect(store.values, isEmpty);
        expect(store.representatives, isEmpty);
        expect(store.pin, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Signup holds its draft and route while an account request is pending',
    (tester) async {
      final (dependencies, router) = await mount(
        tester,
        393,
        delay: const Duration(milliseconds: 350),
      );
      final store = tester
          .widget<InvestorSignupScreen>(find.byType(InvestorSignupScreen))
          .store;
      for (final entry in {
        'Full Name': 'New Investor',
        'Email Address': 'new@example.test',
        'Phone Number': '821234567',
        'Password': 'Password123!',
        'Confirm Password': 'Password123!',
      }.entries) {
        await enter(tester, field(entry.key), entry.value);
      }
      await tester.ensureVisible(button('Create account'));
      await tester.tap(button('Create account'));
      await tester.pump();
      expect(store.busy, true);
      store.edit('name', 'Late edit');
      store.setCountry('GB', '+44');
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/investor/create-account',
      );
      expect(store.values['name'], 'New Investor');
      expect(store.countryCode, 'US');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(store.stage, InvestorSignupStage.verification);
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(store.stage, InvestorSignupStage.details);
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: field('Full Name'),
                matching: find.byType(EditableText),
              ),
            )
            .controller
            .text,
        'New Investor',
      );
      expect(dependencies.session.isAuthenticated, false);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'Signup blocks skipped stages, invalid representative indices and disposed edits',
    () async {
      final session = SessionService();
      final authorization = MockTransactionAuthorization(session);
      final store = InvestorSignupStore(
        MockAuthRepository(MockBehavior(delay: Duration.zero)),
        session,
        authorization,
        entity: EntityType.company,
      );
      store.removeRepresentative(-1);
      store.removeRepresentative(4);
      expect(store.representatives.length, 1);
      store.beginFace();
      store.captureFace();
      store.beginFingerprint();
      store.completeSecurity();
      expect(store.stage, InvestorSignupStage.details);
      expect(store.continuePin(), false);
      expect(await store.finish(), false);
      store.dispose();
      store.edit('password', 'Sensitive123!');
      store.setCode('123456');
      store.setPin('1234');
      store.addRepresentative();
      store.togglePassword();
      expect(store.values, isEmpty);
      expect(store.representatives, isEmpty);
      expect(store.code, isEmpty);
      expect(store.pin, isEmpty);
      expect(store.passwordVisible, false);
      expect(session.isAuthenticated, false);
      authorization.dispose();
      session.dispose();
    },
  );
}
