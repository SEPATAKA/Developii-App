import 'dart:async';
import 'helpers/fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/features/investor/presentation/screens/explore_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/investor_home_screen.dart';
import 'package:developify_mobile/features/landowner/presentation/home_screen.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/features/investor/presentation/screens/investor_entry_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/investor_signup_screen.dart';
import 'package:developify_mobile/features/onboarding/presentation/onboarding_screen.dart';

void main() {
  setUpAll(loadAppFonts);
  const user = AppUser(
    id: 'router-user',
    name: 'Babatunde Yusuf',
    email: 'user@example.test',
  );
  void viewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 56, bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
  }

  for (final path in ['/investor/splash', '/']) {
    testWidgets(
      'Investor entry from $path requires consent and an explicit entity',
      (tester) async {
        viewport(tester);
        final dependencies = await AppDependencies.create(
          environment: const AppEnvironment(mockDelay: Duration.zero),
        );
        dependencies.session.selectExperience(Experience.investor);
        final router = createAppRouter(dependencies, initialLocation: path);
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox());
          router.dispose();
          await tester.runAsync(dependencies.dispose);
        });
        await tester.pumpWidget(
          DevelopifyApp(dependencies: dependencies, router: router),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          tester
              .widget<SplashScreen>(find.byType(SplashScreen))
              .landownerPortal,
          isFalse,
        );
        expect(find.text('Landowner Portal'), findsNothing);
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        expect(find.byType(InvestorOnboardingScreen), findsOneWidget);
        await tester.tap(find.text('Get started'));
        await tester.pumpAndSettle();
        final continueButton = find.byKey(const ValueKey('terms-continue'));
        expect(tester.widget<AppButton>(continueButton).onPressed, isNull);
        expect(dependencies.session.onboardingComplete, isFalse);
        await tester.tap(find.byKey(const ValueKey('terms-declaration')));
        await tester.pumpAndSettle();
        await tester.tap(continueButton);
        await tester.pumpAndSettle();
        expect(dependencies.session.onboardingComplete, isTrue);
        expect(find.byType(InvestorWelcomeScreen), findsOneWidget);
        expect(
          tester
              .widget<InvestorWelcomeScreen>(find.byType(InvestorWelcomeScreen))
              .fromOnboarding,
          isTrue,
        );
        await tester.tap(find.widgetWithText(AppButton, 'Create account'));
        await tester.pumpAndSettle();
        final useEntity = find.widgetWithText(AppButton, 'Use this entity');
        expect(tester.widget<AppButton>(useEntity).onPressed, isNull);
        await tester.tap(find.text('Non-Resident / Diaspora'));
        await tester.pumpAndSettle();
        expect(tester.widget<AppButton>(useEntity).onPressed, isNotNull);
        await tester.tap(find.text('Company / SPV'));
        await tester.pumpAndSettle();
        await tester.tap(useEntity);
        await tester.pumpAndSettle();
        final store = tester
            .widget<InvestorSignupScreen>(find.byType(InvestorSignupScreen))
            .store;
        expect(store.entity, EntityType.company);
        expect(store.nonResident, isFalse);
        expect(dependencies.session.isAuthenticated, isFalse);
        router.go('/investor/splash');
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<InvestorWelcomeScreen>(find.byType(InvestorWelcomeScreen))
              .fromOnboarding,
          isFalse,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  test('Application dependencies clear both experiences and dispose', () async {
    final dependencies = await AppDependencies.create(
      environment: const AppEnvironment(mockDelay: Duration.zero),
    );
    dependencies.session.signIn(user);
    await dependencies.logout();
    expect(dependencies.session.isAuthenticated, false);
    await dependencies.dispose();
  });
  testWidgets(
    'Experience switches preserve the session and both navigator branches',
    (tester) async {
      viewport(tester);
      final dependencies = await AppDependencies.create(
        environment: const AppEnvironment(mockDelay: Duration.zero),
      );
      dependencies.session.signIn(user);
      final router = createAppRouter(dependencies, initialLocation: '/home');
      await tester.pumpWidget(
        DevelopifyApp(dependencies: dependencies, router: router),
      );
      await tester.pumpAndSettle();
      final landowner = tester
          .widget<HomeScreen>(find.byType(HomeScreen))
          .store;
      unawaited(router.push<void>('/experience'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Investor'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/investor/home');
      expect(find.byType(InvestorHomeScreen), findsOneWidget);
      expect(dependencies.session.user, same(user));
      router.go('/investor/explore');
      await tester.pumpAndSettle();
      final explore = tester
          .widget<ExploreScreen>(find.byType(ExploreScreen))
          .store;
      explore.search('Saffron');
      unawaited(router.push<void>('/experience'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Landowner'));
      await tester.pump();
      expect(find.text('Landowner Portal'), findsOneWidget);
      expect(dependencies.session.user, same(user));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(
        tester.widget<HomeScreen>(find.byType(HomeScreen)).store,
        same(landowner),
      );
      unawaited(router.push<void>('/experience'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Investor'));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/investor/explore',
      );
      expect(
        tester.widget<ExploreScreen>(find.byType(ExploreScreen)).store,
        same(explore),
      );
      expect(explore.query, 'Saffron');
      expect(dependencies.session.isAuthenticated, true);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await tester.runAsync(dependencies.dispose);
    },
  );
  testWidgets('Investor deep links are guarded and restored after sign-in', (
    tester,
  ) async {
    viewport(tester);
    final dependencies = await AppDependencies.create(
      environment: const AppEnvironment(mockDelay: Duration.zero),
    );
    dependencies.session.completeOnboarding();
    final router = createAppRouter(
      dependencies,
      initialLocation: '/investor/projects/marula-heights',
    );
    await tester.pumpWidget(
      DevelopifyApp(dependencies: dependencies, router: router),
    );
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/investor/sign-in');
    dependencies.session.signIn(user, experience: Experience.investor);
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/investor/projects/marula-heights',
    );
    expect(find.text('Marula Heights'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    await tester.runAsync(dependencies.dispose);
  });
  testWidgets(
    'Missing project, investment, transaction and entity IDs show controlled errors',
    (tester) async {
      viewport(tester);
      final dependencies = await AppDependencies.create(
        environment: const AppEnvironment(mockDelay: Duration.zero),
      );
      dependencies.session.signIn(user, experience: Experience.investor);
      final router = createAppRouter(
        dependencies,
        initialLocation: '/investor/projects/missing',
      );
      await tester.pumpWidget(
        DevelopifyApp(dependencies: dependencies, router: router),
      );
      for (final path in [
        '/investor/projects/missing',
        '/investor/investments/missing',
        '/investor/transactions/missing',
        '/investor/kyc/missing/overview',
        '/investor/kyc/trust/missing',
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(
          find.textContaining('could not be found'),
          findsWidgets,
          reason: path,
        );
        expect(tester.takeException(), isNull, reason: path);
      }
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await tester.runAsync(dependencies.dispose);
    },
  );
  testWidgets('Malformed Explore filters can recover to the project list', (
    tester,
  ) async {
    viewport(tester);
    final dependencies = await AppDependencies.create(
      environment: const AppEnvironment(mockDelay: Duration.zero),
    );
    dependencies.session.signIn(user, experience: Experience.investor);
    final router = createAppRouter(
      dependencies,
      initialLocation: '/investor/explore?min=500&max=50',
    );
    await tester.pumpWidget(
      DevelopifyApp(dependencies: dependencies, router: router),
    );
    await tester.pumpAndSettle();
    expect(find.text('This project filter is invalid.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byType(ExploreScreen), findsOneWidget);
    expect(router.state.uri.query, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    await tester.runAsync(dependencies.dispose);
  });
}
