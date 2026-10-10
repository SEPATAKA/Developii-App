import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/features/investor/presentation/screens/kyc_member_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/kyc_screen.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_repository.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_review.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'helpers/fonts.dart';
import 'helpers/investor_member_fixtures.dart';

void main() {
  setUpAll(loadAppFonts);
  Future<AppDependencies> dependencies() async {
    final deps = await AppDependencies.create(
      environment: const AppEnvironment(
        mockDelay: Duration.zero,
        mockScenario: MockScenario.incompleteKyc,
      ),
    );
    deps.session.signIn(
      const AppUser(
        id: 'member-journeys',
        name: 'Investor',
        email: 'investor@example.test',
      ),
      experience: Experience.investor,
    );
    return deps;
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Finder input(String key) => find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(TextFormField),
  );
  Future<void> enter(WidgetTester tester, String key, String value) async {
    await tester.ensureVisible(input(key));
    await tester.enterText(input(key), value);
    await tester.pumpAndSettle();
  }

  Future<void> select(WidgetTester tester, String key, String value) async {
    await tap(tester, input(key));
    await tap(tester, find.text(value).last);
  }

  Future<void> date(WidgetTester tester, String key) async {
    await tap(tester, input(key));
    await tap(tester, find.text('OK'));
  }

  Future<void> upload(WidgetTester tester, String title) async {
    await tap(
      tester,
      find.bySemanticsLabel(
        RegExp('^Choose a file for ${RegExp.escape(title)}'),
      ),
    );
    await tap(tester, find.text('Choose Document'));
  }

  for (final entity in ['trust', 'company']) {
    testWidgets(
      '$entity resolution requests, previews, signs and continues with the uploaded document',
      (tester) async {
        tester.view.physicalSize = const Size(393, 852);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final deps = await dependencies();
        await tester.runAsync(
          () => seedInvestorMemberFrame(
            deps.container<KycRepository>(),
            entity == 'trust' ? '56805' : '81662',
          ),
        );
        final router = createAppRouter(
          deps,
          initialLocation: '/investor/kyc/$entity/resolution',
        );
        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        await tester.pumpWidget(
          DevelopifyApp(dependencies: deps, router: router),
        );
        await tester.pumpAndSettle();
        try {
          await enter(tester, 'signatory', 'Adaeze Okoye');
          final store = tester.widget<KycScreen>(find.byType(KycScreen)).store;
          expect(store.members.every((member) => !member.signed), isTrue);
          if (entity == 'trust') {
            for (final member in store.members.toList()) {
              await tap(
                tester,
                find.descendant(
                  of: find.byKey(ValueKey('signature-${member.id}')),
                  matching: find.widgetWithText(TextButton, 'Request'),
                ),
              );
            }
          } else {
            await tap(tester, find.text('Send for signature'));
          }
          expect(
            store.members.every(
              (member) =>
                  member.resolutionSignature.status ==
                  KycSignatureStatus.awaiting,
            ),
            isTrue,
          );
          for (final member in store.members.toList()) {
            await tap(tester, find.byKey(ValueKey('signature-${member.id}')));
            expect(find.text('Resolution preview'), findsOneWidget);
            await tap(tester, find.text('Copy preview'));
            expect(copied, contains(member.name));
            expect(copied, contains('No legal signature has been issued.'));
            await tap(
              tester,
              find.widgetWithText(AppButton, 'Simulate signature'),
            );
            expect(find.text('Signature recorded in demo'), findsOneWidget);
            await tap(tester, find.text('Close'));
          }
          expect(store.members.every((member) => member.signed), isTrue);
          expect(store.canContinue, isFalse);
          await upload(
            tester,
            entity == 'trust' ? 'Upload Signed Resolution' : 'Upload',
          );
          expect(store.canContinue, isTrue);
          await tap(
            tester,
            find.widgetWithText(AppButton, 'Save and Continue'),
          );
          expect(
            store.selectedStep,
            entity == 'trust' ? 'trustees' : 'directors',
          );
          expect(
            find.text(entity == 'trust' ? 'Trustee KYC' : 'Directors & UBO'),
            findsOneWidget,
          );
          expect(store.draft!.completedSteps, contains('resolution'));
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox());
          router.dispose();
          await tester.runAsync(deps.dispose);
        }
      },
    );
  }

  testWidgets(
    'Trust review saves declarations, returns edited details and submits pending checks',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final deps = await dependencies();
      await tester.runAsync(
        () => seedInvestorMemberFrame(deps.container<KycRepository>(), '59009'),
      );
      final router = createAppRouter(
        deps,
        initialLocation: '/investor/kyc/trust/review',
      );
      await tester.pumpWidget(
        DevelopifyApp(dependencies: deps, router: router),
      );
      await tester.pumpAndSettle();
      try {
        final store = tester.widget<KycScreen>(find.byType(KycScreen)).store;
        expect(
          tester
              .widget<AppButton>(find.widgetWithText(AppButton, 'Submit'))
              .onPressed,
          isNull,
        );
        for (final field in KycReviewPlan.trustDeclarations) {
          await tap(tester, find.byKey(ValueKey(field.key)));
        }
        expect(store.canSubmit, isTrue);
        await tap(tester, find.text('6. Source of Trust Funds'));
        expect(store.selectedStep, 'funds');
        await enter(tester, 'annualInvestment', '1250000');
        await tap(tester, find.widgetWithText(AppButton, 'Save and Continue'));
        expect(store.selectedStep, 'review');
        expect(find.text('R 1,250,000'), findsOneWidget);
        expect(store.canSubmit, isTrue);
        await tap(tester, find.widgetWithText(AppButton, 'Submit'));
        expect(find.text('Submitted for review'), findsOneWidget);
        expect(store.draft!.status, VerificationStatus.pending);
        await tap(tester, find.text('View Status'));
        expect(find.text('Your application is in review'), findsOneWidget);
        await tap(tester, find.text('Simulate approval'));
        expect(store.draft!.status, VerificationStatus.pending);
        expect(
          find.text(
            'Resolve the pending verification items before simulating approval.',
          ),
          findsOneWidget,
        );
        await tap(tester, find.text('Request correction'));
        expect(store.draft!.status, VerificationStatus.correctionRequired);
        expect(store.canSubmit, isFalse);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        await tester.runAsync(deps.dispose);
      }
    },
  );

  testWidgets(
    'beneficiary journey adds guardian documents, allocates and returns with saved details',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final deps = await dependencies();
      final router = createAppRouter(
        deps,
        initialLocation: '/investor/kyc/trust/beneficiaries',
      );
      await tester.pumpWidget(
        DevelopifyApp(dependencies: deps, router: router),
      );
      await tester.pumpAndSettle();
      try {
        await enter(tester, 'founderName', 'Thandi Okoye');
        await enter(tester, 'founderIdentity', 'mock-founder');
        await select(tester, 'founderCountry', 'South Africa');
        await tap(tester, find.text('Add a beneficiary'));
        await enter(tester, 'member-firstName', 'Adaeze');
        await enter(tester, 'member-lastName', 'Okoye');
        await enter(tester, 'member-identityNumber', 'mock-child');
        await date(tester, 'member-birthDate');
        await select(tester, 'member-relationship', 'Child');
        await enter(tester, 'member-guardianName', 'Thandi Okoye');
        await enter(tester, 'member-guardianIdentity', 'mock-guardian');
        await select(tester, 'member-guardianCountry', 'South Africa');
        await upload(tester, 'Birth Certificate or ID copy');
        await upload(tester, 'Guardian’s ID Copy');
        await tap(tester, find.widgetWithText(AppButton, 'Save & continue'));
        expect(find.text('Amount Allocation'), findsOneWidget);
        await tester.drag(find.byType(Slider), const Offset(400, 0));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<KycMemberScreen>(find.byType(KycMemberScreen))
              .store
              .totalAllocation,
          10000,
        );
        await tap(tester, find.widgetWithText(AppButton, 'Save & continue'));
        final main = tester.widget<KycScreen>(find.byType(KycScreen)).store;
        expect(
          main.draft!.members.single.details!.guardianName,
          'Thandi Okoye',
        );
        expect(main.draft!.members.single.shareBasisPoints, 10000);
        expect(main.canContinue, isTrue);
        await tap(tester, find.text('Adaeze Okoye'));
        await tap(tester, find.text('Edit Details'));
        expect(
          tester
              .widget<KycMemberScreen>(find.byType(KycMemberScreen))
              .store
              .values['firstName'],
          'Adaeze',
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        await tester.runAsync(deps.dispose);
      }
    },
  );

  testWidgets(
    'shareholder journey derives ownership and saves every supporting document',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final deps = await dependencies();
      final router = createAppRouter(
        deps,
        initialLocation: '/investor/kyc/company/shareholders',
      );
      await tester.pumpWidget(
        DevelopifyApp(dependencies: deps, router: router),
      );
      await tester.pumpAndSettle();
      try {
        await tap(tester, find.text('Add a shareholder'));
        await enter(tester, 'member-firstName', 'Adaeze');
        await enter(tester, 'member-lastName', 'Okoye');
        await enter(tester, 'member-identityNumber', 'mock-shareholder');
        await tap(tester, find.text('Also a director of the company'));
        await select(tester, 'member-shareClass', 'Ordinary');
        await enter(tester, 'member-numberOfShares', '1000');
        await enter(tester, 'member-issuedShares', '1000');
        await date(tester, 'member-acquiredOn');
        await enter(tester, 'member-acquisition', 'Founding issue');
        for (final title in [
          'Upload Certified ID / Passport',
          'Proof of address (< 3 months)',
          'Share certificate / issue resolution',
        ]) {
          await upload(tester, title);
        }
        await tap(tester, find.widgetWithText(AppButton, 'Update Register'));
        final main = tester.widget<KycScreen>(find.byType(KycScreen)).store;
        expect(main.draft!.members.single.shareBasisPoints, 10000);
        expect(main.draft!.members.single.details!.isDirector, isTrue);
        expect(main.draft!.members.single.details!.documents, hasLength(3));
        await upload(tester, 'Upload');
        expect(main.canContinue, isTrue);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        await tester.runAsync(deps.dispose);
      }
    },
  );

  testWidgets(
    'trust invitation previews the entered recipient and returns a pending trustee',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final deps = await dependencies();
      final router = createAppRouter(
        deps,
        initialLocation: '/investor/kyc/trust/trustees',
      );
      await tester.pumpWidget(
        DevelopifyApp(dependencies: deps, router: router),
      );
      await tester.pumpAndSettle();
      try {
        await tap(tester, find.text('Email Invite link'));
        await enter(tester, 'invite-email', 'thandi@example.test');
        await tap(tester, find.byKey(const ValueKey('phone-country')));
        await tap(tester, find.text('United Kingdom (+44)'));
        await enter(tester, 'invite-phone', '7700 900123');
        await tap(tester, find.text('Send SMS with link too'));
        await tap(tester, find.text('T - 104 Acknowledgment of Appointment'));
        await enter(tester, 'invite-message', 'Welcome to the trust.');
        await tap(tester, find.widgetWithText(AppButton, 'Preview email'));
        expect(find.text('thandi@example.test'), findsOneWidget);
        expect(find.text('Welcome to the trust.'), findsOneWidget);
        expect(
          tester
              .widget<KycMemberScreen>(find.byType(KycMemberScreen))
              .store
              .invitation
              .phone,
          '+447700900123',
        );
        await tap(tester, find.widgetWithText(AppButton, 'Back to edit'));
        expect(
          tester
              .widget<KycMemberScreen>(find.byType(KycMemberScreen))
              .store
              .values['message'],
          'Welcome to the trust.',
        );
        await tap(tester, find.widgetWithText(AppButton, 'Send Invite'));
        expect(find.text('Invite Sent!'), findsOneWidget);
        await tap(tester, find.widgetWithText(AppButton, 'Track all invites'));
        final main = tester.widget<KycScreen>(find.byType(KycScreen)).store;
        expect(main.members.single.email, 'thandi@example.test');
        expect(main.members.single.inviteSent, isTrue);
        expect(main.canContinue, isTrue);
        expect(main.canSubmit, isFalse);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        await tester.runAsync(deps.dispose);
      }
    },
  );

  testWidgets('invalid member route parameters show a controlled error', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final deps = await dependencies();
    final router = createAppRouter(deps, initialLocation: '/investor/home');
    await tester.pumpWidget(DevelopifyApp(dependencies: deps, router: router));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'Home before invalid route');
    try {
      for (final path in [
        '/investor/kyc/individual/member/trustee/details',
        '/investor/kyc/trust/member/director/details',
        '/investor/kyc/trust/member/beneficiary/missing',
        '/investor/kyc/trust/member/beneficiary/details?id=',
        '/investor/kyc/trust/member/beneficiary/details?id=missing',
        '/investor/kyc/trust/member/beneficiary/allocation',
        '/investor/kyc/trust/member/beneficiary/details?return=missing',
        '/investor/kyc/trust/member/beneficiary/details?return=tax',
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(
          find.textContaining('could not be found'),
          findsOneWidget,
          reason: path,
        );
        expect(find.byType(TextFormField), findsNothing, reason: path);
        final retry = find.widgetWithText(AppButton, 'Try again');
        await tester.ensureVisible(retry);
        await tester.pumpAndSettle();
        expect(retry.hitTestable(), findsOneWidget, reason: path);
        expect(tester.takeException(), isNull, reason: path);
      }
    } finally {
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await tester.runAsync(deps.dispose);
    }
  });

  testWidgets(
    'Stokvel invites and completes both office bearers before continuing',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final deps = await dependencies();
      final router = createAppRouter(
        deps,
        initialLocation: '/investor/kyc/stokvel/resolution',
      );
      await tester.pumpWidget(
        DevelopifyApp(dependencies: deps, router: router),
      );
      await tester.pumpAndSettle();
      try {
        await date(tester, 'meetingDate');
        await enter(tester, 'membersPresent', '22');
        await enter(tester, 'authorisedAmount', '100000');
        await select(tester, 'signatory', 'Chairperson + Treasurer');
        await upload(tester, 'Upload signed minutes');
        await tap(tester, find.widgetWithText(AppButton, 'Save and Continue'));
        expect(
          tester.widget<KycScreen>(find.byType(KycScreen)).store.selectedStep,
          'officers',
        );
        for (final (role, firstName, lastName, email) in [
          ('Chairperson', 'Nomthandazo', 'Hadebe', 'chair@example.test'),
          ('Treasurer', 'Bongani', 'Mthembu', 'treasurer@example.test'),
        ]) {
          await tap(tester, find.text('Email Invite link'));
          await tap(tester, find.text(role));
          await enter(tester, 'invite-email', email);
          await tap(tester, find.widgetWithText(AppButton, 'Send Invite'));
          expect(find.text('Invite Sent!'), findsOneWidget);
          await tap(
            tester,
            find.widgetWithText(AppButton, 'Track all invites'),
          );
          var main = tester.widget<KycScreen>(find.byType(KycScreen)).store;
          expect(main.canContinue, isFalse);
          await tap(tester, find.text(email));
          await tap(tester, find.text('Edit Details'));
          await enter(tester, 'member-firstName', firstName);
          await enter(tester, 'member-lastName', lastName);
          await enter(tester, 'member-identityNumber', 'mock-$role');
          await upload(tester, 'Upload Certified ID / Passport');
          await upload(tester, 'Proof of address (< 3 months)');
          await tap(tester, find.widgetWithText(AppButton, 'Save & continue'));
          main = tester.widget<KycScreen>(find.byType(KycScreen)).store;
          final saved = main.members.singleWhere(
            (member) => member.email == email,
          );
          expect(saved.identityVerified && saved.addressVerified, isTrue);
          expect(saved.details!.documents, hasLength(2));
        }
        final main = tester.widget<KycScreen>(find.byType(KycScreen)).store;
        expect(main.canContinue, isTrue);
        await tap(tester, find.widgetWithText(AppButton, 'Save and Continue'));
        expect(main.selectedStep, 'register');
        expect(main.canContinue, isFalse);
        await upload(tester, 'Member register (summary)');
        expect(main.canContinue, isTrue);
        expect(main.draft!.documents, contains('memberRegister'));
        await tap(tester, find.widgetWithText(AppButton, 'Save and Continue'));
        expect(main.selectedStep, 'bank');
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        await tester.runAsync(deps.dispose);
      }
    },
  );

  for (final width in [360.0, 393.0, 430.0]) {
    testWidgets(
      'member and invite forms retain input above the keyboard at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 852);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final deps = await dependencies();
        final router = createAppRouter(deps, initialLocation: '/investor/home');
        await tester.pumpWidget(
          DevelopifyApp(dependencies: deps, router: router),
        );
        await tester.pumpAndSettle();
        try {
          for (final scale in [1.0, 1.6]) {
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            for (final (path, key, value, button) in [
              (
                '/investor/kyc/trust/member/beneficiary/details',
                'member-firstName',
                'Saved beneficiary',
                'Save & continue',
              ),
              (
                '/investor/kyc/company/member/shareholder/details',
                'member-firstName',
                'Saved shareholder',
                'Update Register',
              ),
              (
                '/investor/kyc/stokvel/member/treasurer/details',
                'member-firstName',
                'Saved treasurer',
                'Save & continue',
              ),
              (
                '/investor/kyc/trust/member/trustee/invite',
                'invite-email',
                'saved@example.test',
                'Send Invite',
              ),
            ]) {
              router.go(path);
              await tester.pumpAndSettle();
              await enter(tester, key, value);
              tester.view.viewInsets = const FakeViewPadding(bottom: 320);
              await tester.pumpAndSettle();
              await tester.ensureVisible(input(key));
              await tester.pumpAndSettle();
              final footer = find.widgetWithText(AppButton, button);
              expect(
                footer.hitTestable(),
                findsOneWidget,
                reason: '$path $scale',
              );
              expect(
                tester.getRect(footer).bottom,
                lessThanOrEqualTo(532),
                reason: '$path $scale',
              );
              expect(tester.takeException(), isNull, reason: '$path $scale');
              FocusManager.instance.primaryFocus?.unfocus();
              tester.view.resetViewInsets();
              router.go('/investor/home');
              await tester.pumpAndSettle();
              router.go(path);
              await tester.pumpAndSettle();
              final store = tester
                  .widget<KycMemberScreen>(find.byType(KycMemberScreen))
                  .store;
              expect(
                store.values[key == 'invite-email' ? 'email' : 'firstName'],
                value,
              );
            }
          }
        } finally {
          await tester.pumpWidget(const SizedBox());
          router.dispose();
          await tester.runAsync(deps.dispose);
        }
      },
    );
  }
}
