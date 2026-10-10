import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:developify_mobile/features/onboarding/presentation/widgets/onboarding_chrome.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'helpers/fidelity_capture.dart';
import 'helpers/fonts.dart';

void main() {
  setUpAll(loadAppFonts);
  const user = AppUser(
    id: 'splash-review',
    name: 'Review',
    email: 'review@example.test',
  );

  for (final action in ['complete', 'cancel', 'logout']) {
    testWidgets('Plain launch splash and Landowner switch: $action', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 56, bottom: 34);
      addTearDown(tester.view.reset);
      final dependencies = await AppDependencies.create(
        environment: const AppEnvironment(mockDelay: Duration.zero),
      );
      final router = createAppRouter(dependencies);
      final boundary = GlobalKey();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        await tester.runAsync(dependencies.dispose);
      });
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: DevelopifyApp(dependencies: dependencies, router: router),
        ),
      );
      await tester.pump();
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Landowner Portal'), findsNothing);
      expect(
        tester.getRect(find.byType(SplashBrand)),
        const Rect.fromLTWH(49, 392, 295, 68),
      );
      expect(
        SystemChrome.latestStyle?.statusBarIconBrightness,
        Brightness.light,
      );
      if (action == 'complete') {
        await captureFidelity(tester, boundary, 'default-launch');
      }
      dependencies.session.signIn(user);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/investor/home');
      unawaited(router.push<void>('/experience'));
      await tester.pumpAndSettle();
      expect(find.text('Landowner Portal'), findsNothing);
      await tester.tap(find.text('Landowner'));
      await tester.pump();
      expect(find.text('Landowner Portal'), findsOneWidget);
      expect(dependencies.session.user, same(user));
      expect(dependencies.session.experience, Experience.investor);
      if (action == 'complete') {
        await captureFidelity(tester, boundary, 'landowner-switch');
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/home');
        expect(dependencies.session.user, same(user));
        expect(find.text('Landowner Portal'), findsNothing);
      } else {
        await tester.pump(const Duration(milliseconds: 650));
        if (action == 'cancel') {
          router.pop();
        } else {
          await dependencies.logout();
        }
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, isNot('/home'));
        expect(dependencies.session.isAuthenticated, action == 'cancel');
        expect(dependencies.session.experience, Experience.investor);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
