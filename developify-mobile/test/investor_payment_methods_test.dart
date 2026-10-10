import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/features/investor/data/mock_investor_account_repository.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/investor_account_context.dart';
import 'package:developify_mobile/features/investor/domain/investor_repository.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/payment_card_preview.dart';
import 'package:developify_mobile/features/investor/presentation/screens/payment_methods_screen.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'helpers/fonts.dart';

void main() {
  setUpAll(loadAppFonts);
  Future<(AppDependencies, GoRouter)> mount(
    WidgetTester tester, {
    double width = 393,
    String route = '/investor/profile/payment-methods',
    MockScenario scenario = MockScenario.success,
    Duration delay = Duration.zero,
  }) async {
    tester.view.physicalSize = Size(width, 852);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 56, bottom: 34);
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    final dependencies = await AppDependencies.create(
      environment: AppEnvironment(mockDelay: delay, mockScenario: scenario),
    );
    dependencies.session.signIn(
      const AppUser(
        id: 'payment-test',
        name: 'Babatunde Yusuf',
        email: 'investor@example.test',
      ),
      experience: Experience.investor,
    );
    final router = createAppRouter(dependencies, initialLocation: route);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await tester.runAsync(dependencies.dispose);
    });
    await tester.pumpWidget(
      DevelopifyApp(dependencies: dependencies, router: router),
    );
    await tester.pumpAndSettle();
    return (dependencies, router);
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<InvestorAccountSnapshot> snapshot(
    WidgetTester tester,
    InvestorAccountRepository repository,
  ) async =>
      (await tester.runAsync(repository.snapshot)
              as Success<InvestorAccountSnapshot>)
          .value;

  testWidgets(
    'Malformed payment selectors cannot open or mutate saved methods',
    (tester) async {
      final (dependencies, router) = await mount(tester);
      final repository = dependencies.container<InvestorAccountRepository>();
      final before = (await snapshot(tester, repository)).paymentMethods;
      for (final path in [
        '/investor/profile/payment-methods?kind=unknown',
        '/investor/profile/payment-methods?select=maybe',
        '/investor/profile/payment-methods?kind=card&kind=bankAccount',
        '/investor/profile/payment-methods?select=true&select=false',
        '/investor/profile/bank-details?kind=card',
        '/investor/profile/payment-methods/card?kind=bankAccount',
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(
          find.text('This payment-method selection could not be found.'),
          findsOneWidget,
        );
        expect(find.byType(PaymentCardPreview), findsNothing);
      }
      expect(
        (await snapshot(tester, repository)).paymentMethods.map((m) => m.id),
        before.map((m) => m.id),
      );
      await tap(tester, find.text('Try again'));
      expect(find.byType(PaymentCardPreview), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [360.0, 390.0, 393.0, 402.0, 430.0]) {
    testWidgets(
      'Card defaults, failed deletion and add-card recovery at $width with large text',
      (tester) async {
        final (dependencies, _) = await mount(tester, width: width);
        final repository =
            dependencies.container<InvestorAccountRepository>()
                as MockInvestorAccountRepository;
        expect(
          tester
              .widget<PaymentCardPreview>(find.byType(PaymentCardPreview))
              .method
              .isDefault,
          true,
        );
        await tap(tester, find.widgetWithText(TextButton, 'Change'));
        expect(find.byType(PaymentCardPreview), findsNothing);
        await tap(
          tester,
          find.bySemanticsLabel('More options for Visa ending 2526'),
        );
        expect(find.text('More Options'), findsOneWidget);
        await tap(tester, find.bySemanticsLabel('Set as default'));
        expect(
          (await snapshot(tester, repository)).paymentMethods.first.isDefault,
          false,
        );
        await tap(tester, find.bySemanticsLabel('Set as default'));
        expect(
          (await snapshot(tester, repository)).paymentMethods.first.isDefault,
          true,
        );
        repository.behavior.failNext();
        await tap(tester, find.widgetWithText(AppButton, 'Delete Card'));
        expect(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.text('Unable to connect. Please try again.'),
          ),
          findsOneWidget,
        );
        expect(
          (await snapshot(tester, repository)).paymentMethods.where(
            (method) => method.kind == PaymentMethodKind.card,
          ),
          hasLength(1),
        );
        await tap(tester, find.widgetWithText(AppButton, 'Delete Card'));
        expect(find.text('More Options'), findsNothing);
        expect(find.text('No Cards Added Yet'), findsOneWidget);
        expect(
          (await snapshot(tester, repository)).paymentMethods.single.kind,
          PaymentMethodKind.bankAccount,
        );
        await tap(tester, find.widgetWithText(AppButton, 'Add card'));
        for (final (index, value) in [
          (0, 'Babatunde Yusuf'),
          (1, '1000 0000 0000 1111'),
          (2, '12 / 29'),
          (3, '123'),
        ]) {
          await tester.enterText(find.byType(TextField).at(index), value);
        }
        await tester.pumpAndSettle();
        await tap(tester, find.widgetWithText(AppButton, 'Add Card'));
        expect(
          find.text('Check the card details and try again.'),
          findsOneWidget,
        );
        expect(
          tester
              .widget<TextField>(find.byType(TextField).at(1))
              .controller!
              .text,
          '1000 0000 0000 1111',
        );
        await tester.enterText(
          find.byType(TextField).at(1),
          '4111 1111 1111 1111',
        );
        await tap(
          tester,
          find.bySemanticsLabel(RegExp(r'^Save card for future payments')),
        );
        await tap(tester, find.widgetWithText(AppButton, 'Add Card'));
        expect(find.text('Card Added'), findsOneWidget);
        expect(find.textContaining('simulated payments'), findsOneWidget);
        await tap(tester, find.widgetWithText(AppButton, 'Done'));
        expect(find.text('No Cards Added Yet'), findsNothing);
        await tap(tester, find.bySemanticsLabel('Back'));
        final saved = tester
            .widget<PaymentCardPreview>(find.byType(PaymentCardPreview))
            .method;
        expect(saved.lastFour, '1111');
        expect(saved.expiry, '12/29');
        expect(saved.isDefault, true);
        for (final finder in [
          find.widgetWithText(TextButton, 'Change'),
          find.widgetWithText(AppButton, 'Add payment method'),
        ]) {
          expect(tester.getSize(finder).height, greaterThanOrEqualTo(44));
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('A pending card save blocks back and completes only once', (
    tester,
  ) async {
    await mount(
      tester,
      route: '/investor/profile/payment-methods/card',
      delay: const Duration(milliseconds: 300),
    );
    for (final (index, value) in [
      (0, 'Babatunde Yusuf'),
      (1, '4111111111111111'),
      (2, '12/29'),
      (3, '123'),
    ]) {
      await tester.enterText(find.byType(TextField).at(index), value);
    }
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Add Card'));
    await tester.pump(const Duration(milliseconds: 10));
    final store = tester
        .widget<PaymentMethodsScreen>(find.byType(PaymentMethodsScreen))
        .store;
    expect(store.saving, true);
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.byType(PaymentMethodsScreen), findsOneWidget);
    expect(store.saving, true);
    await tester.pumpAndSettle();
    expect(store.saving, false);
    expect(find.text('Card Added'), findsOneWidget);
    expect(store.values, isEmpty);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(
      store.methods.where((method) => method.id == store.lastSavedId),
      hasLength(1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'An unsaved card stays available until its single simulated payment',
    (tester) async {
      final (dependencies, _) = await mount(
        tester,
        scenario: MockScenario.empty,
      );
      await tap(tester, find.widgetWithText(AppButton, 'Add card'));
      for (final (index, value) in [
        (0, 'Babatunde Yusuf'),
        (1, '4111111111111111'),
        (2, '12/29'),
        (3, '123'),
      ]) {
        await tester.enterText(find.byType(TextField).at(index), value);
      }
      await tester.pumpAndSettle();
      await tap(tester, find.widgetWithText(AppButton, 'Add Card'));
      await tap(tester, find.widgetWithText(AppButton, 'Done'));
      final method = tester
          .widget<PaymentCardPreview>(find.byType(PaymentCardPreview))
          .method;
      expect(method.reusable, false);
      expect(method.isDefault, false);
      await tap(tester, find.widgetWithText(TextButton, 'Change'));
      await tap(
        tester,
        find.bySemanticsLabel('More options for Visa ending 1111'),
      );
      expect(find.text('Available for one simulated payment.'), findsOneWidget);
      await tap(tester, find.bySemanticsLabel('Set as default'));
      final repository = dependencies.container<InvestorAccountRepository>();
      expect(
        (await snapshot(tester, repository)).paymentMethods.single.isDefault,
        false,
      );
      final result = await tester.runAsync(
        () => repository.addMoney(
          amount: const MonetaryAmount(10000, Currency.zar),
          methodId: method.id,
          operationId: repository.newOperationId(),
          pin: '1234',
        ),
      );
      expect(result, isA<Success<InvestorOperationReceipt>>());
      await tester.pumpAndSettle();
      expect(find.byType(PaymentCardPreview), findsNothing);
      expect(
        find.text('This payment method is no longer available.'),
        findsOneWidget,
      );
      await tap(tester, find.bySemanticsLabel('Close payment method options'));
      expect(find.text('No Cards Added Yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Bank management keeps cards and shows a distinct bank empty state',
    (tester) async {
      final (dependencies, _) = await mount(
        tester,
        route: '/investor/profile/bank-details',
      );
      await tap(
        tester,
        find.bySemanticsLabel(
          RegExp(r'^Manage Access Bank account ending 0119'),
        ),
      );
      await tap(tester, find.widgetWithText(AppButton, 'Delete Bank Account'));
      expect(find.text('No Bank Account Added'), findsOneWidget);
      expect(
        find.widgetWithText(AppButton, 'Add bank account'),
        findsOneWidget,
      );
      final account = await snapshot(
        tester,
        dependencies.container<InvestorAccountRepository>(),
      );
      expect(account.paymentMethods.single.kind, PaymentMethodKind.card);
      await tap(tester, find.widgetWithText(AppButton, 'Add bank account'));
      expect(find.text('Add Bank Account'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Changing entity dismisses sensitive card content without changing the new entity',
    (tester) async {
      final (dependencies, _) = await mount(
        tester,
        route: '/investor/profile/payment-methods/cards',
      );
      await tap(
        tester,
        find.bySemanticsLabel('More options for Visa ending 2526'),
      );
      dependencies.container<InvestorAccountContext>().selectEntity(
        EntityType.trust,
      );
      await tester.pumpAndSettle();
      expect(find.byType(PaymentCardPreview), findsNothing);
      expect(
        find.text('This payment method is no longer available.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(AppButton, 'Delete Card'), findsNothing);
      await tap(tester, find.bySemanticsLabel('Close payment method options'));
      final account = await snapshot(
        tester,
        dependencies.container<InvestorAccountRepository>(),
      );
      expect(
        account.paymentMethods.every(
          (method) => method.id.startsWith('trust-'),
        ),
        true,
      );
      expect(account.paymentMethods.every((method) => method.isDefault), true);
      expect(tester.takeException(), isNull);
    },
  );
}
