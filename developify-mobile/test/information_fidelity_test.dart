import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/features/profile/presentation/widgets/information_tile.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'package:developify_mobile/features/notifications/presentation/chat_screen.dart';
import 'helpers/fidelity_capture.dart';
import 'helpers/fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  testWidgets(
    'Information navigation, FAQ expansion and complete legal scrolls',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 56, bottom: 34);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final deps = await AppDependencies.create(
        environment: const AppEnvironment(mockDelay: Duration.zero),
      );
      deps.session.signIn(
        const AppUser(
          id: 'local-landowner',
          name: 'Babatunde Yusuf',
          email: 'bafreka@gmail.com',
        ),
      );
      final router = createAppRouter(deps, initialLocation: '/profile/help');
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: DevelopifyApp(dependencies: deps, router: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('help-question-0'))).dy,
        closeTo(143, .1),
      );
      expect(tester.getTopLeft(find.text('CONTACT US')).dy, closeTo(600, .1));
      await captureFidelity(tester, key, '4105-12676');
      await tester.tap(find.text('What can I do with this app?'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<InformationTile>(
              find.byKey(const ValueKey('help-question-0')),
            )
            .expanded,
        isFalse,
      );
      await tester.tap(find.text('How do I get support?'));
      await tester.pumpAndSettle();
      expect(
        find.text('Open Live Chat to speak with the property team.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Live Chat'));
      await tester.tap(find.text('Live Chat'));
      await tester.pumpAndSettle();
      expect(find.byType(ChatScreen), findsOneWidget);
      router.go('/profile/about');
      await tester.pumpAndSettle();
      expect(
        tester
            .getTopLeft(
              find.widgetWithText(InformationTile, 'Terms & Condition'),
            )
            .dy,
        closeTo(438.410065, .1),
      );
      await captureFidelity(tester, key, '4105-12792');
      await tester.tap(find.text('Terms & Condition'));
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-12908');
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(393, 1059);
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-12851');
      tester.view.physicalSize = const Size(360, 780);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -1400));
      await tester.pumpAndSettle();
      expect(find.text('Cookies & Tracking').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      router.go('/profile/help');
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -900));
      await tester.pumpAndSettle();
      expect(find.text('Call Us').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await deps.dispose();
    },
  );
}
