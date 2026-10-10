import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/features/authentication/presentation/signup_screen.dart';
import 'package:developify_mobile/features/onboarding/presentation/onboarding_terms_screen.dart';
import 'helpers/fidelity_capture.dart';
import 'helpers/fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  testWidgets('Terms consent, authored layout and scrollable large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 56, bottom: 20);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final deps = await AppDependencies.create(
      environment: const AppEnvironment(mockDelay: Duration.zero),
    );
    final router = createAppRouter(deps, initialLocation: '/onboarding-terms');
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: DevelopifyApp(dependencies: deps, router: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingTermsScreen), findsOneWidget);
    final continueButton = find.byKey(const ValueKey('terms-continue'));
    expect(tester.widget<AppButton>(continueButton).onPressed, isNull);
    await captureFidelity(tester, key, '4105-7101');
    expect(
      tester.getTopLeft(find.text('Terms of Service')).dy,
      closeTo(129, 1),
    );
    expect(tester.getTopLeft(find.text('Overview')).dy, closeTo(183, 1));
    expect(tester.getTopLeft(continueButton).dy, closeTo(784, 1));
    await tester.tap(find.byKey(const ValueKey('terms-declaration')));
    await tester.pumpAndSettle();
    await captureFidelity(tester, key, '4105-7155');
    expect(tester.widget<AppButton>(continueButton).onPressed, isNotNull);
    tester.view.physicalSize = const Size(360, 780);
    tester.view.padding = const FakeViewPadding(top: 32, bottom: 34);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('landowner-terms-content')),
      const Offset(0, -450),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();
    expect(find.byType(SignupScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    await deps.dispose();
  });
}
