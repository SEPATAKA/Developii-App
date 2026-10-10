import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/features/investor/data/mock_kyc_repository.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_repository.dart';
import 'package:developify_mobile/features/investor/presentation/screens/kyc_screen.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'helpers/fonts.dart';
import 'helpers/investor_entity_document_frames.dart';

void main() {
  setUpAll(loadAppFonts);
  for (final entity in [EntityType.trust, EntityType.company]) {
    for (final width in [360.0, 393.0, 430.0]) {
      testWidgets(
        '${entity.name} supporting files journey at $width, text 1.6',
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
              id: 'supporting-file-journey',
              name: 'Investor',
              email: 'investor@example.test',
            ),
            experience: Experience.investor,
          );
          final repository =
              dependencies.container<KycRepository>() as MockKycRepository;
          await tester.runAsync(
            () => seedInvestorEntityDocumentFrame(
              repository,
              entity == EntityType.trust ? '58787' : '82119',
            ),
          );
          final router = createAppRouter(
            dependencies,
            initialLocation: '/investor/kyc/${entity.name}/funds',
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
          final original = store.draft!.documentsFor('fundsEvidence').single;
          Future<void> choose(String option) async {
            final picker = find.bySemanticsLabel(
              RegExp('^Choose a file for Upload more supporting documents'),
            );
            await tester.ensureVisible(picker);
            await tester.tap(picker);
            await tester.pumpAndSettle();
            await tester.tap(find.text(option));
            await tester.pumpAndSettle();
          }

          await choose('Cancel');
          expect(store.draft!.documentsFor('fundsEvidence'), [original]);
          repository.behavior.failNext();
          await choose('Choose Document');
          expect(store.draft!.documentsFor('fundsEvidence'), [original]);
          expect(store.canContinue, isFalse);
          final retry = find.text('Try Again');
          await tester.ensureVisible(retry);
          await tester.tap(retry);
          await tester.pumpAndSettle();
          final files = store.draft!.documentsFor('fundsEvidence');
          expect(files, hasLength(2));
          expect(files.first, same(original));
          expect(store.canContinue, isTrue);
          final remove = find.descendant(
            of: find.byKey(ValueKey(original.id)),
            matching: find.bySemanticsLabel('Delete Supporting Evidence'),
          );
          await tester.ensureVisible(remove);
          await tester.tap(remove);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Delete').last);
          await tester.pumpAndSettle();
          expect(store.draft!.documentsFor('fundsEvidence'), [files.last]);
          expect(store.canContinue, isTrue);
          final amount = find.byKey(
            const ValueKey('field-Planned annual investment'),
          );
          await tester.ensureVisible(amount);
          await tester.tap(amount);
          await tester.enterText(amount, '1000000.25');
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          expect(store.draft!.values['annualInvestment'], '1000000.25');
          expect(
            tester.widget<TextFormField>(amount).controller!.text,
            'R 1,000,000.25',
          );
          router.go('/investor/kyc/${entity.name}/overview');
          await tester.pumpAndSettle();
          router.go('/investor/kyc/${entity.name}/funds');
          await tester.pumpAndSettle();
          final restored = tester
              .widget<KycScreen>(find.byType(KycScreen))
              .store;
          expect(restored.draft!.documentsFor('fundsEvidence'), [files.last]);
          expect(restored.canContinue, isTrue);
          expect(restored.draft!.values['annualInvestment'], '1000000.25');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
