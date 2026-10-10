import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/core/widgets/password_visibility_button.dart';
import 'package:developify_mobile/features/authentication/presentation/auth_screen.dart';
import 'package:developify_mobile/features/authentication/presentation/recovery_screen.dart';
import 'package:developify_mobile/features/authentication/presentation/widgets/auth_social_button.dart';
import 'package:developify_mobile/features/authentication/presentation/widgets/recovery_success_sheet.dart';
import 'helpers/fidelity_capture.dart';
import 'helpers/fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  void referenceViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 56, bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  testWidgets('Sign-in, password visibility and returning account states', (
    tester,
  ) async {
    referenceViewport(tester);
    final deps = await AppDependencies.create(
      environment: const AppEnvironment(mockDelay: Duration.zero),
    );
    final router = createAppRouter(deps, initialLocation: '/sign-in');
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: DevelopifyApp(dependencies: deps, router: router),
      ),
    );
    await tester.pumpAndSettle();
    await captureFidelity(tester, key, '4105-7722');
    expect(tester.getTopLeft(find.text('Email Address')).dy, closeTo(273, 1));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('auth-submit'))).dy,
      closeTo(487, 1),
    );
    expect(
      tester.getTopLeft(find.byType(AuthSocialButton).first).dy,
      closeTo(640, 1),
    );
    await tester.enterText(
      find.byKey(const ValueKey('field-Email Address')),
      'Thomashook@gmail.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('field-Password')),
      r'Winner2026$$$',
    );
    final passwordField = find.descendant(
      of: find.byKey(const ValueKey('field-Password')),
      matching: find.byType(EditableText),
    );
    final focus = tester.widget<EditableText>(passwordField).focusNode;
    expect(focus.hasFocus, isTrue);
    await tester.tap(find.byType(PasswordVisibilityButton));
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    expect(tester.widget<EditableText>(passwordField).obscureText, isFalse);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await captureFidelity(tester, key, '4105-7781');
    // Sign in and then sign out to set returning user
    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pumpAndSettle();
    // After sign-in, app should navigate away from auth. Return to sign-in and visit welcome-back.
    if (router.canPop()) router.pop();
    await tester.pumpAndSettle();
    // Sign out to record returning user
    deps.session.signOut();
    await tester.pumpAndSettle();
    router.go('/welcome-back');
    await tester.pumpAndSettle();
    await captureFidelity(tester, key, '4105-7606');
    expect(
      tester.getTopLeft(find.text('Welcome Babatunde')).dy,
      closeTo(120, 1),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('auth-submit'))).dy,
      closeTo(368, 1),
    );
    await tester.enterText(
      find.byKey(const ValueKey('field-Password')),
      r'Winner2026$$$',
    );
    await tester.tap(find.byType(PasswordVisibilityButton));
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await captureFidelity(tester, key, '4105-7646');
    tester.view.physicalSize = const Size(360, 780);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const ValueKey('auth-submit')));
    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pumpAndSettle();
    expect(deps.session.isAuthenticated, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    await deps.dispose();
  });

  testWidgets(
    'Recovery retains input, handles rejection, resends and completes',
    (tester) async {
      referenceViewport(tester);
      final deps = await AppDependencies.create(
        environment: const AppEnvironment(mockDelay: Duration.zero),
      );
      final router = createAppRouter(deps, initialLocation: '/forgot-password');
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: DevelopifyApp(dependencies: deps, router: router),
        ),
      );
      await tester.pumpAndSettle();
      final store = tester
          .widget<RecoveryScreen>(find.byType(RecoveryScreen))
          .store;
      await captureFidelity(tester, key, '4105-6238');
      expect(tester.getTopLeft(find.text('Email Address')).dy, closeTo(300, 1));
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('recovery-continue'))).dy,
        closeTo(756, 1),
      );
      await tester.enterText(
        find.byKey(const ValueKey('field-Email Address')),
        'Thomashook@gmail.com',
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 304);
      tester.view.padding = const FakeViewPadding(top: 56);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('recovery-continue'))).dy,
        closeTo(424, 1),
      );
      await captureFidelity(tester, key, '4105-6275');
      tester.view.viewInsets = const FakeViewPadding();
      tester.view.padding = const FakeViewPadding(top: 56, bottom: 34);
      await tester.tap(find.byKey(const ValueKey('recovery-continue')));
      await tester.pumpAndSettle();
      expect(store.stage, 1);
      expect(store.maskedEmail, 'T***hook@gmail.com');
      await captureFidelity(tester, key, '4105-6439');
      expect(tester.getTopLeft(find.byType(CodeField)).dy, closeTo(265, 1));
      final codeInput = find.descendant(
        of: find.byType(CodeField),
        matching: find.byType(TextField),
      );
      await tester.enterText(codeInput, '000000');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-6477');
      await tester.tap(find.byKey(const ValueKey('recovery-continue')));
      await tester.pumpAndSettle();
      expect(store.codeRejected, isTrue);
      expect(store.canContinue, isFalse);
      await captureFidelity(tester, key, '4105-6771');
      await tester.pump(const Duration(seconds: 49));
      await tester.pump();
      expect(store.resendSeconds, 0);
      await tester.tap(find.textContaining('Resend code'));
      await tester.pumpAndSettle();
      expect(store.code, isEmpty);
      expect(store.codeRejected, isFalse);
      await tester.enterText(codeInput, '123456');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('recovery-continue')));
      await tester.pumpAndSettle();
      expect(store.stage, 2);
      await captureFidelity(tester, key, '4105-6515');
      expect(tester.getTopLeft(find.text('Password')).dy, closeTo(252, 1));
      await tester.enterText(
        find.byKey(const ValueKey('field-Password')),
        r'Winner2026$$$',
      );
      await tester.enterText(
        find.byKey(const ValueKey('field-Confirm new Password')),
        r'Winner2026$$$',
      );
      await tester.tap(find.byType(PasswordVisibilityButton).first);
      await tester.tap(find.byType(PasswordVisibilityButton).last);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-6563');
      await captureFidelity(tester, key, '4105-6611');
      expect(store.canContinue, isTrue);
      runInAction(() => store.passwordRejected = true);
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-6723');
      expect(store.canContinue, isFalse);
      expect(store.password, r'Winner2026$$$');
      store.setPassword(r'Winner2026$$$');
      await tester.pumpAndSettle();
      expect(store.passwordRejected, isFalse);
      await tester.tap(find.byKey(const ValueKey('recovery-continue')));
      await tester.pumpAndSettle();
      expect(find.byType(RecoverySuccessSheet), findsOneWidget);
      await captureFidelity(tester, key, '4105-6659');
      expect(
        tester.getTopLeft(find.byType(RecoverySuccessSheet)).dy,
        closeTo(316, 1),
      );
      await tester.tap(find.text('Login Now'));
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(store.password, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await deps.dispose();
    },
  );
}
