import '../test/helpers/native_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android keyboard and native Back on the original Flutter surface',
    (tester) async {
      final dependencies = await AppDependencies.create(
        environment: const AppEnvironment(mockDelay: Duration.zero),
      );
      dependencies.session.signIn(
        const AppUser(
          id: 'native-keyboard',
          name: 'Test Investor',
          email: 'keyboard@example.test',
        ),
        experience: Experience.investor,
      );
      final router = createAppRouter(
        dependencies,
        initialLocation: '/investor/explore',
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        await tester.runAsync(dependencies.dispose);
      });
      await tester.pumpWidget(
        DevelopifyApp(dependencies: dependencies, router: router),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Search projects'));
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('field-'));
      await tester.tap(field);
      await tester.enterText(field, 'Saffron');
      for (
        var attempt = 0;
        attempt < 50 && tester.view.viewInsets.bottom == 0;
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();
      await settleNativeImages(tester);
      final view = tester.view;
      final inset = view.viewInsets.bottom / view.devicePixelRatio;
      debugPrint(
        'Original surface keyboard inset: $inset, size: ${view.physicalSize}, raw: ${binding.platformDispatcher.implicitView?.viewInsets}',
      );

      binding.reportData = {
        'keyboardInset': inset,
        'surfaceConvertedDuringKeyboardCheck': false,
      };
      expect(inset, greaterThan(0));
      expect(
        tester.getRect(field).bottom,
        lessThan(view.physicalSize.height / view.devicePixelRatio - inset),
      );
      debugPrint('DEVELOPIFY_NATIVE_BACK_READY:investor-search-keyboard');
      for (
        var attempt = 0;
        attempt < 300 && view.viewInsets.bottom > 0;
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 200));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      expect(view.viewInsets.bottom, 0);
      expect(router.state.uri.path, '/investor/explore/search');
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'Saffron',
      );
      expect(tester.takeException(), isNull);
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await binding.takeScreenshot('investor-native-back-keyboard-dismissed');
    },
  );
}
