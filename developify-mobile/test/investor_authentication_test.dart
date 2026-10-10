import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/features/authentication/data/mock_auth_repository.dart';
import 'package:developify_mobile/features/authentication/domain/auth_repository.dart';
import 'package:developify_mobile/features/authentication/presentation/auth_screen.dart';
import 'package:developify_mobile/features/authentication/presentation/recovery_screen.dart';
import 'helpers/fonts.dart';

void main() {
  setUpAll(loadAppFonts);
  for (final width in [360.0, 393.0, 430.0]) {
    testWidgets(
      'Investor recovery and sign-in preserve pending requests and clear credentials at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 852);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 56, bottom: 34);
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final dependencies = await AppDependencies.create(
          environment: const AppEnvironment(
            mockDelay: Duration(milliseconds: 350),
          ),
        );
        dependencies.session.completeOnboarding();
        final router = createAppRouter(
          dependencies,
          initialLocation: '/investor/forgot-password',
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
        final repository =
            dependencies.container<AuthRepository>() as MockAuthRepository;
        final store = tester
            .widget<RecoveryScreen>(find.byType(RecoveryScreen))
            .store;
        Finder field(String label) => find.byKey(ValueKey('field-$label'));
        Finder button(String label) =>
            find.widgetWithText(AppButton, label).last;
        Finder code() => find.descendant(
          of: find.byType(CodeField),
          matching: find.byType(TextField),
        );
        Future<void> enter(Finder finder, String value) async {
          await tester.ensureVisible(finder);
          await tester.enterText(finder, value);
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
        }

        Future<void> tap(Finder finder) async {
          await tester.ensureVisible(finder);
          await tester.tap(finder);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: finder.toString());
        }

        await enter(field('Email Address'), 'Thomashook@gmail.com');
        repository.behavior.failNext();
        await tester.ensureVisible(button('Continue'));
        await tester.tap(button('Continue'));
        await tester.pump();
        expect(store.status, LoadStatus.loading);
        await tester.tap(find.bySemanticsLabel('Back'));
        await tester.binding.handlePopRoute();
        store.setEmail('late@example.test');
        expect(store.email, 'Thomashook@gmail.com');
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
        expect(
          find.text('Unable to connect. Please try again.'),
          findsOneWidget,
        );
        expect(store.stage, 0);
        await tap(button('Continue'));
        await enter(code(), '000000');
        await tap(button('Continue'));
        expect(store.codeRejected, true);
        await tap(find.bySemanticsLabel('Back'));
        expect(store.stage, 0);
        expect(store.code, isEmpty);
        await tap(button('Continue'));
        await enter(code(), '123456');
        await tap(button('Continue'));
        expect(store.stage, 2);
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await enter(field('Password'), 'Password123!');
        await enter(field('Confirm new Password'), 'Mismatch123!');
        expect(tester.widget<AppButton>(button('Continue')).onPressed, isNull);
        await enter(field('Confirm new Password'), 'Password123!');
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        repository.behavior.failNext();
        await tap(button('Continue'));
        expect(store.stage, 2);
        await tap(button('Continue'));
        expect(store.password, isEmpty);
        expect(store.confirmation, isEmpty);
        expect(
          tester
              .widgetList<EditableText>(find.byType(EditableText))
              .every(
                (field) => !field.controller.text.contains('Password123!'),
              ),
          true,
        );
        await tap(button('Login Now'));
        expect(store.isDisposed, true);
        expect(find.byType(AuthScreen), findsOneWidget);
        final auth = tester.widget<AuthScreen>(find.byType(AuthScreen)).store;
        await enter(field('Email Address'), 'Thomashook@gmail.com');
        await enter(field('Password'), 'Password123!');
        await tester.ensureVisible(button('Sign In'));
        await tester.tap(button('Sign In'));
        await tester.pump();
        expect(auth.status, LoadStatus.loading);
        await tester.tap(find.bySemanticsLabel('Back'));
        await tester.binding.handlePopRoute();
        await tester.tap(find.text('Forgot Password?'));
        auth.setPassword('Late123!');
        expect(auth.password, 'Password123!');
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
        expect(dependencies.session.isAuthenticated, true);
        expect(auth.isDisposed, true);
        expect(auth.password, isEmpty);
        auth.setPassword('Disposed123!');
        expect(auth.password, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
