import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/features/authentication/presentation/recovery_screen.dart';
import 'package:developify_mobile/features/profile/domain/profile_repository.dart';
import 'package:developify_mobile/features/profile/presentation/widgets/security_device_card.dart';
import 'package:developify_mobile/features/profile/presentation/widgets/security_success_sheet.dart';
import 'package:developify_mobile/features/profile/presentation/widgets/transaction_pin_field.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'helpers/fidelity_capture.dart';
import 'helpers/fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  void viewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 56, bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  const user = AppUser(
    id: 'local-landowner',
    name: 'Babatunde Yusuf',
    email: 'bafreka@gmail.com',
  );

  testWidgets('Security menu, biometric persistence and device removal', (
    tester,
  ) async {
    viewport(tester);
    final deps = await AppDependencies.create(
      environment: const AppEnvironment(mockDelay: Duration.zero),
    );
    deps.session.signIn(user);
    final router = createAppRouter(deps, initialLocation: '/profile/security');
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: DevelopifyApp(dependencies: deps, router: router),
      ),
    );
    await tester.pumpAndSettle();
    for (final id in [12951, 13137, 13469, 14084, 14178]) {
      await captureFidelity(tester, key, '4105-$id');
    }
    await tester.tap(find.text('Biometric'));
    await tester.pumpAndSettle();
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('profile-menu-Use for login')))
          .dy,
      closeTo(144, 1),
    );
    await captureFidelity(tester, key, '4105-13564');
    for (final label in [
      'Use for login',
      'Use for investment',
      'Use for withdrawals',
    ]) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    await captureFidelity(tester, key, '4105-13629');
    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Biometric'));
    await tester.pumpAndSettle();
    expect(
      deps
          .container<ProfileRepository>()
          .securityPreferences
          .biometrics
          .values
          .every((v) => v),
      isTrue,
    );
    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Devices and sessions'));
    await tester.pumpAndSettle();
    expect(find.byType(SecurityDeviceCard), findsNWidgets(3));
    await captureFidelity(tester, key, '4105-13046');
    await tester.tap(find.bySemanticsLabel('Remove previous device').first);
    await tester.pumpAndSettle();
    expect(find.byType(SecurityDeviceCard), findsNWidgets(2));
    tester.view.physicalSize = const Size(360, 780);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    await deps.dispose();
  });

  testWidgets(
    'Transaction PIN confirmation, entry, success and keyboard safety',
    (tester) async {
      viewport(tester);
      final deps = await AppDependencies.create(
        environment: const AppEnvironment(mockDelay: Duration.zero),
      );
      deps.session.signIn(user);
      final router = createAppRouter(
        deps,
        initialLocation: '/profile/security/pin',
      );
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: DevelopifyApp(dependencies: deps, router: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Enter Password')).dy,
        closeTo(142, 1),
      );
      await captureFidelity(tester, key, '4105-13232');
      await tester.enterText(
        find.byKey(const ValueKey('field-Enter Current Password')),
        'Min. of 8 characters',
      );
      await tester.tap(find.byTooltip('Show password'));
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-13274');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.byType(TransactionPinField), findsOneWidget);
      await captureFidelity(tester, key, '4105-13316');
      await tester.enterText(
        find.byKey(const ValueKey('transaction-pin-field')),
        '1234',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-13361');
      tester.view.viewInsets = const FakeViewPadding(bottom: 304);
      await tester.pumpAndSettle();
      expect(
        tester.getBottomLeft(find.widgetWithText(AppButton, 'Continue')).dy,
        lessThanOrEqualTo(548),
      );
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.byType(SecuritySuccessSheet), findsOneWidget);
      await captureFidelity(tester, key, '4105-13406');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Security'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await deps.dispose();
    },
  );

  testWidgets(
    'SMS and authenticator setup stages, invalid codes and 2FA persistence',
    (tester) async {
      viewport(tester);
      final deps = await AppDependencies.create(
        environment: const AppEnvironment(mockDelay: Duration.zero),
      );
      deps.session.signIn(user);
      final router = createAppRouter(
        deps,
        initialLocation: '/profile/security/2fa',
      );
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: DevelopifyApp(dependencies: deps, router: router),
        ),
      );
      await tester.pumpAndSettle();
      for (final id in [14460, 14814]) {
        await captureFidelity(tester, key, '4105-$id');
      }
      await tester.tap(find.text('SMS Authentication'));
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-14556');
      await tester.enterText(
        find.byKey(const ValueKey('field-Phone Number')),
        '9012737476172',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-14594');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-14513');
      final codeInput = find.descendant(
        of: find.byType(CodeField),
        matching: find.byType(TextField),
      );
      await tester.enterText(codeInput, '000000');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-14632');
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();
      expect(tester.widget<CodeField>(find.byType(CodeField)).invalid, isTrue);
      await captureFidelity(tester, key, '4105-14731');
      await tester.enterText(codeInput, '123456');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-14675');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(
        deps
            .container<ProfileRepository>()
            .securityPreferences
            .twoFactorEnabled,
        isTrue,
      );
      for (final id in [14272, 14366]) {
        await captureFidelity(tester, key, '4105-$id');
      }
      router.go('/profile/security/2fa/app');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('authenticator-setup-code')),
        '284091',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-14774');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Verify Setup'), findsOneWidget);
      await captureFidelity(tester, key, '4105-14867');
      await tester.enterText(codeInput, '000000');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-14910');
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-15009');
      await tester.enterText(codeInput, '123456');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-14953');
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await deps.dispose();
    },
  );
}
