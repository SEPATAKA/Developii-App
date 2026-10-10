import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_plan.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_repository.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_review.dart';
import 'package:developify_mobile/features/investor/presentation/screens/kyc_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/investor_entry_screen.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'helpers/fonts.dart';
import 'helpers/investor_member_fixtures.dart';

void main() {
  setUpAll(loadAppFonts);
  for (final width in [360.0, 393.0, 430.0]) {
    testWidgets(
      'Entity KYC retains input and keeps actions above the keyboard at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 852);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final dependencies = await AppDependencies.create(
          environment: const AppEnvironment(
            mockDelay: Duration.zero,
            mockScenario: MockScenario.incompleteKyc,
          ),
        );
        dependencies.session.signIn(
          const AppUser(
            id: 'keyboard-kyc-user',
            name: 'Babatunde Yusuf',
            email: 'investor@example.test',
          ),
          experience: Experience.investor,
        );
        final router = createAppRouter(
          dependencies,
          initialLocation: '/investor/home',
        );
        await tester.pumpWidget(
          DevelopifyApp(dependencies: dependencies, router: router),
        );
        try {
          for (final scale in [1.0, 1.6]) {
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            for (final (entity, step, label, key) in [
              ('trust', 'deed', 'Registered name of Trust', 'trustName'),
              ('company', 'registration', 'Registered name', 'companyName'),
              ('stokvel', 'constitution', 'Stokvel name', 'stokvelName'),
            ]) {
              final path = '/investor/kyc/$entity/$step';
              router.go(path);
              await tester.pumpAndSettle();
              final field = find.byKey(ValueKey('field-$label'));
              await tester.ensureVisible(field);
              await tester.enterText(field, 'Saved example $entity');
              tester.view.viewInsets = const FakeViewPadding(bottom: 320);
              await tester.pumpAndSettle();
              await tester.ensureVisible(field);
              await tester.pumpAndSettle();
              for (final label in ['Save & Exit', 'Save and Continue']) {
                final button = find.widgetWithText(AppButton, label);
                expect(
                  button.hitTestable(),
                  findsOneWidget,
                  reason: '$path $scale',
                );
                expect(
                  tester.getRect(button).bottom,
                  lessThanOrEqualTo(532),
                  reason: '$path $scale',
                );
              }
              expect(tester.takeException(), isNull, reason: '$path $scale');
              FocusManager.instance.primaryFocus?.unfocus();
              tester.view.resetViewInsets();
              router.go('/investor/home');
              await tester.pumpAndSettle();
              router.go(path);
              await tester.pumpAndSettle();
              final store = tester
                  .widget<KycScreen>(find.byType(KycScreen))
                  .store;
              expect(store.draft!.values[key], 'Saved example $entity');
            }
          }
        } finally {
          await tester.pumpWidget(const SizedBox());
          router.dispose();
          await tester.runAsync(dependencies.dispose);
        }
      },
    );
    testWidgets(
      'Investor public forms remain usable with a keyboard at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 852);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final dependencies = await AppDependencies.create(
          environment: const AppEnvironment(mockDelay: Duration.zero),
        );
        final router = createAppRouter(
          dependencies,
          initialLocation: '/investor/onboarding',
        );
        await tester.pumpWidget(
          DevelopifyApp(dependencies: dependencies, router: router),
        );
        try {
          for (final scale in [1.0, 1.6, 2.0]) {
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            router.go('/investor/onboarding');
            await tester.pumpAndSettle();
            expect(
              SystemChrome.latestStyle?.statusBarIconBrightness,
              Brightness.dark,
            );
            for (var page = 1; page < 4; page++) {
              await tester.tap(
                find.bySemanticsLabel('Onboarding page $page of 3. Next page'),
              );
              await tester.pumpAndSettle();
              expect(
                tester.takeException(),
                isNull,
                reason: 'Onboarding $page at $scale',
              );
            }
            expect(find.byType(InvestorOnboardingScreen), findsOneWidget);
            await tester.tap(find.text('Get started'));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const ValueKey('terms-declaration')));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const ValueKey('terms-continue')));
            await tester.pumpAndSettle();
            expect(find.byType(InvestorWelcomeScreen), findsOneWidget);
            expect(
              SystemChrome.latestStyle?.statusBarIconBrightness,
              Brightness.dark,
            );
            expect(tester.takeException(), isNull, reason: 'Welcome at $scale');
            for (final (path, key, text) in [
              ('/investor/sign-in', 'field-Password', 'Test-password-9'),
              (
                '/investor/create-account?entity=individual',
                'field-Confirm Password',
                'Test-password-9',
              ),
              (
                '/investor/create-account?entity=company',
                'representative-name-0',
                'Simulated representative',
              ),
            ]) {
              router.go(path);
              await tester.pumpAndSettle();
              if (path.endsWith('entity=company')) {
                await tester.ensureVisible(find.text('Add'));
                await tester.pumpAndSettle();
                await tester.tap(find.text('Add'));
                await tester.pumpAndSettle();
              }
              final field = find.byKey(ValueKey(key));
              expect(field, findsOneWidget, reason: path);
              await tester.ensureVisible(field);
              await tester.pumpAndSettle();
              await tester.enterText(field, text);
              tester.view.viewInsets = const FakeViewPadding(bottom: 320);
              await tester.pumpAndSettle();
              await tester.ensureVisible(field);
              await tester.pumpAndSettle();
              expect(
                tester.getRect(field).bottom,
                lessThanOrEqualTo(533),
                reason: '$path at $scale',
              );
              expect(tester.takeException(), isNull, reason: '$path at $scale');
              FocusManager.instance.primaryFocus?.unfocus();
              tester.view.resetViewInsets();
              await tester.pumpAndSettle();
            }
          }
        } finally {
          await tester.pumpWidget(const SizedBox());
          router.dispose();
          await tester.runAsync(dependencies.dispose);
        }
      },
    );
    for (final scale in [1.0, 1.6]) {
      testWidgets(
        'Investor routes fit width $width at text scale $scale with reduced motion',
        (tester) async {
          tester.view.physicalSize = Size(width, 852);
          tester.view.devicePixelRatio = 1;
          tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              const FakeAccessibilityFeatures(disableAnimations: true);
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearAllTestValues);
          final dependencies = await AppDependencies.create(
            environment: const AppEnvironment(
              mockDelay: Duration.zero,
              mockScenario: MockScenario.incompleteKyc,
            ),
          );
          dependencies.session.signIn(
            const AppUser(
              id: 'responsive-investor',
              name: 'Babatunde Yusuf',
              email: 'investor@example.test',
            ),
            experience: Experience.investor,
          );
          await tester.runAsync(() async {
            final repository = dependencies.container<KycRepository>();
            await seedInvestorMemberFrame(repository, '56805');
            await seedInvestorMemberFrame(repository, '81740');
          });
          final router = createAppRouter(
            dependencies,
            initialLocation: '/investor/home',
          );
          await tester.pumpWidget(
            DevelopifyApp(dependencies: dependencies, router: router),
          );
          await tester.pumpAndSettle();
          final routes = [
            '/investor/home',
            '/investor/explore',
            '/investor/explore/filters',
            '/investor/wallet',
            '/investor/portfolio',
            '/investor/profile',
            '/investor/projects/saffron-towers',
            '/investor/projects/saffron-towers/invest',
            '/investor/projects/saffron-towers/calculator',
            '/investor/projects/saffron-towers/details',
            '/investor/projects/saffron-towers/developer',
            '/investor/projects/saffron-towers/updates',
            '/investor/projects/saffron-towers/updates/planning',
            '/investor/portfolio/analytics',
            '/investor/notifications',
            '/investor/notifications/individual-target-reached',
            '/investor/investments/individual-saffron-0',
            '/investor/investments/individual-saffron-0/timeline',
            '/investor/wallet/add-money',
            '/investor/wallet/withdraw',
            '/investor/profile/payment-methods/card',
            for (final entity in EntityType.values) ...[
              '/investor/kyc/${entity.name}/overview',
              for (final step in KycPlans.steps(entity))
                '/investor/kyc/${entity.name}/${step.id}',
            ],
          ];
          try {
            for (final path in routes) {
              router.go(path);
              await tester.pumpAndSettle();
              expect(router.routeInformationProvider.value.uri.path, path);
              expect(tester.takeException(), isNull, reason: path);
              if (path.endsWith('/overview')) {
                final continueButton = find.widgetWithText(
                  AppButton,
                  'Continue',
                );
                final bounds = tester.getRect(continueButton);
                final safeBottom = 852 - tester.view.padding.bottom;
                expect(
                  bounds.top,
                  greaterThanOrEqualTo(tester.view.padding.top),
                  reason: path,
                );
                expect(
                  bounds.bottom,
                  lessThanOrEqualTo(safeBottom),
                  reason: path,
                );
                if (path.contains('/individual/')) {
                  final exit = find.widgetWithText(AppButton, 'Save and exit');
                  expect(
                    tester.getRect(exit).bottom,
                    lessThanOrEqualTo(safeBottom),
                  );
                }
              }
              final context = tester.element(find.byType(Scaffold).last);
              expect(
                AppDurations.motion(context, AppDurations.page),
                Duration.zero,
              );
              final scrollable = find
                  .byWidgetPredicate(
                    (widget) =>
                        widget is Scrollable &&
                        widget.axisDirection == AxisDirection.down,
                  )
                  .hitTestable();
              if (scrollable.evaluate().isNotEmpty) {
                await tester.drag(scrollable.first, const Offset(0, -350));
                await tester.pumpAndSettle();
                expect(
                  tester.takeException(),
                  isNull,
                  reason: '$path after scroll',
                );
              }
            }
            await tester.runAsync(
              () => seedInvestorMemberFrame(
                dependencies.container<KycRepository>(),
                '59009',
              ),
            );
            router.go('/investor/kyc/trust/review');
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: 'Trust review');
            for (final field in KycReviewPlan.trustDeclarations) {
              final declaration = find.byKey(ValueKey(field.key));
              await tester.ensureVisible(declaration);
              await tester.pumpAndSettle();
              await tester.tap(declaration);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull, reason: field.key);
            }
            expect(
              find.widgetWithText(AppButton, 'Submit').hitTestable(),
              findsOneWidget,
            );
            await tester.tap(find.text('Submit'));
            await tester.pumpAndSettle();
            expect(find.text('Submitted for review'), findsOneWidget);
            expect(find.text('View Status').hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull, reason: 'Trust receipt');
          } finally {
            await tester.pumpWidget(const SizedBox());
            router.dispose();
            await tester.runAsync(dependencies.dispose);
          }
        },
      );
    }
  }
}
