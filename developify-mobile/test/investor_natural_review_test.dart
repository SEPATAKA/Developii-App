import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_chrome.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_repository.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_review.dart';
import 'package:developify_mobile/features/investor/presentation/screens/kyc_screen.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'helpers/fonts.dart';
import 'helpers/investor_natural_review_frames.dart';

void main() {
  setUpAll(loadAppFonts);
  for (final width in [360.0, 393.0, 430.0]) {
    for (final pep in [false, true]) {
      testWidgets(
        'Natural review requires ${pep ? 'PEP declarations' : 'consent'} at $width with enlarged text',
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
              mockDelay: Duration.zero,
              mockScenario: MockScenario.incompleteKyc,
            ),
          );
          dependencies.session.signIn(
            const AppUser(
              id: 'natural-review',
              name: 'Babatunde Yusuf',
              email: 'investor@example.test',
            ),
            experience: Experience.investor,
          );
          await tester.runAsync(
            () => seedInvestorNaturalReviewFrame(
              dependencies.container<KycRepository>(),
              pep ? '53372' : '53211',
            ),
          );
          final router = createAppRouter(
            dependencies,
            initialLocation: '/investor/kyc/individual/review',
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
          final label = pep ? 'Submit for verification' : 'Continue';
          final submit = find.byWidgetPredicate(
            (widget) => widget is AppButton && widget.label == label,
          );
          expect(tester.widget<AppButton>(submit).onPressed, isNull);
          expect(store.canSubmit, isFalse);
          expect(find.text('14 June 1992'), findsOneWidget);
          expect(find.text('R600,000.00'), findsOneWidget);
          final declarations = KycReviewPlan.naturalDeclarations
              .where((field) => field.visible(store.draft!.values))
              .toList();
          expect(declarations, hasLength(pep ? 4 : 1));
          for (final declaration in declarations) {
            expect(tester.widget<AppButton>(submit).onPressed, isNull);
            final checkbox = find.text(declaration.label);
            await tester.ensureVisible(checkbox);
            await tester.tap(checkbox);
            await tester.pumpAndSettle();
            expect(store.draft!.values[declaration.key], 'true');
          }
          expect(store.canSubmit, isTrue);
          final documents = find.bySemanticsLabel(
            RegExp('^Review identity documents'),
          );
          await tester.ensureVisible(documents);
          await tester.tap(documents);
          await tester.pumpAndSettle();
          expect(store.selectedStep, 'identity');
          expect(store.reviewingStep, isTrue);
          await tester.tap(find.byType(AppBackButton));
          await tester.pumpAndSettle();
          expect(store.selectedStep, 'review');
          expect(store.canSubmit, isTrue);
          await tester.tap(submit);
          await tester.pumpAndSettle();
          expect(store.draft!.status, VerificationStatus.pending);
          expect(find.text('Verification in review'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
