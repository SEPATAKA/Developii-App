import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_field.dart';
import 'package:developify_mobile/features/profile/data/mock_profile_repository.dart';
import 'package:developify_mobile/features/profile/domain/profile_repository.dart';
import 'package:developify_mobile/features/profile/presentation/widgets/payout_success_sheet.dart';
import 'package:developify_mobile/features/profile/presentation/payout_screen.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'helpers/fidelity_capture.dart';
import 'helpers/fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  void viewport(WidgetTester tester, [double height = 852]) {
    tester.view.physicalSize = Size(393, height);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 56, bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  const user = AppUser(
    id: 'local-landowner',
    name: 'Babatunde Yusuf',
    email: 'bafreka@gmail.com',
  );

  testWidgets('Payout account overview, navigation and empty state', (
    tester,
  ) async {
    viewport(tester);
    final deps = await AppDependencies.create(
      environment: const AppEnvironment(mockDelay: Duration.zero),
    );
    deps.session.signIn(user);
    final router = createAppRouter(deps, initialLocation: '/profile/payout');
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: DevelopifyApp(dependencies: deps, router: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('payout-account-card'))).dy,
      closeTo(139, 1),
    );
    expect(tester.getTopLeft(find.text('Account Holder')).dy, closeTo(316, 1));
    expect(
      tester
          .getTopLeft(find.widgetWithText(AppButton, 'Change payout account'))
          .dy,
      closeTo(698, 1),
    );
    await captureFidelity(tester, key, '4105-11789');
    await tester.tap(find.text('Change payout account'));
    await tester.pumpAndSettle();
    expect(find.text('New Payouts'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('View last payouts'));
    await tester.pumpAndSettle();
    expect(find.text('Linked Accounts'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    await deps.dispose();

    final empty = await AppDependencies.create(
      environment: const AppEnvironment(
        mockDelay: Duration.zero,
        mockScenario: MockScenario.empty,
      ),
    );
    empty.session.signIn(user);
    final emptyRouter = createAppRouter(
      empty,
      initialLocation: '/profile/payout',
    );
    final emptyKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: emptyKey,
        child: DevelopifyApp(dependencies: empty, router: emptyRouter),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('No Payout Account Added Yet')).dy,
      closeTo(378, 1),
    );
    await captureFidelity(tester, emptyKey, '4105-11755');
    await tester.tap(find.text('Add Bank Account'));
    await tester.pumpAndSettle();
    expect(find.text('New Payouts'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    emptyRouter.dispose();
    await empty.dispose();
  });

  testWidgets(
    'Payout form states, proof removal, failed save retry and persistence',
    (tester) async {
      viewport(tester, 1017);
      final deps = await AppDependencies.create(
        environment: const AppEnvironment(mockDelay: Duration.zero),
      );
      deps.session.signIn(user);
      final router = createAppRouter(
        deps,
        initialLocation: '/profile/payout/new',
      );
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: DevelopifyApp(dependencies: deps, router: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AppButton>(
              find.widgetWithText(AppButton, 'Submit for verification'),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('payout-proof-upload'))).dy,
        closeTo(607, 1),
      );
      await captureFidelity(tester, key, '4105-11861');
      tester.view.physicalSize = const Size(393, 852);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate((w) => w is AppSelect && w.label == 'Bank'),
      );
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-12182');
      await tester.tap(find.text('Standard Bank'));
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(393, 1017);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('field-Account Number')),
        '1234567890',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-11933');
      tester.view.physicalSize = const Size(393, 852);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is AppSelect && w.label == 'Account Type',
        ),
      );
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-12306');
      await tester.tap(find.text('Savings'));
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(393, 941);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('field-Branch Code')),
        '051001',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('payout-proof-upload')));
      await tester.pumpAndSettle();
      expect(find.text('Bank account letter'), findsOneWidget);
      await captureFidelity(tester, key, '4105-12005');
      await tester.tap(find.bySemanticsLabel('Remove bank account letter'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<PayoutScreen>(find.byType(PayoutScreen)).store.canSubmit,
        isFalse,
      );
      await tester.tap(find.byKey(const ValueKey('payout-proof-upload')));
      await tester.pumpAndSettle();
      final repo = deps.container<ProfileRepository>() as MockProfileRepository;
      repo.behavior.failNext();
      await tester.tap(find.text('Submit for verification'));
      await tester.pumpAndSettle();
      expect(find.byType(PayoutSuccessSheet), findsNothing);
      expect(repo.payoutAccount!.number, '0000001293');
      await tester.ensureVisible(find.text('Submit for verification'));
      await tester.tap(find.text('Submit for verification'));
      await tester.pumpAndSettle();
      expect(find.byType(PayoutSuccessSheet), findsOneWidget);
      tester.view.physicalSize = const Size(393, 852);
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-12084');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(repo.payoutAccount!.number, '1234567890');
      expect(find.text('Payout Account'), findsOneWidget);
      expect(find.text('Discard changes?'), findsNothing);
      tester.view.physicalSize = const Size(360, 780);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -700));
      await tester.pumpAndSettle();
      expect(find.text('View last payouts').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await deps.dispose();
    },
  );
}
