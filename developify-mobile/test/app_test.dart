import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'helpers/fonts.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/bootstrap.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/core/network/api_client.dart';
import 'package:developify_mobile/core/services/push_notification_service.dart';
import 'package:developify_mobile/core/services/telemetry.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/features/authentication/presentation/stores/auth_store.dart';
import 'package:developify_mobile/features/authentication/presentation/recovery_screen.dart';
import 'package:developify_mobile/features/landowner/domain/landowner_repository.dart';
import 'package:developify_mobile/features/landowner/presentation/stores/submission_store.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

Future<void> captureScreenshot(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  if (!const bool.fromEnvironment('CAPTURE_SCREENSHOTS')) return;
  await tester.runAsync(() async {
    await Future.wait([
      for (final asset in AppAssets.rasterImages)
        precacheImage(AssetImage(asset), key.currentContext!),
    ]);
  });
  await tester.pumpAndSettle();
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  debugDisableShadows = false;
  boundary.markNeedsPaint();
  await tester.pump();
  try {
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory('build/test-artifacts/reference').createSync(recursive: true);
      File(
        'build/test-artifacts/reference/${name.replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '_')}.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  } finally {
    debugDisableShadows = true;
    boundary.markNeedsPaint();
    await tester.pump();
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  setUp(() {
    binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  });
  tearDown(binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
  test('Bootstrap and DI work without external service credentials', () async {
    final dependencies = await bootstrap(
      environment: const AppEnvironment(mockDelay: Duration.zero),
      launch: false,
    );
    expect(dependencies.telemetry.firebaseConfigured, false);
    expect(dependencies.telemetry.analytics, isA<NoopAnalytics>());
    expect(dependencies.push.isConfigured, false);
    expect(await dependencies.push.requestPermission(), false);
    expect(dependencies.container<ApiClient>(), isNotNull);
    final first = dependencies.container<AuthStore>();
    final second = dependencies.container<AuthStore>();
    expect(identical(first, second), false);
    first.dispose();
    second.dispose();
    await dependencies.dispose();
  });
  test(
    'Push payload contract only accepts supported serializable destinations',
    () {
      expect(
        PushTarget.fromPlaceholder({
          'destination': 'property',
          'id': '../secret',
        }),
        isNull,
      );
      expect(
        PushTarget.fromPlaceholder({
          'destination': 'property',
          'id': 'ridge-live',
        })!.id,
        'ridge-live',
      );
      expect(PushTarget.fromPlaceholder({'destination': 'unknown'}), isNull);
    },
  );
  testWidgets(
    'Startup, onboarding and authentication redirect retain requested route',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final deps = await AppDependencies.create(
        environment: const AppEnvironment(mockDelay: Duration.zero),
      );
      final router = createAppRouter(
        deps,
        initialLocation: '/profile/security',
      );
      await tester.pumpWidget(
        DevelopifyApp(dependencies: deps, router: router),
      );
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/onboarding');
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(find.text('List my land'), findsOneWidget);
      await tester.tap(find.text('I already have an account'));
      await tester.pumpAndSettle();
      deps.session.signIn(
        const AppUser(
          id: 'test',
          name: 'Babatunde Yusuf',
          email: 'owner@example.test',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/profile/security',
      );
      expect(find.text('Biometric'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await deps.dispose();
    },
  );
  testWidgets('Primary routes render at the inspected 393 by 852 size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 56, bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    final deps = await AppDependencies.create(
      environment: const AppEnvironment(mockDelay: Duration.zero),
    );
    deps.session.signIn(
      const AppUser(
        id: 'test',
        name: 'Babatunde Yusuf',
        email: 'owner@example.test',
      ),
    );
    final router = createAppRouter(deps, initialLocation: '/home');
    final captureKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: DevelopifyApp(dependencies: deps, router: router),
      ),
    );
    for (final path in [
      '/home',
      '/properties',
      '/earnings',
      '/notifications',
      '/notifications/approved',
      '/support/chat',
      '/properties/ridge-live',
      for (var i = 1; i <= 9; i++) '/submit/$i?draft=marula-draft',
      '/profile',
      '/profile/edit',
      '/profile/payout',
      '/profile/payout/new',
      '/profile/notifications',
      '/profile/language',
      '/profile/security',
      '/profile/security/password',
      '/profile/security/pin',
      '/profile/security/biometrics',
      '/profile/security/devices',
      '/profile/security/2fa',
      '/profile/security/2fa/sms',
      '/profile/security/2fa/app',
      '/profile/help',
      '/profile/about',
      '/profile/privacy',
      '/profile/terms',
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: path);
      await captureScreenshot(tester, captureKey, path);
    }
    router.go('/properties/ridge-live');
    await tester.pumpAndSettle();
    expect(find.text('Ridge Site 12'), findsWidgets);
    router.go('/properties/sea-point');
    await tester.pumpAndSettle();
    expect(find.text('Sea Point Sunset Rd'), findsWidgets);
    router.go('/home');
    await tester.pumpAndSettle();
    unawaited(router.push('/experience'));
    await tester.pumpAndSettle();
    await captureScreenshot(tester, captureKey, 'experience-switch');
    await tester.tap(find.text('Investor'));
    await tester.pumpAndSettle();
    await captureScreenshot(tester, captureKey, 'experience-investor');
    expect(router.routeInformationProvider.value.uri.path, '/investor/home');
    expect(deps.session.experience, Experience.investor);
    expect(deps.session.isAuthenticated, true);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    await deps.dispose();
  });
  testWidgets('Reduced motion removes additional animation delays', (
    tester,
  ) async {
    late Duration duration;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            duration = AppDurations.motion(context, AppDurations.page);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(duration, Duration.zero);
  });

  testWidgets('Public screens and recovery states render at reference size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 56, bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    final deps = await AppDependencies.create(
      environment: const AppEnvironment(mockDelay: Duration.zero),
    );
    final router = createAppRouter(deps, initialLocation: '/onboarding');
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: DevelopifyApp(dependencies: deps, router: router),
      ),
    );
    for (var page = 1; page <= 4; page++) {
      await tester.pumpAndSettle();
      await captureScreenshot(tester, key, 'onboarding-$page');
      expect(tester.takeException(), isNull, reason: 'onboarding-$page');
      await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    }
    await tester.pumpAndSettle();
    await captureScreenshot(tester, key, 'welcome');
    await tester.tap(find.text('List my land'));
    await tester.pumpAndSettle();
    await captureScreenshot(tester, key, 'signup');
    router.go('/onboarding-terms');
    await tester.pumpAndSettle();
    await captureScreenshot(tester, key, 'onboarding-terms');
    for (final path in ['/sign-in', '/welcome-back', '/forgot-password']) {
      router.go(path);
      await tester.pumpAndSettle();
      await captureScreenshot(tester, key, path);
      expect(tester.takeException(), isNull, reason: path);
    }
    final recovery = tester
        .widget<RecoveryScreen>(find.byType(RecoveryScreen))
        .store;
    recovery.setEmail('owner@example.test');
    await tester.runAsync(recovery.submit);
    await tester.pumpAndSettle();
    await captureScreenshot(tester, key, 'recovery-code');
    recovery.setCode('000000');
    await tester.runAsync(recovery.submit);
    await tester.pumpAndSettle();
    await captureScreenshot(tester, key, 'recovery-code-error');
    recovery.setCode('123456');
    await tester.runAsync(recovery.submit);
    await tester.pumpAndSettle();
    await captureScreenshot(tester, key, 'recovery-password');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    await deps.dispose();
  });

  for (final device in [
    (const Size(320, 568), 1.0),
    (const Size(393, 852), 1.3),
    (const Size(430, 932), 1.3),
  ]) {
    testWidgets('Core layouts fit ${device.$1} at text scale ${device.$2}', (
      tester,
    ) async {
      tester.view.physicalSize = device.$1;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = device.$2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final deps = await AppDependencies.create(
        environment: const AppEnvironment(mockDelay: Duration.zero),
      );
      deps.session.signIn(
        const AppUser(
          id: 'test',
          name: 'Babatunde Yusuf',
          email: 'owner@example.test',
        ),
      );
      final router = createAppRouter(deps, initialLocation: '/home');
      await tester.pumpWidget(
        DevelopifyApp(dependencies: deps, router: router),
      );
      for (final path in [
        '/home',
        '/properties',
        '/earnings',
        '/submit/1',
        '/submit/8',
        '/profile',
        '/profile/payout/new',
        '/profile/security',
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: path);
      }
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await deps.dispose();
    });
  }

  testWidgets(
    'Submission confirmation dashboard action and system back preserve destinations',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final deps = await AppDependencies.create(
        environment: const AppEnvironment(mockDelay: Duration.zero),
      );
      deps.session.signIn(
        const AppUser(
          id: 'test',
          name: 'Babatunde Yusuf',
          email: 'owner@example.test',
        ),
      );
      final draft = SubmissionStore(
        deps.container<LandownerRepository>(),
        'marula-draft',
      );
      draft.addDocument('identity');
      draft.update(draft.draft.copyWith(accepted: true));
      draft.save();
      draft.dispose();
      final router = createAppRouter(
        deps,
        initialLocation: '/submit/9?draft=marula-draft',
      );
      await tester.pumpWidget(
        DevelopifyApp(dependencies: deps, router: router),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Submitted!'), findsOneWidget);
      await tester.tap(find.text('Back to dahsboard'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/home');
      await tester.tap(find.text('Properties').last);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/properties');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/home');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await deps.dispose();
    },
  );

  for (final scenario in [MockScenario.empty, MockScenario.networkFailure]) {
    testWidgets('Visible ${scenario.name} states and retry', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 56, bottom: 34);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      final deps = await AppDependencies.create(
        environment: AppEnvironment(
          mockDelay: Duration.zero,
          mockScenario: scenario,
        ),
      );
      deps.session.signIn(
        const AppUser(
          id: 'test',
          name: 'Babatunde Yusuf',
          email: 'owner@example.test',
        ),
      );
      final router = createAppRouter(deps, initialLocation: '/home');
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: DevelopifyApp(dependencies: deps, router: router),
        ),
      );
      await tester.pumpAndSettle();
      await captureScreenshot(tester, key, 'home-${scenario.name}');
      if (scenario == MockScenario.networkFailure) {
        expect(find.text('Try again'), findsOneWidget);
        await tester.tap(find.text('Try again'));
        await tester.pumpAndSettle();
        expect(find.text('Ridge Site 12'), findsWidgets);
        await captureScreenshot(tester, key, 'home-retry-success');
      } else {
        for (final path in [
          '/properties',
          '/earnings',
          '/notifications',
          '/profile/payout',
        ]) {
          router.go(path);
          await tester.pumpAndSettle();
          await captureScreenshot(tester, key, '$path-empty');
          expect(tester.takeException(), isNull, reason: path);
        }
        router.go('/notifications');
        await tester.pumpAndSettle();
        expect(find.text("You're all caught up"), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await deps.dispose();
    });
  }
}
