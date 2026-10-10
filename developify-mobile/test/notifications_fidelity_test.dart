import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/features/landowner/domain/property.dart';
import 'package:developify_mobile/features/landowner/presentation/home_screen.dart';
import 'package:developify_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:developify_mobile/features/notifications/presentation/chat_screen.dart';
import 'package:developify_mobile/features/shared/presentation/experience_screen.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'helpers/fidelity_capture.dart';
import 'helpers/fonts.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  setUp(
    () => binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true),
  );
  tearDown(() {
    binding.platformDispatcher.clearAccessibilityFeaturesTestValue();
    binding.platformDispatcher.clearTextScaleFactorTestValue();
    final view = binding.platformDispatcher.implicitView!;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
    view.resetPadding();
  });
  void viewport(
    WidgetTester tester, [
    double height = 852,
    double width = 393,
  ]) {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 56, bottom: 34);
  }

  const user = AppUser(
    id: 'owner',
    name: 'Babatunde Yusuf',
    email: 'owner@example.test',
  );
  testWidgets(
    'Notifications, unread transitions, funding target and local chat',
    (tester) async {
      viewport(tester);
      final deps = await AppDependencies.create(
        environment: const AppEnvironment(mockDelay: Duration.zero),
      );
      deps.session.signIn(user);
      final router = createAppRouter(deps, initialLocation: '/notifications');
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: DevelopifyApp(dependencies: deps, router: router),
        ),
      );
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-18266');
      expect(
        tester.getTopLeft(find.byType(NotificationRow).first).dy,
        closeTo(163, 1),
      );
      await tester.tap(find.text('Approved'));
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-18339');
      expect(tester.getTopLeft(find.byType(FundingPanel)).dy, closeTo(276, 1));
      await tester.tap(find.text('Track funding progress'));
      await tester.pumpAndSettle();
      expect(find.text('Sea Point Sunset Rd'), findsWidgets);
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Message the property team'));
      await tester.pumpAndSettle();
      expect(find.byType(ChatScreen), findsOneWidget);
      await captureFidelity(tester, key, '4105-18427');
      expect(
        tester.getTopLeft(find.byType(ChatBubble).first).dy,
        closeTo(225, 1),
      );
      await tester.enterText(
        find.byKey(const ValueKey('chat-message-input')),
        'Please confirm the next step.',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Send message'));
      await tester.pumpAndSettle();
      expect(find.text('Please confirm the next step.'), findsOneWidget);
      expect(
        tester
            .widget<ChatScreen>(find.byType(ChatScreen))
            .store
            .messages
            .length,
        5,
      );
      viewport(tester, 780, 360);
      binding.platformDispatcher.textScaleFactorTestValue = 1.3;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      router.go('/notifications');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<NotificationsScreen>(find.byType(NotificationsScreen))
            .store
            .items
            .first
            .unread,
        false,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await deps.dispose();
    },
  );
  testWidgets('Notifications empty state and Help route', (tester) async {
    viewport(tester);
    final deps = await AppDependencies.create(
      environment: const AppEnvironment(
        mockDelay: Duration.zero,
        mockScenario: MockScenario.empty,
      ),
    );
    deps.session.signIn(user);
    final router = createAppRouter(deps, initialLocation: '/notifications');
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: DevelopifyApp(dependencies: deps, router: router),
      ),
    );
    await tester.pumpAndSettle();
    await captureFidelity(tester, key, '4105-18228');
    expect(find.text("You're all caught up"), findsOneWidget);
    viewport(tester, 780, 360);
    binding.platformDispatcher.textScaleFactorTestValue = 1.3;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    await deps.dispose();
  });
  testWidgets(
    'Long and empty Home states, experience overlays and preserved Landowner navigation',
    (tester) async {
      viewport(tester);
      final deps = await AppDependencies.create(
        environment: const AppEnvironment(mockDelay: Duration.zero),
      );
      deps.session.signIn(user);
      final router = createAppRouter(deps, initialLocation: '/home');
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: DevelopifyApp(dependencies: deps, router: router),
        ),
      );
      await tester.pumpAndSettle();
      final store = tester.widget<HomeScreen>(find.byType(HomeScreen)).store;
      await captureFidelity(tester, key, '4105-18481');
      await tester.tap(find.byTooltip('Switch experience'));
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-18576');
      expect(find.byType(ExperienceScreen), findsOneWidget);
      await tester.tap(find.text('Investor'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/investor/home');
      expect(deps.session.experience, Experience.investor);
      unawaited(router.push<void>('/experience'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Landowner'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(deps.session.experience, Experience.landowner);
      expect(
        tester.widget<HomeScreen>(find.byType(HomeScreen)).store,
        same(store),
      );
      runInAction(
        () => store.data = const LandownerOverview(
          properties: [
            Property(
              id: 'sea-point',
              name: 'Sea Point Sunset Rd',
              town: 'Cape Town',
              status: PropertyStatus.live,
            ),
            Property(
              id: 'ridge-live',
              name: 'Ridge Site 12',
              town: 'KZN',
              status: PropertyStatus.live,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      for (final id in ['8285', '8426', '18687']) {
        await captureFidelity(tester, key, '4105-$id');
      }
      await tester.tap(find.byTooltip('Switch experience'));
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-18828');
      router.pop();
      await tester.pumpAndSettle();
      viewport(tester, 1006);
      await tester.pumpAndSettle();
      for (final id in ['7843', '8049']) {
        await captureFidelity(tester, key, '4105-$id');
      }
      viewport(tester, 1068);
      runInAction(() {
        store.data = const LandownerOverview(properties: []);
        store.status = LoadStatus.empty;
      });
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-8160');
      expect(find.text('No Properties Yet'), findsOneWidget);
      viewport(tester, 780, 360);
      binding.platformDispatcher.textScaleFactorTestValue = 1.3;
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -550),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await deps.dispose();
    },
  );
}
