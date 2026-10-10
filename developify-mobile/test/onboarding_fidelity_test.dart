import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/app/router/route_names.dart';
import 'package:developify_mobile/core/services/session_service.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:developify_mobile/features/onboarding/presentation/onboarding_store.dart';
import 'package:developify_mobile/features/onboarding/presentation/widgets/onboarding_chrome.dart';
import 'package:developify_mobile/features/onboarding/presentation/widgets/onboarding_illustrations.dart';
import 'package:developify_mobile/features/onboarding/presentation/widgets/welcome_content.dart';
import 'helpers/fidelity_capture.dart';
import 'helpers/fonts.dart';

Future<void> _host(
  WidgetTester tester,
  Widget child, {
  bool reducedMotion = false,
  bool active = true,
  bool accessibleNavigation = false,
  GlobalKey<NavigatorState>? navigatorKey,
  double textScale = 1,
  Size size = const Size(393, 852),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 56, bottom: 34);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      builder: (context, _) => MaterialApp(
        navigatorKey: navigatorKey,
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reducedMotion,
            accessibleNavigation: accessibleNavigation,
            textScaler: TextScaler.linear(textScale),
          ),
          child: TickerMode(
            enabled: active,
            child: Scaffold(body: child),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  setUp(
    () => TestWidgetsFlutterBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    ),
  );
  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
    view.resetPadding();
  });

  group('Looping onboarding carousel', () {
    Future<OnboardingStore> mount(
      WidgetTester tester, {
      bool reduced = false,
      bool accessible = false,
      GlobalKey<NavigatorState>? navigator,
    }) async {
      final session = SessionService();
      addTearDown(session.dispose);
      final store = OnboardingStore(session);
      await _host(
        tester,
        OnboardingScreen(store: store),
        reducedMotion: reduced,
        accessibleNavigation: accessible,
        navigatorKey: navigator,
      );
      await tester.pump();
      return store;
    }

    Future<void> remove(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 12));
      expect(tester.takeException(), isNull);
      expect(tester.binding.transientCallbackCount, 0);
    }

    Future<void> dwell(WidgetTester tester) async {
      await tester.pump(AppDurations.onboardingDwell);
      await tester.pump(AppDurations.onboardingPage);
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump();
    }

    Future<void> swipe(WidgetTester tester, double distance) async {
      await tester.drag(find.byType(PageView), Offset(distance, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump();
    }

    testWidgets(
      'Four logical slides loop forward twice without reverse traversal',
      (tester) async {
        final store = await mount(tester);
        final controller = tester
            .widget<PageView>(find.byType(PageView))
            .controller!;
        final start = controller.page!;
        final seen = <int>{};
        for (var step = 0; step < 9; step++) {
          expect(store.page, step % 4);
          seen.add(store.page);
          expect(controller.page, start + step);
          for (var dot = 0; dot < 4; dot++) {
            expect(
              tester.getSize(find.byKey(ValueKey('onboarding-dot-$dot'))).width,
              dot == store.page ? 40 : 7,
            );
          }
          await tester.pump(const Duration(milliseconds: 4999));
          expect(controller.page, start + step);
          await tester.pump(const Duration(milliseconds: 1));
          await tester.pump(const Duration(milliseconds: 210));
          expect(controller.page, greaterThan(start + step));
          expect(controller.page, lessThan(start + step + 1));
          await tester.pump(const Duration(milliseconds: 210));
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(seen, {0, 1, 2, 3});
        await remove(tester);
      },
    );

    testWidgets(
      'Manual swipes work in both directions across the loop boundary',
      (tester) async {
        final store = await mount(tester);
        await swipe(tester, -360);
        expect(store.page, 1);
        await swipe(tester, 360);
        expect(store.page, 0);
        await swipe(tester, 360);
        expect(store.page, 3);
        await swipe(tester, -360);
        expect(store.page, 0);
        await remove(tester);
      },
    );

    testWidgets('Manual paging cancels the old timer and starts a full dwell', (
      tester,
    ) async {
      final store = await mount(tester);
      await tester.pump(const Duration(seconds: 4));
      await swipe(tester, -360);
      expect(store.page, 1);
      await tester.pump(const Duration(milliseconds: 4999));
      expect(store.page, 1);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(AppDurations.onboardingPage);
      await tester.pump(const Duration(milliseconds: 16));
      expect(store.page, 2);
      await remove(tester);
    });

    testWidgets('A held pointer and an active drag prevent deadline races', (
      tester,
    ) async {
      final store = await mount(tester);
      await tester.pump(const Duration(seconds: 4));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await tester.pump(const Duration(seconds: 7));
      expect(store.page, 0);
      await gesture.moveBy(const Offset(-80, 0));
      await tester.pump(const Duration(seconds: 7));
      expect(store.page, 0);
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      final settled = store.page;
      await tester.pump(const Duration(milliseconds: 4999));
      expect(store.page, settled);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(AppDurations.onboardingPage);
      await tester.pump(const Duration(milliseconds: 16));
      expect(store.page, (settled + 1) % 4);
      await remove(tester);
    });

    testWidgets(
      'Rapid swipes preserve the active indicator and a single scheduler',
      (tester) async {
        final store = await mount(tester);
        for (final distance in [-360.0, -360.0, 360.0, -360.0, -360.0]) {
          await swipe(tester, distance);
          expect(
            tester
                .getSize(find.byKey(ValueKey('onboarding-dot-${store.page}')))
                .width,
            40,
          );
        }
        final before = store.page;
        await dwell(tester);
        expect(store.page, (before + 1) % 4);
        await remove(tester);
      },
    );

    testWidgets(
      'Every background lifecycle state pauses and foreground starts a fresh dwell',
      (tester) async {
        final store = await mount(tester);
        await tester.pump(const Duration(seconds: 4));
        for (final state in [
          AppLifecycleState.inactive,
          AppLifecycleState.hidden,
          AppLifecycleState.paused,
          AppLifecycleState.detached,
        ]) {
          tester.binding.handleAppLifecycleStateChanged(state);
          await tester.pump(const Duration(seconds: 8));
          expect(store.page, 0);
          expect(tester.binding.transientCallbackCount, 0);
        }
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 4999));
        expect(store.page, 0);
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump(AppDurations.onboardingPage);
        await tester.pump(const Duration(milliseconds: 16));
        expect(store.page, 1);
        await remove(tester);
      },
    );

    testWidgets(
      'Covered routes stop motion until the uncover transition completes',
      (tester) async {
        final navigator = GlobalKey<NavigatorState>();
        final store = await mount(tester, navigator: navigator);
        await tester.pump(const Duration(seconds: 4));
        unawaited(
          navigator.currentState!.push(
            MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Covered')),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 8));
        expect(store.page, 0);
        expect(tester.binding.transientCallbackCount, 0);
        navigator.currentState!.pop();
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(milliseconds: 4999));
        expect(store.page, 0);
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump(AppDurations.onboardingPage);
        await tester.pump(const Duration(milliseconds: 16));
        expect(store.page, 1);
        await remove(tester);
      },
    );

    testWidgets(
      'Offstage ticker mode stops timers and resumes with a new dwell',
      (tester) async {
        final store = await mount(tester);
        await _host(tester, OnboardingScreen(store: store), active: false);
        await tester.pump(const Duration(seconds: 15));
        expect(store.page, 0);
        expect(tester.binding.transientCallbackCount, 0);
        await _host(tester, OnboardingScreen(store: store));
        await tester.pump(const Duration(milliseconds: 4999));
        expect(store.page, 0);
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump(AppDurations.onboardingPage);
        await tester.pump(const Duration(milliseconds: 16));
        expect(store.page, 1);
        await remove(tester);
      },
    );

    for (final accessible in [false, true]) {
      testWidgets(
        '${accessible ? 'Accessible navigation' : 'Reduced motion'} disables autoplay but keeps manual paging',
        (tester) async {
          final store = await mount(
            tester,
            reduced: !accessible,
            accessible: accessible,
          );
          await tester.pump(const Duration(seconds: 15));
          expect(store.page, 0);
          expect(tester.binding.transientCallbackCount, 0);
          await swipe(tester, -360);
          expect(store.page, 1);
          expect(
            tester
                .widget<Transform>(
                  find.byKey(const ValueKey('title-key-float')),
                )
                .transform
                .getTranslation()
                .y,
            0,
          );
          await swipe(tester, -360);
          expect(store.page, 2);
          expect(
            tester
                .getSize(find.byKey(const ValueKey('funding-progress-fill')))
                .width,
            closeTo(169.615, .001),
          );
          await tester.pump(const Duration(seconds: 15));
          expect(store.page, 2);
          expect(tester.binding.transientCallbackCount, 0);
          await remove(tester);
        },
      );
    }

    testWidgets('The key stops offstage and restarts from its authored rest', (
      tester,
    ) async {
      await _host(tester, const TitleDeedIllustration());
      final key = find.byKey(const ValueKey('title-key-float'));
      await tester.pump(const Duration(milliseconds: 836));
      expect(
        tester.widget<Transform>(key).transform.getTranslation().y,
        lessThan(-6),
      );
      await _host(tester, const TitleDeedIllustration(), active: false);
      await tester.pump(const Duration(seconds: 8));
      expect(tester.widget<Transform>(key).transform.getTranslation().y, 0);
      expect(tester.binding.transientCallbackCount, 0);
      await _host(tester, const TitleDeedIllustration());
      expect(tester.widget<Transform>(key).transform.getTranslation().y, 0);
      await tester.pump(const Duration(milliseconds: 836));
      expect(
        tester.widget<Transform>(key).transform.getTranslation().y,
        lessThan(-6),
      );
      await remove(tester);
    });

    testWidgets(
      'Investor entrance replays on revisit and pulse resumes after looping',
      (tester) async {
        final store = await mount(tester);
        await dwell(tester);
        await dwell(tester);
        expect(store.page, 2);
        final progress = find.byKey(const ValueKey('funding-progress-fill'));
        await tester.pump(const Duration(milliseconds: 850));
        expect(tester.getSize(progress).width, closeTo(169.615, .001));
        await swipe(tester, -360);
        await swipe(tester, 360);
        expect(tester.getSize(progress).width, lessThan(169.615));
        await tester.pump(const Duration(milliseconds: 850));
        expect(tester.getSize(progress).width, closeTo(169.615, .001));
        await swipe(tester, -360);
        await dwell(tester);
        expect(store.page, 0);
        final pulse = find.byKey(const ValueKey('location-pulse-0'));
        final previous = tester.widget<Transform>(pulse).transform.clone();
        await tester.pump(const Duration(milliseconds: 450));
        expect(tester.widget<Transform>(pulse).transform, isNot(previous));
        await remove(tester);
      },
    );

    testWidgets(
      'Only logical page semantics are exposed without live announcements',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final store = await mount(tester, reduced: true);
        for (var i = 0; i < 4; i++) {
          expect(
            find.bySemanticsLabel('Page ${store.page + 1} of 4'),
            findsOneWidget,
          );
          expect(find.bySemanticsLabel(RegExp('4000[0-9]')), findsNothing);
          final node = tester.getSemantics(
            find.byKey(const ValueKey('onboarding-indicator')),
          );
          expect(node.getSemanticsData().flagsCollection.isLiveRegion, isFalse);
          await swipe(tester, -360);
        }
        semantics.dispose();
        await remove(tester);
      },
    );

    for (final skip in [true, false]) {
      testWidgets(
        '${skip ? 'Skip' : 'Get started and Continue'} keeps the welcome destination and disposes carousel activity',
        (tester) async {
          final session = SessionService();
          final store = OnboardingStore(session);
          final router = GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => OnboardingScreen(store: store),
              ),
              GoRoute(
                path: '/welcome',
                name: Routes.welcome,
                builder: (_, _) =>
                    const Scaffold(body: Text('Welcome destination')),
              ),
            ],
          );
          await tester.pumpWidget(
            ScreenUtilInit(
              designSize: const Size(393, 852),
              builder: (_, _) => MaterialApp.router(
                routerConfig: router,
                theme: AppTheme.light,
              ),
            ),
          );
          await tester.pump();
          if (skip) {
            await tester.tap(find.text('Skip'));
          } else {
            for (var i = 0; i < 3; i++) {
              await tester.tap(find.text('Get started'));
              await tester.pump();
              await tester.pump(AppDurations.onboardingPage);
              await tester.pump(const Duration(milliseconds: 16));
              await tester.pump();
              expect(store.page, i + 1);
            }
            await tester.tap(find.text('Continue'));
          }
          await tester.pumpAndSettle();
          await tester.pump(const Duration(seconds: 12));
          expect(find.text('Welcome destination'), findsOneWidget);
          expect(session.onboardingComplete, isTrue);
          await remove(tester);
          router.dispose();
          session.dispose();
        },
      );
    }
  });

  testWidgets('Onboarding chrome follows the authored bounds and CTA copy', (
    tester,
  ) async {
    final session = SessionService();
    final store = OnboardingStore(session);
    final boundary = GlobalKey();
    await _host(
      tester,
      RepaintBoundary(
        key: boundary,
        child: OnboardingScreen(store: store),
      ),
      reducedMotion: true,
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byType(OnboardingBrand)),
      const Offset(12, 73),
    );
    expect(tester.getSize(find.byType(OnboardingBrand)).width, 128);
    expect(
      tester.getTopLeft(find.byType(LocationIllustration)),
      const Offset(13, 129),
    );
    expect(
      tester.getSize(find.byType(LocationIllustration)),
      const Size(368, 357),
    );
    expect(tester.getTopLeft(find.text('Pin your land in seconds')).dy, 523);
    expect(
      find.byKey(const ValueKey('onboarding-pin-artwork')),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('onboarding-next'))).dy,
      701,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('onboarding-next'))).height,
      48,
    );
    for (var page = 0; page < 4; page++) {
      await captureFidelity(
        tester,
        boundary,
        ['4105-6845', '4105-6913', '4105-6974', '4105-7038'][page],
      );
      expect(store.page, page);
      expect(find.text(page == 3 ? 'Continue' : 'Get started'), findsOneWidget);
      final selected = page;
      expect(
        tester
            .getSize(find.byKey(const ValueKey('onboarding-indicator')))
            .width,
        73,
      );
      for (var dot = 0; dot < 4; dot++) {
        expect(find.byKey(ValueKey('onboarding-dot-$dot')), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('onboarding-dot-4')), findsNothing);
      expect(
        tester.getSize(find.byKey(ValueKey('onboarding-dot-$selected'))).width,
        40,
      );
      if (page < 3) {
        await tester.tap(find.byKey(const ValueKey('onboarding-next')));
        await tester.pumpAndSettle();
      }
    }
    expect(find.byKey(const ValueKey('entity-card-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('entity-card-3')), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      expect(find.byKey(ValueKey('entity-artwork-$i')), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });

  testWidgets(
    'Splash and welcome preserve the authored brand and hero bounds',
    (tester) async {
      var ready = 0;
      final splashKey = GlobalKey();
      await _host(
        tester,
        RepaintBoundary(
          key: splashKey,
          child: SplashScreen(landownerPortal: true, onReady: () => ready++),
        ),
        reducedMotion: true,
      );
      await tester.pump();
      expect(
        tester.getRect(find.byType(SplashBrand)),
        const Rect.fromLTWH(49, 392, 295, 68),
      );
      expect(
        tester.getTopLeft(find.text('Landowner Portal')),
        const Offset(144, 451),
      );
      await captureFidelity(tester, splashKey, '4105-6812');
      await captureFidelity(tester, splashKey, '4105-7573');
      await captureFidelity(tester, splashKey, '4105-7689');
      await tester.pump(const Duration(milliseconds: 700));
      expect(ready, 1);
      final welcomeKey = GlobalKey();
      await _host(
        tester,
        RepaintBoundary(key: welcomeKey, child: const WelcomeScreen()),
        reducedMotion: true,
      );
      await tester.pumpAndSettle();
      await captureFidelity(tester, welcomeKey, '4105-7209');
      expect(tester.getSize(find.byType(WelcomeHero)), const Size(393, 423));
      expect(
        tester.getTopLeft(find.byType(OnboardingBrand)),
        const Offset(17, 81),
      );
      expect(
        tester.getTopLeft(find.text('Turn your land into\nincome.')),
        const Offset(19, 217),
      );
      expect(
        tester.getTopLeft(find.widgetWithText(TextButton, 'List my land')),
        const Offset(12, 705),
      );
      expect(
        tester.getTopLeft(
          find.widgetWithText(TextButton, 'I already have an account'),
        ),
        const Offset(12, 768),
      );
      expect(tester.takeException(), isNull);
      await _host(
        tester,
        const WelcomeScreen(),
        reducedMotion: true,
        textScale: 1.3,
        size: const Size(360, 780),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Backed by investors'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Location pulse advances, pauses offstage and disposes', (
    tester,
  ) async {
    await _host(tester, const LocationIllustration());
    final ring = find.byKey(const ValueKey('location-pulse-0'));
    final first = tester.widget<Transform>(ring).transform.clone();
    await tester.pump(const Duration(milliseconds: 450));
    final middle = tester.widget<Transform>(ring).transform.clone();
    expect(middle, isNot(first));
    expect(find.byKey(const ValueKey('location-marker')), findsOneWidget);
    await _host(tester, const LocationIllustration(), active: false);
    final paused = tester.widget<Transform>(ring).transform.clone();
    await tester.pump(const Duration(seconds: 2));
    expect(tester.widget<Transform>(ring).transform, paused);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets(
    'Title key has a visible bounce, settles, rests and respects reduced motion',
    (tester) async {
      await _host(tester, const TitleDeedIllustration());
      final movement = find.byKey(const ValueKey('title-key-float'));
      expect(find.byKey(const ValueKey('title-key')), findsOneWidget);
      expect(find.byKey(const ValueKey('title-key-artwork')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 836));
      expect(
        tester.widget<Transform>(movement).transform.getTranslation().y,
        closeTo(-7, .001),
      );
      expect(
        tester
            .widget<Transform>(find.byKey(const ValueKey('title-key-scale')))
            .transform
            .getMaxScaleOnAxis(),
        closeTo(1.05, .001),
      );
      await tester.pump(const Duration(milliseconds: 484));
      expect(
        tester.widget<Transform>(movement).transform.getTranslation().y,
        closeTo(2.5, .001),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester.widget<Transform>(movement).transform.getTranslation().y,
        0,
      );
      await tester.pump(const Duration(milliseconds: 440));
      expect(
        tester.widget<Transform>(movement).transform.getTranslation().y,
        0,
      );
      await _host(tester, const TitleDeedIllustration(), reducedMotion: true);
      await tester.pumpAndSettle();
      expect(
        tester.widget<Transform>(movement).transform.getTranslation().y,
        0,
      );
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Investor stagger and progress finish once without unrelated replay',
    (tester) async {
      await _host(tester, const InvestorsIllustration());
      final progress = find.byKey(const ValueKey('funding-progress-fill'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.getSize(progress).width, greaterThan(0));
      expect(tester.getSize(progress).width, lessThan(169.615));
      expect(
        tester
            .widget<Opacity>(find.byKey(const ValueKey('investor-initial-0')))
            .opacity,
        greaterThan(
          tester
              .widget<Opacity>(find.byKey(const ValueKey('investor-initial-7')))
              .opacity,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(progress).width, closeTo(169.615, .001));
      for (var i = 0; i < 8; i++) {
        expect(
          tester
              .widget<Opacity>(find.byKey(ValueKey('investor-initial-$i')))
              .opacity,
          1,
        );
      }
      await _host(tester, const InvestorsIllustration(), textScale: 1.1);
      expect(tester.getSize(progress).width, closeTo(169.615, .001));
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Reduced motion immediately presents the final marker and funding states',
    (tester) async {
      await _host(tester, const LocationIllustration(), reducedMotion: true);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Transform>(find.byKey(const ValueKey('location-pulse-0')))
            .transform
            .getMaxScaleOnAxis(),
        1,
      );
      expect(tester.binding.transientCallbackCount, 0);
      await _host(tester, const InvestorsIllustration(), reducedMotion: true);
      await tester.pumpAndSettle();
      expect(
        tester
            .getSize(find.byKey(const ValueKey('funding-progress-fill')))
            .width,
        closeTo(169.615, .001),
      );
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Onboarding remains usable at narrow widths and larger text', (
    tester,
  ) async {
    final session = SessionService();
    final store = OnboardingStore(session);
    await _host(
      tester,
      OnboardingScreen(store: store),
      reducedMotion: true,
      textScale: 1.3,
      size: const Size(360, 780),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.drag(
        find.byKey(const ValueKey('onboarding-pages')),
        const Offset(-360, 0),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(store.page, 3);
    expect(
      tester.getRect(find.byKey(const ValueKey('onboarding-next'))).bottom,
      lessThan(746),
    );
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });
}
