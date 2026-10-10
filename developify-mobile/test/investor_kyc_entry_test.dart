import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/features/investor/domain/investor_account_context.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_entity_sheet.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'helpers/fonts.dart';

void main() {
  setUpAll(loadAppFonts);
  for (final width in [360.0, 393.0, 430.0]) {
    testWidgets(
      'Verification entry selects each entity and preserves residency at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 852);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 56, bottom: 34);
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
          const AppUser(
            id: 'kyc-entry',
            name: 'Babatunde Yusuf',
            email: 'investor@example.test',
          ),
          experience: Experience.investor,
        );
        final account = dependencies.container<InvestorAccountContext>();
        final router = createAppRouter(
          dependencies,
          initialLocation: '/investor/home',
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
        Future<Finder> reveal(String text) async {
          final target = find.text(text);
          if (target.evaluate().isEmpty) {
            final scrollable = find.byType(Scrollable).last;
            await tester.drag(scrollable, const Offset(0, 5000));
            await tester.pumpAndSettle();
            await tester.scrollUntilVisible(
              target,
              200,
              scrollable: scrollable,
            );
          }
          await tester.ensureVisible(target);
          await tester.pumpAndSettle();
          return target;
        }

        Future<void> tap(String text) async {
          await tester.tap(await reveal(text));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: text);
        }

        await tap('Complete your verification');
        expect(router.state.uri.path, '/investor/verification');
        await tap('I’ll do this later');
        expect(router.state.uri.path, '/investor/home');
        await tap('Complete your verification');
        await tap('Start Verification');
        expect(
          tester
              .widget<InvestorEntityChoice>(
                find.widgetWithText(InvestorEntityChoice, 'Natural Person'),
              )
              .selected,
          isTrue,
        );
        expect(
          tester
              .widget<AppButton>(find.widgetWithText(AppButton, 'Continue'))
              .onPressed,
          isNotNull,
        );
        await tap('Non-Resident / Diaspora');
        await tap('Natural Person');
        await tap('Continue');
        expect(account.entity, EntityType.individual);
        expect(account.nonResident, isFalse);
        expect(find.text('Required Documents'), findsOneWidget);
        await tap('Government ID / International Passport');
        expect(find.text('Which ID will you use?'), findsOneWidget);
        await tap('International Passport');
        expect(find.text('Upload your identity'), findsOneWidget);
        router.go('/investor/verification/entity');
        await tester.pumpAndSettle();
        for (final (label, entity) in [
          ('Trust', EntityType.trust),
          ('Company / SPV', EntityType.company),
          ('Stokvel / Group', EntityType.stokvel),
        ]) {
          await tap(label);
          await tap('Continue');
          expect(account.entity, entity);
          expect(account.nonResident, isFalse);
          expect(
            router.state.uri.path,
            '/investor/kyc/${entity.name}/overview',
          );
          expect(find.text('KYC Checklist'), findsOneWidget);
          await tap('Continue');
          expect(
            find.text(switch (entity) {
              EntityType.trust => 'Trust Deed',
              EntityType.company => 'CIPC Registration',
              EntityType.stokvel => 'Stokvel constitution',
              EntityType.individual => throw StateError('Unexpected entity'),
            }),
            findsOneWidget,
          );
          await tester.tap(find.bySemanticsLabel('Back'));
          await tester.pumpAndSettle();
          expect(find.text('KYC Checklist'), findsOneWidget);
          router.pop();
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<InvestorEntityChoice>(
                  find.widgetWithText(InvestorEntityChoice, label),
                )
                .selected,
            isTrue,
          );
        }
        await tap('Natural Person');
        await reveal('Non-Resident / Diaspora');
        expect(
          tester
              .widget<InvestorEntityChoice>(
                find.widgetWithText(
                  InvestorEntityChoice,
                  'Non-Resident / Diaspora',
                ),
              )
              .selected,
          isFalse,
        );
        await tap('Non-Resident / Diaspora');
        await tap('Trust');
        await tap('Natural Person');
        await reveal('Non-Resident / Diaspora');
        expect(
          tester
              .widget<InvestorEntityChoice>(
                find.widgetWithText(
                  InvestorEntityChoice,
                  'Non-Resident / Diaspora',
                ),
              )
              .selected,
          isFalse,
        );
        dependencies.session.signOut();
        await tester.pumpAndSettle();
        router.go('/investor/verification/documents');
        await tester.pumpAndSettle();
        expect(router.state.uri.path, '/investor/welcome-back');
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Who is investing opens on the entity chosen at registration', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 56, bottom: 34);
    addTearDown(tester.view.reset);
    final dependencies = await AppDependencies.create(
      environment: const AppEnvironment(mockDelay: Duration.zero),
    );
    dependencies.session.signIn(
      const AppUser(
        id: 'kyc-trust',
        name: 'Trust Investor',
        email: 'trust@example.test',
        entity: EntityType.trust,
      ),
      experience: Experience.investor,
    );
    final router = createAppRouter(
      dependencies,
      initialLocation: '/investor/verification/entity',
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
    expect(
      tester
          .widget<InvestorEntityChoice>(
            find.widgetWithText(InvestorEntityChoice, 'Trust'),
          )
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<InvestorEntityChoice>(
            find.widgetWithText(InvestorEntityChoice, 'Natural Person'),
          )
          .selected,
      isFalse,
    );
    router.go('/investor/home');
    await tester.pumpAndSettle();
    dependencies.session.signIn(
      const AppUser(
        id: 'kyc-diaspora',
        name: 'Diaspora Investor',
        email: 'diaspora@example.test',
        nonResident: true,
      ),
      experience: Experience.investor,
    );
    router.go('/investor/verification/entity');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<InvestorEntityChoice>(
            find.widgetWithText(
              InvestorEntityChoice,
              'Non-Resident / Diaspora',
            ),
          )
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<InvestorEntityChoice>(
            find.widgetWithText(InvestorEntityChoice, 'Natural Person'),
          )
          .selected,
      isFalse,
    );
  });
}
