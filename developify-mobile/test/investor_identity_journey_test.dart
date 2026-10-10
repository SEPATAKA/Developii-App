import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/features/investor/data/mock_kyc_repository.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_repository.dart';
import 'package:developify_mobile/features/investor/presentation/screens/kyc_screen.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_identity_photo.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'helpers/fonts.dart';
import 'helpers/investor_document_frames.dart';

void main() {
  setUpAll(loadAppFonts);
  testWidgets('Identity scan pauses offstage and respects reduced motion', (
    tester,
  ) async {
    final active = ValueNotifier(true);
    final reducedMotion = ValueNotifier(false);
    addTearDown(active.dispose);
    addTearDown(reducedMotion.dispose);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 852),
        builder: (_, child) => MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: Listenable.merge([active, reducedMotion]),
              builder: (context, _) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: reducedMotion.value),
                child: TickerMode(
                  enabled: active.value,
                  child: const KycIdentityPhoto(
                    title: 'Photo ID Card (Front)',
                    back: false,
                    checking: true,
                    onRetake: null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    double rotation() => tester
        .widget<RotationTransition>(
          find.descendant(
            of: find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics &&
                  widget.properties.label == 'Simulating identity photo check',
            ),
            matching: find.byType(RotationTransition),
          ),
        )
        .turns
        .value;
    await tester.pump(const Duration(milliseconds: 240));
    final beforePause = rotation();
    expect(beforePause, greaterThan(0));
    active.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1370));
    expect(rotation(), beforePause);
    active.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(rotation(), closeTo(beforePause, .02));
    await tester.pump(const Duration(milliseconds: 100));
    expect(rotation(), greaterThan(beforePause));
    reducedMotion.value = true;
    await tester.pump();
    expect(rotation(), 0);
    await tester.pump(const Duration(seconds: 2));
    expect(rotation(), 0);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
  for (final width in [360.0, 393.0, 430.0]) {
    testWidgets(
      'Identity check retries, returns to checklist and supports retakes at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 852);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 56, bottom: 34);
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final dependencies = await AppDependencies.create(
          environment: const AppEnvironment(
            mockDelay: Duration(milliseconds: 50),
            mockScenario: MockScenario.incompleteKyc,
          ),
        );
        dependencies.session.signIn(
          const AppUser(
            id: 'identity-journey',
            name: 'Sample Investor',
            email: 'sample@example.test',
          ),
          experience: Experience.investor,
        );
        final repository =
            dependencies.container<KycRepository>() as MockKycRepository;
        await tester.runAsync(
          () => seedInvestorIdentityFrame(repository, '48414'),
        );
        final router = createAppRouter(
          dependencies,
          initialLocation: '/investor/kyc/individual/identity',
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
        final store = tester.widget<KycScreen>(find.byType(KycScreen)).store;
        expect(find.byType(KycIdentityPhoto), findsNWidgets(2));
        expect(store.canContinue, isTrue);
        repository.behavior.failNext();
        await tester.tap(find.widgetWithText(AppButton, 'Continue'));
        await tester.pump(const Duration(milliseconds: 10));
        expect(store.busy, isTrue);
        expect(
          tester
              .widgetList<KycIdentityPhoto>(find.byType(KycIdentityPhoto))
              .every((photo) => photo.checking),
          isTrue,
        );
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        expect(store.error, isNotNull);
        expect(store.draft!.verifiedSteps, isNot(contains('identity')));
        expect(store.selectedStep, 'identity');
        await tester.tap(find.widgetWithText(AppButton, 'Continue'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        expect(find.text('Verification in Progress!'), findsOneWidget);
        expect(store.selectedStep, 'overview');
        expect(store.draft!.verifiedSteps, contains('identity'));
        await tester.tap(find.widgetWithText(AppButton, 'Continue').last);
        await tester.pumpAndSettle();
        store.selectStep('identity');
        await tester.pumpAndSettle();
        final previous = store.draft!.documents['identityFront'];
        final retake = find.bySemanticsLabel(
          RegExp(r'^Retake Photo ID Card \(Front\)'),
        );
        await tester.ensureVisible(retake);
        await tester.tap(retake);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel').last);
        await tester.pumpAndSettle();
        expect(store.draft!.documents['identityFront'], same(previous));
        await tester.tap(retake);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Choose Document'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        expect(
          store.draft!.documents['identityFront']!.mimeType,
          'application/pdf',
        );
        expect(store.draft!.verifiedSteps, isNot(contains('identity')));
        expect(find.byType(KycIdentityPhoto), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
