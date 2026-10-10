import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/features/authentication/presentation/auth_screen.dart';
import 'package:developify_mobile/features/authentication/presentation/recovery_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/investor_signup_screen.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investor_signup_store.dart';
import '../test/helpers/native_assets.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  var converted = false;
  setUp(() => converted = false);

  Future<AppDependencies> mount(WidgetTester tester) async {
    final dependencies = await AppDependencies.create(
      environment: const AppEnvironment(mockDelay: Duration.zero),
    );
    dependencies.session.completeOnboarding();
    final router = createAppRouter(
      dependencies,
      initialLocation: '/investor/welcome',
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
    return dependencies;
  }

  Finder button(String label) => find.widgetWithText(AppButton, label).last;
  Finder field(String label) => find.byKey(ValueKey('field-$label'));
  Finder code() => find.descendant(
    of: find.byType(CodeField),
    matching: find.byType(TextField),
  );

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  Future<void> enter(WidgetTester tester, Finder target, String value) async {
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.enterText(target, value);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    await settleNativeImages(tester);
    if (defaultTargetPlatform == TargetPlatform.android && !converted) {
      await binding.convertFlutterSurfaceToImage();
      converted = true;
      await tester.pump();
    }
    debugPrint('Native authentication checkpoint: $name');
    await binding.takeScreenshot(name);
  }

  testWidgets('Native recovery notice preserves Back and completes recovery', (
    tester,
  ) async {
    final dependencies = await mount(tester);
    await tap(tester, button('I already have an account'));
    await tap(tester, find.text('Forgot Password?'));
    final store = tester
        .widget<RecoveryScreen>(find.byType(RecoveryScreen))
        .store;
    await enter(tester, field('Email Address'), 'Thomashook@gmail.com');
    await tap(tester, button('Continue'));
    expect(find.byType(MaterialBanner), findsOneWidget);
    await capture(tester, 'recovery-simulation-notice');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(store.stage, 0);
    expect(find.byType(MaterialBanner), findsNothing);
    await tap(tester, button('Continue'));
    await tap(tester, find.widgetWithText(TextButton, 'Dismiss'));
    await enter(tester, code(), '000000');
    await tap(tester, button('Continue'));
    expect(store.codeRejected, true);
    await enter(tester, code(), '123456');
    await tap(tester, button('Continue'));
    await enter(tester, field('Password'), 'Password123!');
    await enter(tester, field('Confirm new Password'), 'Password123!');
    await tap(tester, button('Continue'));
    expect(store.password, isEmpty);
    expect(store.confirmation, isEmpty);
    await capture(tester, 'recovery-complete');
    await tap(tester, button('Login Now'));
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(dependencies.session.isAuthenticated, false);
  });

  testWidgets(
    'Native signup keeps Back, biometrics and face completion intact',
    (tester) async {
      final dependencies = await mount(tester);
      await tap(tester, button('Create account'));
      await tap(tester, find.text('Natural Person'));
      await tap(tester, button('Use this entity'));
      final store = tester
          .widget<InvestorSignupScreen>(find.byType(InvestorSignupScreen))
          .store;
      for (final entry in {
        'Full Name': 'Native Investor',
        'Email Address': 'native-investor@example.test',
        'Phone Number': '821234567',
        'Password': 'Password123!',
        'Confirm Password': 'Password123!',
      }.entries) {
        await enter(tester, field(entry.key), entry.value);
      }
      await tap(tester, button('Create account'));
      expect(store.stage, InvestorSignupStage.verification);
      expect(find.byType(MaterialBanner), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(store.stage, InvestorSignupStage.details);
      expect(store.values['name'], 'Native Investor');
      await tap(tester, button('Create account'));
      await tap(tester, find.widgetWithText(TextButton, 'Dismiss'));
      await enter(tester, code(), '123456');
      await tap(tester, button('Verify'));
      await capture(tester, 'signup-verified');
      await tap(tester, button('Continue'));
      await enter(tester, code(), '9876');
      await tap(tester, button('Continue'));
      await capture(tester, 'signup-biometrics');
      await tap(tester, button('Continue'));
      await tap(tester, find.bySemanticsLabel('Simulate fingerprint setup'));
      await tap(tester, button('Continue'));
      expect(store.stage, InvestorSignupStage.faceCamera);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(store.stage, InvestorSignupStage.face);
      await capture(tester, 'signup-face-setup');
      await tap(tester, button('Continue'));
      await tap(tester, find.bySemanticsLabel('Simulate face capture'));
      for (
        var attempt = 0;
        attempt < 50 && store.faceProgress < 100;
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(store.faceProgress, 100);
      expect(store.stage, InvestorSignupStage.faceComplete);
      await capture(tester, 'signup-face-completed');
      await tap(tester, button('Continue'));
      await tap(tester, button('Continue'));
      expect(dependencies.session.isAuthenticated, true);
      expect(store.isDisposed, true);
      expect(store.values, isEmpty);
      expect(store.pin, isEmpty);
      await capture(tester, 'signup-home');
    },
  );
}
