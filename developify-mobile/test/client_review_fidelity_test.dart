import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/features/investor/domain/investment_policy.dart';
import 'package:developify_mobile/features/investor/domain/investor_project_content.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/project_documents.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'helpers/fonts.dart';
import 'helpers/fidelity_capture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  testWidgets('Project documents support empty and long unavailable files', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    Future<void> show(List<InvestorProjectDocument> documents) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(393, 852),
          minTextAdapt: true,
          builder: (context, _) => MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: ProjectDocuments(documents: documents),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await show(const []);
    expect(find.text('No documents yet'), findsOneWidget);
    const name =
        'CIPC_CoR14_3_Marula_Heights_Registration_Supporting_Document_September_2026.pdf';
    await show(const [InvestorProjectDocument(id: 'long', name: name)]);
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.text(name)).width, lessThan(360));
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
    expect(find.textContaining('no file is downloaded'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text(name), findsOneWidget);
  });
  for (final viewport in [
    (360.0, 780.0, 1.6),
    (393.0, 852.0, 1.0),
    (430.0, 932.0, 1.0),
  ]) {
    testWidgets(
      'Correction layouts at ${viewport.$1} and text ${viewport.$3}',
      (tester) async {
        tester.view.physicalSize = Size(viewport.$1, viewport.$2);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 56, bottom: 34);
        tester.platformDispatcher.textScaleFactorTestValue = viewport.$3;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final dependencies = await AppDependencies.create(
          environment: const AppEnvironment(mockDelay: Duration.zero),
        );
        dependencies.session.signIn(
          const AppUser(
            id: 'review-fidelity',
            name: 'Review',
            email: 'review@example.test',
          ),
        );
        final router = createAppRouter(
          dependencies,
          initialLocation: '/investor/portfolio',
        );
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
        await tester.pumpAndSettle();
        Future<void> capture(String name) async {
          expect(tester.takeException(), isNull);
          await captureFidelity(
            tester,
            boundary,
            '${viewport.$1.toInt()}-$name',
          );
        }

        await capture('portfolio');
        await tester.tap(find.bySemanticsLabel('Hide balance'));
        await tester.pumpAndSettle();
        expect(find.text('Projected returns hidden'), findsOneWidget);
        final semantics = tester.ensureSemantics();
        final maskedAmount = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Invested Capital' &&
              widget.properties.value != null,
        );
        expect(
          tester.getSemantics(maskedAmount).getSemanticsData().value,
          'Hidden',
        );
        expect(
          find.bySemanticsLabel(RegExp(r'R652\.50.*projected returns')),
          findsNothing,
        );
        semantics.dispose();

        await capture('portfolio-private');
        router.go(
          '/investor/projects/marula-heights/calculator?amountCents=10000',
        );
        await tester.pumpAndSettle();
        final input = find.byKey(const ValueKey('investor-amount'));
        final calculatorSemantics = tester.ensureSemantics();
        final fieldNode = tester.getSemantics(input);
        expect(
          fieldNode.rect.height,
          lessThanOrEqualTo(tester.getSize(input).height + 1),
          reason: 'Amount input must not absorb the calculator results.',
        );
        calculatorSemantics.dispose();
        for (final invalid in ['-1', 'abc100', '1.001', '1..2']) {
          await tester.enterText(input, invalid);
          await tester.pumpAndSettle();
          expect(tester.widget<TextField>(input).controller!.text, invalid);
          expect(
            tester
                .widget<AppButton>(
                  find.widgetWithText(AppButton, 'Invest this amount'),
                )
                .onPressed,
            isNull,
          );
        }
        await tester.enterText(input, '100');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        final disclaimer = find.text(InvestmentPolicy.calculatorDisclaimer);
        await tester.ensureVisible(disclaimer);
        await tester.pumpAndSettle();
        expect(disclaimer.hitTestable(), findsOneWidget);
        expect(
          find.text('30 payments of R1.21 and 6 of R1.20.'),
          findsOneWidget,
        );
        await capture('calculator');
        tester.view.viewInsets = const FakeViewPadding(bottom: 290);
        await tester.pumpAndSettle();
        await tester.ensureVisible(disclaimer);
        await tester.pumpAndSettle();
        expect(
          tester.getBottomRight(disclaimer).dy,
          lessThanOrEqualTo(viewport.$2 - 290),
        );
        expect(tester.takeException(), isNull);
        tester.view.resetViewInsets();
        router.go('/investor/projects/marula-heights');
        await tester.pumpAndSettle();
        final documents = find.widgetWithText(TextButton, 'Documents');
        await tester.ensureVisible(documents);
        await tester.pumpAndSettle();
        await tester.tap(documents);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('CIPC_CoR14_3_Marula'));
        await tester.pumpAndSettle();
        await capture('documents');
      },
    );
  }
}
