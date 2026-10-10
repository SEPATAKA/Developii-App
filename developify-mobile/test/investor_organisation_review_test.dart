import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/widgets/app_chrome.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_repository.dart';
import 'package:developify_mobile/features/investor/presentation/screens/kyc_screen.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'helpers/fonts.dart';
import 'helpers/investor_critical_journeys.dart';

void main() {
  setUpAll(loadAppFonts);
  for (final entity in [EntityType.company, EntityType.stokvel]) {
    testWidgets(
      '${entity.name} review keeps document names and edit return at large text',
      (tester) async {
        tester.view.physicalSize = const Size(360, 852);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final dependencies = await AppDependencies.create(
          environment: const AppEnvironment(
            mockDelay: Duration.zero,
            mockScenario: MockScenario.incompleteKyc,
          ),
        );
        dependencies.session.signIn(
          AppUser(
            id: 'review-${entity.name}',
            name: 'Test Investor',
            email: 'review@example.test',
            entity: entity,
          ),
          experience: Experience.investor,
        );
        final repository = dependencies.container<KycRepository>();
        await tester.runAsync(() => seedCompleteEntityKyc(repository, entity));
        final section = entity == EntityType.company
            ? 'registration'
            : 'constitution';
        final key = entity == EntityType.company ? 'cipc' : 'constitution';
        const filename =
            'Signed_founding_document_with_all_members_and_authorised_signatories_September_2026.pdf';
        final result = await tester.runAsync(
          () => repository.upload(
            entity,
            key,
            name: filename,
            bytes: 124000,
            mimeType: 'application/pdf',
          ),
        );
        expect(result, isA<Success>());
        final router = createAppRouter(
          dependencies,
          initialLocation: '/investor/kyc/${entity.name}/review',
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
        final expected = entity == EntityType.company
            ? [
                'registration',
                'moi',
                'shareholders',
                'resolution',
                'directors',
                'funds',
              ]
            : [
                'constitution',
                'resolution',
                'officers',
                'register',
                'bank',
                'funds',
              ];
        for (var index = 1; index < expected.length; index++) {
          expect(
            tester
                .getTopLeft(
                  find.byKey(ValueKey('review-section-${expected[index]}')),
                )
                .dy,
            greaterThan(
              tester
                  .getTopLeft(
                    find.byKey(
                      ValueKey('review-section-${expected[index - 1]}'),
                    ),
                  )
                  .dy,
            ),
          );
        }
        final name = find.text(filename);
        await tester.ensureVisible(name);
        await tester.pumpAndSettle();
        final paragraph = tester.renderObject<RenderParagraph>(name);
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(tester.getRect(name).width, greaterThan(280));
        expect(tester.getRect(name).right, lessThan(360));
        expect(tester.takeException(), isNull);
        final edit = find.byKey(ValueKey('review-edit-$section'));
        await tester.ensureVisible(edit);
        await tester.tap(edit);
        await tester.pumpAndSettle();
        expect(store.selectedStep, section);
        expect(store.reviewingStep, isTrue);
        final uploadedName = find.text(filename.replaceFirst('.pdf', ''));
        await tester.ensureVisible(uploadedName);
        await tester.pumpAndSettle();
        final uploadedParagraph = tester.renderObject<RenderParagraph>(
          find.descendant(of: uploadedName, matching: find.byType(RichText)),
        );
        expect(uploadedParagraph.didExceedMaxLines, isFalse);
        expect(tester.getRect(uploadedName).right, lessThan(360));
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(AppBackButton));
        await tester.pumpAndSettle();
        expect(store.selectedStep, 'review');
        expect(store.draft!.documents[key]!.name, filename);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
