import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/app/router/app_transition_page.dart';
import 'package:developify_mobile/app/router/route_names.dart';
import 'package:developify_mobile/features/landowner/presentation/properties_screen.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

void main() {
  testWidgets(
    'Shared route transitions retain named primitive parameters and iOS back gestures',
    (tester) async {
      late PageRoute<void> detailRoute;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Root')),
          ),
          GoRoute(
            path: '/detail/:id',
            name: 'detail',
            pageBuilder: (context, state) => AppTransitionPage(
              key: state.pageKey,
              name: state.name,
              reducedMotion: false,
              child: Builder(
                builder: (context) {
                  detailRoute = ModalRoute.of(context)! as PageRoute<void>;
                  return Scaffold(
                    body: Text(
                      '${state.pathParameters['id']} ${state.uri.queryParameters['tab']}',
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          theme: ThemeData(platform: TargetPlatform.iOS),
        ),
      );
      await tester.pumpAndSettle();
      unawaited(
        router.pushNamed(
          'detail',
          pathParameters: {'id': 'ridge-live'},
          queryParameters: {'tab': 'documents'},
        ),
      );
      await tester.pump();
      expect(detailRoute.transitionDuration, const Duration(milliseconds: 280));
      expect(
        detailRoute.reverseTransitionDuration,
        const Duration(milliseconds: 220),
      );
      await tester.pumpAndSettle();
      expect(find.text('ridge-live documents'), findsOneWidget);
      expect(router.state.uri.toString(), '/detail/ridge-live?tab=documents');
      final edge = await tester.startGesture(const Offset(8, 300));
      await edge.moveBy(const Offset(80, 0));
      await edge.moveBy(const Offset(400, 0));
      await tester.pump();
      await edge.up();
      await tester.pumpAndSettle();
      expect(find.text('Root'), findsOneWidget);
      expect(router.canPop(), isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
    },
  );

  testWidgets('Reduced motion makes shared routes immediate', (tester) async {
    final page = AppTransitionPage(
      key: const ValueKey('reduced'),
      name: 'reduced',
      child: const Scaffold(body: Text('Reduced')),
      reducedMotion: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final route = page.createRoute(context) as PageRoute<void>;
            expect(route.transitionDuration, Duration.zero);
            expect(route.reverseTransitionDuration, Duration.zero);
            route.dispose();
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Primary tabs preserve the Properties store, input, scroll and pushed route',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final deps = await AppDependencies.create(
        environment: const AppEnvironment(mockDelay: Duration.zero),
      );
      deps.session.signIn(
        const AppUser(id: 'qa', name: 'QA', email: 'qa@example.test'),
      );
      final router = createAppRouter(deps, initialLocation: '/properties');
      await tester.pumpWidget(
        DevelopifyApp(dependencies: deps, router: router),
      );
      await tester.pumpAndSettle();
      final screen = tester.widget<PropertiesScreen>(
        find.byType(PropertiesScreen),
      );
      final scroll = tester
          .stateList<ScrollableState>(
            find.descendant(
              of: find.byType(PropertiesScreen),
              matching: find.byType(Scrollable),
            ),
          )
          .firstWhere((state) => state.position.axis == Axis.vertical);
      scroll.position.jumpTo(100);
      await tester.pump();
      final offset = scroll.position.pixels;
      await tester.tap(find.byKey(const ValueKey('landowner-tab-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('landowner-tab-1')));
      await tester.pumpAndSettle();
      expect(
        identical(
          tester.widget<PropertiesScreen>(find.byType(PropertiesScreen)).store,
          screen.store,
        ),
        isTrue,
      );
      expect(scroll.position.pixels, offset);
      await tester.enterText(
        find.byKey(const ValueKey('property-search')),
        'Ridge',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('landowner-tab-3')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('landowner-tab-1')));
      await tester.pumpAndSettle();
      expect(find.text('Ridge'), findsOneWidget);
      unawaited(
        router.pushNamed(
          Routes.submit,
          pathParameters: {'step': '1'},
          queryParameters: {'draft': 'marula-draft'},
        ),
      );
      await tester.pumpAndSettle();
      expect(router.state.uri.toString(), '/submit/1?draft=marula-draft');
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Ridge'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await deps.dispose();
    },
  );
}
