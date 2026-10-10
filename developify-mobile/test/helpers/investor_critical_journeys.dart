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
import 'package:developify_mobile/features/investor/data/mock_kyc_repository.dart';
import 'package:developify_mobile/features/investor/data/kyc_demo_fixtures.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/investor_account_context.dart';
import 'package:developify_mobile/features/investor/domain/investor_repository.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_plan.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_repository.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_review.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_tax.dart';
import 'package:developify_mobile/features/investor/presentation/screens/kyc_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/investor_home_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/explore_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/transfer_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/investment_screen.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_transaction_row.dart';
import 'package:developify_mobile/features/landowner/presentation/home_screen.dart';
import 'package:developify_mobile/features/profile/presentation/profile_screen.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'qa_credentials.dart';

typedef InvestorJourneyCapture =
    Future<void> Function(WidgetTester tester, String name);

void registerInvestorCriticalJourneys({InvestorJourneyCapture? capture}) {
  Future<void> checkpoint(WidgetTester tester, String name) async {
    expect(tester.takeException(), isNull, reason: name);
    debugPrint('Journey checkpoint: $name');
    if (capture != null) await capture(tester, name);
  }

  Future<void> reveal(WidgetTester tester, Finder target) async {
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        target,
        240,
        maxScrolls: 40,
        scrollable: find
            .byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            )
            .hitTestable()
            .first,
      );
    }
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder target) async {
    await reveal(tester, target);
    await tester.tap(target);
    await tester.pump();
    if (find.text('Landowner Portal').evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 700));
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: target.toString());
  }

  Future<void> enter(WidgetTester tester, String label, String value) async {
    final field = find.byKey(ValueKey('field-$label'));
    await reveal(tester, field);
    await tester.enterText(field, value);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, String label, String option) async {
    await tap(tester, find.byKey(ValueKey('field-$label')));
    await tap(tester, find.text(option).last);
  }

  Future<void> document(WidgetTester tester, String label) async {
    await tap(
      tester,
      find.bySemanticsLabel(
        RegExp('^Choose a file for ${RegExp.escape(label)}'),
      ),
    );
    await tap(tester, find.text('Choose Document'));
  }

  Future<void> pin(WidgetTester tester) async {
    await tap(tester, find.text('Use PIN Instead'));
    for (final digit in '1234'.split('')) {
      await tap(tester, find.widgetWithText(TextButton, digit));
    }
  }

  Future<InvestorAccountSnapshot> snapshot(
    WidgetTester tester,
    AppDependencies dependencies,
  ) async =>
      (await tester.runAsync(
                dependencies.container<InvestorAccountRepository>().snapshot,
              )
              as Success<InvestorAccountSnapshot>)
          .value;

  Future<(AppDependencies, GoRouter)> mount(
    WidgetTester tester,
    String path, {
    EntityType? entity,
  }) async {
    final dependencies = await AppDependencies.create(
      environment: const AppEnvironment(
        mockDelay: Duration(milliseconds: 50),
        mockScenario: MockScenario.incompleteKyc,
      ),
    );
    if (entity != null) {
      dependencies.session.signIn(
        AppUser(
          id: 'critical-${entity.name}',
          name: 'Babatunde Yusuf',
          email: 'investor@example.test',
          entity: entity,
        ),
        experience: Experience.investor,
      );
    }
    final router = createAppRouter(dependencies, initialLocation: path);
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

  testWidgets(
    'Investor critical journey from splash through KYC, investment, switching and logout',
    (tester) async {
      final (dependencies, router) = await mount(tester, '/investor/splash');
      await checkpoint(tester, 'investor-cold-splash');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/investor/onboarding');
      await checkpoint(tester, 'investor-onboarding');
      await tap(tester, find.text('Get started'));
      await tap(tester, find.byKey(const ValueKey('terms-declaration')));
      await tap(tester, find.widgetWithText(AppButton, 'Continue'));
      await tap(tester, find.text('I already have an account'));
      await enter(tester, 'Email Address', QaCredentials.email);
      await enter(tester, 'Password', QaCredentials.password);
      await tap(tester, find.byKey(const ValueKey('auth-submit')));
      expect(dependencies.session.isAuthenticated, isTrue);
      final user = dependencies.session.user;
      await checkpoint(tester, 'investor-signed-in');
      await tap(tester, find.text('Complete your verification'));
      await tap(tester, find.text('Start Verification'));
      await tap(tester, find.text('Natural Person'));
      await tap(tester, find.widgetWithText(AppButton, 'Continue'));
      await tap(tester, find.text('Government ID / International Passport'));
      await tap(tester, find.text('International Passport'));
      await document(tester, 'Photo ID Card (Front)');
      await document(tester, 'Photo ID Card (Back)');
      await tap(tester, find.widgetWithText(AppButton, 'Continue'));
      await tap(tester, find.widgetWithText(AppButton, 'Continue').last);
      await tap(tester, find.text('Proof of residential address (< 3 Months)'));
      await document(tester, 'Upload');
      await tap(tester, find.widgetWithText(AppButton, 'Continue'));
      await tap(tester, find.widgetWithText(AppButton, 'Continue').last);
      await choose(tester, 'Bank', 'Standard Bank');
      await enter(tester, 'Account Name', 'Babatunde Yusuf');
      await choose(tester, 'Account Type', 'Savings');
      await enter(tester, 'Acc Number', '041882109');
      await enter(tester, 'Branch Code', '051001');
      await document(tester, 'Upload');
      await tap(
        tester,
        find.widgetWithText(AppButton, 'Submit for verification'),
      );
      await tap(tester, find.widgetWithText(AppButton, 'Continue').last);
      await tap(tester, find.text('Salary / Employment Income'));
      await choose(tester, 'Occupation', 'Employed');
      await enter(tester, 'Employer', 'Marula');
      await enter(tester, 'Annual Income (Rands)', '480000');
      await enter(tester, 'Expected Activity (Rands)', '100000');
      await tap(tester, find.widgetWithText(AppButton, 'Continue'));
      await choose(tester, 'Country of tax residency', 'South Africa');
      await enter(tester, 'Tax Identification Number (TIN)', '9012048127');
      await tap(tester, find.text(KycTaxPlan.pepNo));
      await tap(tester, find.text(KycTaxPlan.sanctions));
      await tap(tester, find.text(KycTaxPlan.declaration));
      await tap(tester, find.widgetWithText(AppButton, 'Continue to review'));
      await tap(
        tester,
        find.text(
          KycReviewPlan.naturalDeclarations
              .firstWhere((field) => field.key == 'reviewConsent')
              .label,
        ),
      );
      await checkpoint(tester, 'investor-natural-review');
      await tap(tester, find.widgetWithText(AppButton, 'Continue'));
      await tap(tester, find.text('Simulate approval'));
      expect(
        tester.widget<KycScreen>(find.byType(KycScreen)).store.draft!.status,
        VerificationStatus.verified,
      );
      await checkpoint(tester, 'investor-natural-approved');
      await tap(tester, find.widgetWithText(AppButton, 'Explore Projects'));
      await tap(tester, find.text('Home').last);
      await checkpoint(tester, 'investor-home-verified');
      await tap(tester, find.text('Explore').last);
      await tap(tester, find.bySemanticsLabel('Search projects'));
      final searchField = find.byKey(const ValueKey('field-'));
      await tester.enterText(searchField, 'No matching project');
      await tester.pumpAndSettle();
      expect(find.text('Result (0)'), findsOneWidget);
      await checkpoint(tester, 'investor-search-keyboard');
      expect(router.state.uri.path, '/investor/explore/search');
      FocusManager.instance.primaryFocus?.unfocus();
      await tap(tester, find.bySemanticsLabel('Clear search'));
      await tester.enterText(searchField, 'Saffron');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(find.text('Saffron Towers'), findsWidgets);
      await checkpoint(tester, 'investor-search-results');
      await tap(tester, find.bySemanticsLabel('Back'));
      final explore = tester
          .widget<ExploreScreen>(find.byType(ExploreScreen))
          .store;
      await tap(tester, find.textContaining('Sort :'));
      await tap(tester, find.text('Commercial'));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(explore.category, isNull);
      await tap(tester, find.textContaining('Sort :'));
      await tap(tester, find.text('Residential'));
      await checkpoint(tester, 'investor-filter');
      await tap(tester, find.widgetWithText(AppButton, 'Apply Filter'));
      expect(
        explore.results.every(
          (project) => project.category.name == 'residential',
        ),
        isTrue,
      );
      await tap(tester, find.text('All').first);
      await tap(tester, find.text('Saffron Towers').first);
      await checkpoint(tester, 'investor-project');
      await tap(tester, find.widgetWithText(AppButton, 'Invest Now'));
      final amount = find.byKey(const ValueKey('investor-amount'));
      await tester.enterText(amount, '0');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AppButton>(
              find.widgetWithText(AppButton, 'Review Investment'),
            )
            .onPressed,
        isNull,
      );
      await tap(tester, amount);
      await tester.enterText(amount, '20000');
      FocusManager.instance.primaryFocus?.unfocus();
      final validation = tester
          .widget<InvestmentScreen>(find.byType(InvestmentScreen))
          .store;
      debugPrint(
        'Native amount before review: ${validation.amountText}; valid: ${validation.validAmount}; error: ${validation.amountError}',
      );
      await tap(tester, find.widgetWithText(AppButton, 'Review Investment'));
      debugPrint(
        'Native amount after review: ${validation.amountText}; stage: ${validation.stage}; error: ${validation.amountError}',
      );
      await checkpoint(tester, 'investor-amount-validation');
      await reveal(tester, find.textContaining('balance is too low'));
      expect(find.textContaining('balance is too low'), findsOneWidget);
      await checkpoint(tester, 'investor-low-balance');
      final before = await snapshot(tester, dependencies);
      await tap(tester, find.text('Top up wallet'));
      await tap(tester, find.text('Bank Transfer'));
      await tap(tester, find.widgetWithText(AppButton, 'Continue'));
      await tester.enterText(
        find.byKey(const ValueKey('investor-amount')),
        '20000',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tap(tester, find.widgetWithText(AppButton, 'Continue'));
      await tap(tester, find.widgetWithText(AppButton, 'Confirm Payment'));
      await pin(tester);
      await checkpoint(tester, 'investor-top-up-success');
      await tap(tester, find.text('Return to investment'));
      expect(
        (await snapshot(tester, dependencies)).balance(Currency.zar),
        before.balance(Currency.zar) +
            const MonetaryAmount(2000000, Currency.zar),
      );
      expect(router.state.uri.path, '/investor/projects/saffron-towers/invest');
      expect(
        tester
            .widget<InvestmentScreen>(find.byType(InvestmentScreen))
            .store
            .amount,
        const MonetaryAmount(2000000, Currency.zar),
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tap(tester, find.widgetWithText(AppButton, 'Review Investment'));
      await tap(tester, find.bySemanticsLabel('Accept investment risks'));
      await tap(tester, find.widgetWithText(AppButton, 'Authorize with PIN'));
      await pin(tester);
      await checkpoint(tester, 'investor-investment-success');
      await tap(tester, find.text('View my portfolio'));
      final invested = await snapshot(tester, dependencies);
      expect(invested.investments.length, before.investments.length + 1);
      expect(invested.balance(Currency.zar), before.balance(Currency.zar));
      await checkpoint(tester, 'investor-portfolio');
      await tap(tester, find.text('Saffron Towers').first);
      expect(router.state.uri.path, startsWith('/investor/investments/'));
      await checkpoint(tester, 'investor-holding');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tap(tester, find.text('Wallet').last);
      await checkpoint(tester, 'investor-wallet');
      await tap(tester, find.text('Withdraw').first);
      final withdrawalBefore = await snapshot(tester, dependencies);
      final withdrawal = tester
          .widget<TransferScreen>(find.byType(TransferScreen))
          .store;
      await tester.enterText(
        find.byKey(const ValueKey('investor-amount')),
        '500',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tap(
        tester,
        find.bySemanticsLabel('Select Access Bank account ending 0119'),
      );
      await tap(tester, find.widgetWithText(AppButton, 'Withdraw'));
      await checkpoint(tester, 'investor-withdrawal-review');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(withdrawal.amountText, '500');
      expect(
        (await snapshot(tester, dependencies)).balance(Currency.zar),
        withdrawalBefore.balance(Currency.zar),
      );
      await tap(tester, find.widgetWithText(AppButton, 'Withdraw'));
      await tap(tester, find.text('Authorize with PIN'));
      await pin(tester);
      expect(find.text('Withdrawal Sent'), findsOneWidget);
      final withdrawn = await snapshot(tester, dependencies);
      expect(
        withdrawn.balance(Currency.zar),
        withdrawalBefore.balance(Currency.zar) -
            const MonetaryAmount(50000, Currency.zar),
      );
      expect(withdrawn.investments.length, withdrawalBefore.investments.length);
      await checkpoint(tester, 'investor-withdrawal-success');
      await tap(tester, find.text('View Receipt'));
      await checkpoint(tester, 'investor-withdrawal-receipt');
      await tap(tester, find.bySemanticsLabel('Back'));
      await tap(tester, find.text('See all').first);
      expect(router.state.uri.path, '/investor/transactions');
      await tap(tester, find.byType(InvestorTransactionRow).first);
      await checkpoint(tester, 'investor-transaction-receipt');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tap(tester, find.text('Home').last);
      await tap(tester, find.bySemanticsLabel('Notifications'));
      await checkpoint(tester, 'investor-notifications');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tap(tester, find.text('Profile').last);
      await checkpoint(tester, 'investor-profile');
      await tap(tester, find.text('Notifications Preferences'));
      final preferences = tester
          .widget<ProfileScreen>(find.byType(ProfileScreen))
          .store;
      final channel = preferences.preferences.channels.entries.first;
      await tap(tester, find.byKey(ValueKey('preference-${channel.key}')));
      expect(preferences.preferences.channels[channel.key], !channel.value);
      await checkpoint(tester, 'investor-preferences');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tap(tester, find.text('Notifications Preferences'));
      expect(
        tester
            .widget<ProfileScreen>(find.byType(ProfileScreen))
            .store
            .preferences
            .channels[channel.key],
        !channel.value,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.bySemanticsLabel(RegExp('^Switch investor profile')),
        -240,
        scrollable: find.byType(Scrollable).hitTestable().first,
      );
      await tap(
        tester,
        find.bySemanticsLabel(RegExp('^Switch investor profile')),
      );
      await tap(tester, find.text('Trust'));
      await tap(tester, find.text('Use this entity'));
      expect(
        dependencies.container<InvestorAccountContext>().entity,
        EntityType.trust,
      );
      await tap(
        tester,
        find.bySemanticsLabel(RegExp('^Switch investor profile')),
      );
      await tap(tester, find.text('Natural Person'));
      await tap(tester, find.text('Use this entity'));
      expect(
        (await snapshot(tester, dependencies)).investments.length,
        invested.investments.length,
      );
      await tap(tester, find.text('Home').last);
      final investorHome = tester
          .widget<InvestorHomeScreen>(find.byType(InvestorHomeScreen))
          .store;
      final switchUser = dependencies.session.user;
      expect(switchUser!.id, user!.id);
      await tap(tester, find.bySemanticsLabel('Switch experience'));
      await tap(tester, find.text('Landowner'));
      final landowner = tester
          .widget<HomeScreen>(find.byType(HomeScreen))
          .store;
      await checkpoint(tester, 'landowner-after-investor');
      await tap(tester, find.byTooltip('Switch experience'));
      await tap(tester, find.text('Investor'));
      expect(
        tester
            .widget<InvestorHomeScreen>(find.byType(InvestorHomeScreen))
            .store,
        same(investorHome),
      );
      await tap(tester, find.bySemanticsLabel('Switch experience'));
      await tap(tester, find.text('Landowner'));
      expect(
        tester.widget<HomeScreen>(find.byType(HomeScreen)).store,
        same(landowner),
      );
      await tap(tester, find.byTooltip('Switch experience'));
      await tap(tester, find.text('Investor'));
      expect(dependencies.session.user, same(switchUser));
      await tap(tester, find.text('Profile').last);
      await tap(tester, find.text('Logout'));
      await tap(tester, find.widgetWithText(AppButton, 'Logout'));
      expect(dependencies.session.isAuthenticated, isFalse);
      router.go('/investor/wallet');
      await tester.pumpAndSettle();
      expect(
        router.state.uri.path,
        anyOf('/investor/sign-in', '/investor/welcome-back'),
      );
      await checkpoint(tester, 'investor-logout-guard');
    },
  );

  for (final entity in [
    EntityType.trust,
    EntityType.company,
    EntityType.stokvel,
  ]) {
    testWidgets('${entity.name} complete KYC fixture reviews and submits', (
      tester,
    ) async {
      final (dependencies, router) = await mount(
        tester,
        '/investor/home',
        entity: entity,
      );
      final repository = dependencies.container<KycRepository>();
      await tester.runAsync(() => seedCompleteEntityKyc(repository, entity));
      await tap(tester, find.text('Profile').last);
      await tap(tester, find.text('Identity Verification (KYC)'));
      var store = tester.widget<KycScreen>(find.byType(KycScreen)).store;
      await tap(tester, find.widgetWithText(AppButton, 'Continue'));
      final fundsEdit = entity == EntityType.trust
          ? find.text('6. Source of Trust Funds')
          : find.byKey(const ValueKey('review-edit-funds'));
      await tap(tester, fundsEdit);
      expect(store.selectedStep, 'funds');
      final amountKey = entity == EntityType.stokvel
          ? 'contribution'
          : 'annualInvestment';
      final amount = find.descendant(
        of: find.byKey(ValueKey(amountKey)),
        matching: find.byType(TextFormField),
      );
      await reveal(tester, amount);
      await tester.enterText(amount, '1500');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tap(tester, find.widgetWithText(AppButton, 'Save & Exit'));
      await tap(tester, find.text('Keep editing'));
      expect(store.selectedStep, 'funds');
      expect(store.draft!.values[amountKey], '1500');
      await tap(tester, find.widgetWithText(AppButton, 'Save & Exit'));
      await tap(
        tester,
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(TextButton, 'Save & Exit'),
        ),
      );
      expect(find.byType(KycScreen), findsNothing);
      await tap(tester, find.text('Identity Verification (KYC)'));
      store = tester.widget<KycScreen>(find.byType(KycScreen)).store;
      expect(store.draft!.values[amountKey], '1500');
      if (store.selectedStep == 'overview') {
        await tap(tester, find.widgetWithText(AppButton, 'Continue'));
      }
      if (store.selectedStep == 'funds') {
        await tap(tester, find.widgetWithText(AppButton, 'Save and Continue'));
      }
      expect(store.selectedStep, 'review');
      await checkpoint(tester, '${entity.name}-saved-resumed');
      for (final declaration in KycReviewPlan.declarations(entity)) {
        if (store.draft!.values[declaration.key] != 'true') {
          await tap(tester, find.text(declaration.label));
        }
      }
      expect(store.canSubmit, isTrue);
      await checkpoint(tester, '${entity.name}-review');
      await tap(
        tester,
        find.widgetWithText(
          AppButton,
          entity == EntityType.trust ? 'Submit' : 'Submit for Verification',
        ),
      );
      expect(store.draft!.status, VerificationStatus.pending);
      await checkpoint(tester, '${entity.name}-pending');
      if (entity == EntityType.trust) {
        await tap(tester, find.text('View Status'));
      }
      await tap(tester, find.text('Request correction'));
      expect(store.draft!.status, VerificationStatus.correctionRequired);
      expect(store.canSubmit, isFalse);
      final rejected = store.draft!.documents.entries.firstWhere(
        (entry) => entry.value.rejection != null,
      );
      final correctionStep = store.steps.firstWhere(
        (step) =>
            step.documents.any((document) => document.key == rejected.key),
      );
      await checkpoint(tester, '${entity.name}-correction-required');
      await tap(
        tester,
        entity == EntityType.trust
            ? find.text(
                correctionStep.id == 'authority'
                    ? '2. Letter of Authority'
                    : '1. Trust Deed',
              )
            : find.byKey(ValueKey('review-edit-${correctionStep.id}')),
      );
      expect(store.selectedStep, correctionStep.id);
      final replace = find.bySemanticsLabel(RegExp('^Replace ')).first;
      await tap(tester, replace);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(store.draft!.documents[rejected.key]!.rejection, isNotNull);
      (repository as MockKycRepository).behavior.failNext();
      await tap(tester, replace);
      await tap(tester, find.text('Choose Document'));
      expect(find.text('Failed'), findsOneWidget);
      expect(store.draft!.documents[rejected.key]!.rejection, isNotNull);
      await tap(tester, find.text('Try Again'));
      expect(store.draft!.documents[rejected.key]!.rejection, isNull);
      expect(store.canContinue, isTrue);
      await tap(tester, find.widgetWithText(AppButton, 'Save and Continue'));
      expect(store.selectedStep, 'review');
      await tap(
        tester,
        find.widgetWithText(
          AppButton,
          entity == EntityType.trust ? 'Submit' : 'Submit for Verification',
        ),
      );
      expect(store.draft!.status, VerificationStatus.pending);
      if (entity == EntityType.trust) {
        await tap(tester, find.text('View Status'));
      }
      await tap(tester, find.text('Simulate approval'));
      expect(store.draft!.status, VerificationStatus.verified);
      expect(
        (await snapshot(tester, dependencies)).verification,
        VerificationStatus.verified,
      );
      await checkpoint(tester, '${entity.name}-approved');
    });
  }
}

Future<void> seedCompleteEntityKyc(
  KycRepository repository,
  EntityType entity,
) async {
  KycDraft accept(Result<KycDraft> result) => switch (result) {
    Success(:final value) => value,
    Failure(:final error) => throw StateError(
      '${error.message}: ${error.fields}',
    ),
  };
  final fixture = KycDemoFixtures.verified(entity, DateTime(2026, 7, 22));
  final current = accept(await repository.load(entity));
  accept(repository.save(current.copyWith(values: fixture.values)));
  for (final entry in fixture.documents.entries) {
    accept(
      await repository.upload(
        entity,
        entry.key,
        name: entry.value.name,
        bytes: entry.value.bytes,
        mimeType: entry.value.mimeType,
      ),
    );
  }
  for (final member in fixture.members) {
    accept(repository.saveMember(entity, member));
  }
  if (entity != EntityType.stokvel) {
    accept(await repository.requestResolutionSignatures(entity));
    final resolution = KycPlans.steps(
      entity,
    ).firstWhere((step) => step.id == 'resolution');
    for (final member in fixture.members.where(resolution.includesMember)) {
      accept(await repository.simulateResolutionSignature(entity, member.id));
    }
  }
  accept(
    repository.save(
      accept(await repository.load(entity)).copyWith(currentStep: 'review'),
    ),
  );
}
