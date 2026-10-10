import 'package:developify_mobile/features/investor/presentation/screens/calculator_project_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/router/app_transition_page.dart';
import 'package:developify_mobile/app/router/route_names.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/utils/lifecycle.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/authentication/presentation/auth_screen.dart';
import 'package:developify_mobile/features/authentication/presentation/recovery_screen.dart';
import 'package:developify_mobile/features/authentication/presentation/stores/auth_store.dart';
import 'package:developify_mobile/features/authentication/presentation/stores/recovery_store.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/investor_account_context.dart';
import 'package:developify_mobile/features/investor/domain/investor_drafts.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/investor_shell.dart';
import 'package:developify_mobile/features/investor/presentation/screens/explore_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/investor_search_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/explore_filter_screen.dart';
import 'package:developify_mobile/features/investor/domain/investor_project.dart';
import 'package:developify_mobile/features/investor/presentation/screens/investment_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/investor_entry_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/investor_home_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/investor_notifications_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/investor_profile_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/investor_signup_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/kyc_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/kyc_entry_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/kyc_tax_screen.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_tax.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_plan.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_member_plan.dart';
import 'package:developify_mobile/features/investor/presentation/screens/kyc_member_screen.dart';
import 'package:developify_mobile/features/investor/presentation/stores/kyc_member_store.dart';
import 'package:developify_mobile/features/investor/presentation/screens/payment_methods_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/portfolio_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/project_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/project_content_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/risk_profile_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/transactions_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/transfer_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/wallet_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/investment_timeline_screen.dart';
import 'package:developify_mobile/features/investor/presentation/stores/explore_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investment_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investor_home_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investor_notifications_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investor_profile_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investor_signup_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/kyc_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/payment_methods_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/portfolio_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/project_detail_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/transactions_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/transfer_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/wallet_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/notifications/presentation/chat_screen.dart';
import 'package:developify_mobile/features/notifications/presentation/chat_store.dart';
import 'package:developify_mobile/features/profile/presentation/information_screen.dart';
import 'package:developify_mobile/features/profile/presentation/profile_screen.dart';
import 'package:developify_mobile/features/profile/presentation/security_screen.dart';
import 'package:developify_mobile/features/profile/presentation/stores/information_store.dart';
import 'package:developify_mobile/features/profile/presentation/stores/profile_store.dart';
import 'package:developify_mobile/features/profile/presentation/stores/security_store.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'package:developify_mobile/features/onboarding/presentation/onboarding_screen.dart';

EntityType? investorEntity(String? name) {
  for (final value in EntityType.values) {
    if (value.name == name) return value;
  }
  return null;
}

GoRoute _route(
  String name,
  String path,
  Widget Function(BuildContext, GoRouterState) builder, {
  bool tab = false,
}) => GoRoute(
  name: name,
  path: path,
  pageBuilder: (context, state) => tab
      ? NoTransitionPage<void>(
          key: state.pageKey,
          name: name,
          child: builder(context, state),
        )
      : AppTransitionPage(
          key: state.pageKey,
          name: name,
          reducedMotion: AppDurations.reducedMotion(context),
          child: builder(context, state),
        ),
);

Widget _scope<T extends Object>({
  required GoRouterState state,
  required T Function() create,
  required Widget Function(BuildContext, T) builder,
  Future<void> Function(T)? initialize,
  bool screenDisposes = false,
}) => FeatureScope<T>(
  key: ValueKey('${state.name}:${state.uri}'),
  create: create,
  initialize: initialize == null
      ? null
      : (store) => unawaited(initialize(store)),
  dispose: screenDisposes
      ? (_) {}
      : (store) {
          if (store is Lifecycle) store.dispose();
        },
  builder: builder,
);

List<RouteBase> investorPublicRoutes(AppDependencies dependencies) {
  final get = dependencies.container;
  return [
    _route(
      InvestorRoutes.splash,
      '/investor/splash',
      (context, _) => SplashScreen(
        onReady: () => context.goNamed(
          dependencies.session.isAuthenticated
              ? InvestorRoutes.home
              : dependencies.session.onboardingComplete
              ? InvestorRoutes.welcome
              : InvestorRoutes.onboarding,
        ),
      ),
      tab: true,
    ),
    _route(
      InvestorRoutes.onboarding,
      '/investor/onboarding',
      (_, _) => const InvestorOnboardingScreen(),
    ),
    _route(
      InvestorRoutes.welcome,
      '/investor/welcome',
      (_, state) => InvestorWelcomeScreen(
        fromOnboarding: state.uri.queryParameters['entry'] == 'onboarding',
      ),
    ),
    for (final returning in [false, true])
      _route(
        returning ? InvestorRoutes.welcomeBack : InvestorRoutes.signIn,
        returning ? '/investor/welcome-back' : '/investor/sign-in',
        (_, state) => _scope<AuthStore>(
          state: state,
          create: () => get<AuthStore>(param1: Experience.investor),
          screenDisposes: true,
          builder: (_, store) => AuthScreen(
            store: store,
            returning: returning,
            routePrefix: 'investor-',
            showSocial: false,
          ),
        ),
      ),
    _route(
      InvestorRoutes.recovery,
      '/investor/forgot-password',
      (_, state) => _scope<RecoveryStore>(
        state: state,
        create: () => get<RecoveryStore>(),
        screenDisposes: true,
        builder: (_, store) =>
            RecoveryScreen(store: store, routePrefix: 'investor-'),
      ),
    ),
    _route(InvestorRoutes.signUp, '/investor/create-account', (context, state) {
      final rawEntity = state.uri.queryParameters['entity'];
      final entity = investorEntity(rawEntity ?? 'individual');
      if (entity == null) {
        return InvestorPage(
          title: 'Create Profile',
          child: ErrorView(
            message: 'This investor type could not be found.',
            onRetry: () => context.goNamed(InvestorRoutes.welcome),
          ),
        );
      }
      return _scope<InvestorSignupStore>(
        state: state,
        create: () => get<InvestorSignupStore>(
          param1: entity,
          param2: state.uri.queryParameters['nonResident'] == 'true',
        ),
        builder: (_, store) => InvestorSignupScreen(store: store),
      );
    }),
    for (final item in [
      (Routes.terms, InformationPage.terms),
      (Routes.privacy, InformationPage.privacy),
      (Routes.legal, InformationPage.onboardingTerms),
    ])
      _route(
        'investor-${item.$1}',
        '/investor/${item.$1}',
        (_, state) => _scope<InformationStore>(
          state: state,
          create: () => get<InformationStore>(),
          builder: (context, store) => InformationScreen(
            page: item.$2,
            store: store,
            routePrefix: 'investor-',
            onConsentAccepted: item.$2 == InformationPage.onboardingTerms
                ? () {
                    dependencies.session.completeOnboarding();
                    context.goNamed(
                      InvestorRoutes.welcome,
                      queryParameters: const {'entry': 'onboarding'},
                    );
                  }
                : null,
          ),
        ),
      ),
  ];
}

List<RouteBase> investorAuthenticatedRoutes(
  AppDependencies dependencies, {
  required VoidCallback onLogout,
}) {
  final get = dependencies.container;
  EntityType entity() => get<InvestorAccountContext>().entity;
  GoRoute feature<T extends Lifecycle>(
    String name,
    String path,
    Widget Function(BuildContext, GoRouterState, T) builder, {
    required Future<void> Function(T, GoRouterState) initialize,
    bool tab = false,
  }) => _route(
    name,
    path,
    (_, state) => _scope<T>(
      state: state,
      create: () => get<T>(),
      initialize: (store) => initialize(store, state),
      builder: (context, store) => builder(context, state, store),
    ),
    tab: tab,
  );
  return [
    StatefulShellRoute.indexedStack(
      pageBuilder: (_, state, shell) => NoTransitionPage<void>(
        key: state.pageKey,
        child: InvestorShell(shell: shell),
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            feature<InvestorHomeStore>(
              InvestorRoutes.home,
              '/investor/home',
              (_, _, store) => InvestorHomeScreen(
                store: store,
                entity: entity,
                session: dependencies.session,
              ),
              initialize: (store, _) => store.load(),
              tab: true,
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            feature<ExploreStore>(
              InvestorRoutes.explore,
              '/investor/explore',
              (context, state, store) =>
                  ProjectFilter.tryParse(state.uri.queryParameters) == null
                  ? InvestorPage(
                      title: 'Explore',
                      child: ErrorView(
                        message: 'This project filter is invalid.',
                        onRetry: () => context.goNamed(InvestorRoutes.explore),
                      ),
                    )
                  : ExploreScreen(store: store),
              initialize: (store, state) async {
                final filter = ProjectFilter.tryParse(
                  state.uri.queryParameters,
                );
                if (filter != null) store.applyFilter(filter);
                await store.load();
              },
              tab: true,
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            feature<WalletStore>(
              InvestorRoutes.wallet,
              '/investor/wallet',
              (_, _, store) => WalletScreen(store: store),
              initialize: (store, _) => store.load(),
              tab: true,
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            feature<PortfolioStore>(
              InvestorRoutes.portfolio,
              '/investor/portfolio',
              (_, _, store) => PortfolioScreen(store: store),
              initialize: (store, _) => store.load(),
              tab: true,
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            feature<InvestorProfileStore>(
              InvestorRoutes.profile,
              '/investor/profile',
              (_, _, store) =>
                  InvestorProfileScreen(store: store, onLogout: onLogout),
              initialize: (store, _) => store.load(),
              tab: true,
            ),
          ],
        ),
      ],
    ),
    _route(InvestorRoutes.filters, '/investor/explore/filters', (
      context,
      state,
    ) {
      final initial = ProjectFilter.tryParse(state.uri.queryParameters);
      if (initial == null) {
        return InvestorPage(
          title: 'Filter Projects',
          child: ErrorView(
            message: 'These project filters are not valid.',
            onRetry: () => context.goNamed(InvestorRoutes.filters),
          ),
        );
      }
      return _scope<ExploreStore>(
        state: state,
        create: () => get<ExploreStore>()..applyFilter(initial),
        builder: (_, store) =>
            ExploreFilterScreen(store: store, initial: initial),
      );
    }),
    for (final (name, path, wishlist) in const [
      (InvestorRoutes.search, '/investor/explore/search', false),
      (InvestorRoutes.wishlist, '/investor/explore/wishlist', true),
    ])
      feature<ExploreStore>(
        name,
        path,
        (context, state, store) {
          final query = state.uri.queryParameters['q'] ?? '';
          final valid =
              query.length <= 120 &&
              (state.uri.queryParametersAll['q']?.length ?? 0) <= 1 &&
              state.uri.queryParameters.keys.every((key) => key == 'q');
          return valid
              ? InvestorSearchScreen(store: store, wishlist: wishlist)
              : InvestorPage(
                  title: wishlist ? 'Wishlist' : 'Search',
                  child: ErrorView(
                    message: 'This project search is invalid.',
                    onRetry: () => context.goNamed(name),
                  ),
                );
        },
        initialize: (store, state) async {
          final query = state.uri.queryParameters['q'] ?? '';
          if (query.length <= 120) store.search(query);
          if (wishlist) store.toggleFavourites();
          await store.load();
        },
      ),
    feature<InvestorProjectDetailStore>(
      InvestorRoutes.project,
      '/investor/projects/:id',
      (_, state, store) =>
          InvestorProjectScreen(store: store, id: state.pathParameters['id']!),
      initialize: (store, state) => store.load(state.pathParameters['id']!),
    ),
    for (final (name, suffix, page) in const [
      (InvestorRoutes.projectDetails, 'details', ProjectContentPage.details),
      (
        InvestorRoutes.projectDeveloper,
        'developer',
        ProjectContentPage.developer,
      ),
      (InvestorRoutes.projectUpdates, 'updates', ProjectContentPage.updates),
      (
        InvestorRoutes.projectUpdate,
        'updates/:updateId',
        ProjectContentPage.update,
      ),
      (InvestorRoutes.projectLocation, 'location', ProjectContentPage.location),
      (InvestorRoutes.projectPlans, 'plans', ProjectContentPage.plans),
    ])
      feature<InvestorProjectDetailStore>(
        name,
        '/investor/projects/:id/$suffix',
        (_, state, store) => ProjectContentScreen(
          store: store,
          id: state.pathParameters['id']!,
          page: page,
          updateId: state.pathParameters['updateId'],
        ),
        initialize: (store, state) => store.load(
          state.pathParameters['id']!,
          includeRelated: page == ProjectContentPage.developer,
        ),
      ),
    feature<ExploreStore>(
      InvestorRoutes.calculatorProjects,
      '/investor/calculator',
      (_, _, store) => CalculatorProjectScreen(store: store),
      initialize: (store, _) => store.load(),
    ),
    for (final calculator in [false, true])
      feature<InvestmentStore>(
        calculator ? InvestorRoutes.calculator : InvestorRoutes.invest,
        calculator
            ? '/investor/projects/:id/calculator'
            : '/investor/projects/:id/invest',
        (_, state, store) => InvestmentScreen(
          store: store,
          id: state.pathParameters['id']!,
          calculator: calculator,
        ),
        initialize: (store, state) => store.load(
          state.pathParameters['id']!,
          initialAmountCents: state.uri.queryParameters['amountCents'],
        ),
      ),
    for (final kind in InvestorTransferKind.values)
      feature<TransferStore>(
        kind == InvestorTransferKind.topUp
            ? InvestorRoutes.addMoney
            : InvestorRoutes.withdraw,
        kind == InvestorTransferKind.topUp
            ? '/investor/wallet/add-money'
            : '/investor/wallet/withdraw',
        (_, state, store) => TransferScreen(
          store: store,
          returnProjectId: state.uri.queryParameters['returnProjectId'],
          returnAmountCents: state.uri.queryParameters['returnAmountCents'],
        ),
        initialize: (store, _) => store.load(kind),
      ),
    for (final details in [false, true])
      feature<TransactionsStore>(
        details ? InvestorRoutes.transaction : InvestorRoutes.transactions,
        details ? '/investor/transactions/:id' : '/investor/transactions',
        (_, state, store) =>
            TransactionsScreen(store: store, id: state.pathParameters['id']),
        initialize: (store, _) => store.load(),
      ),
    feature<InvestorProjectDetailStore>(
      InvestorRoutes.investment,
      '/investor/investments/:id',
      (_, state, store) => InvestorProjectScreen(
        store: store,
        id: state.pathParameters['id']!,
        investment: true,
      ),
      initialize: (store, state) =>
          store.loadInvestment(state.pathParameters['id']!),
    ),
    feature<InvestorProjectDetailStore>(
      InvestorRoutes.investmentTimeline,
      '/investor/investments/:id/timeline',
      (_, state, store) => InvestmentTimelineScreen(
        store: store,
        id: state.pathParameters['id']!,
      ),
      initialize: (store, state) =>
          store.loadInvestment(state.pathParameters['id']!),
    ),
    feature<PortfolioStore>(
      InvestorRoutes.analytics,
      '/investor/portfolio/analytics',
      (_, _, store) => PortfolioScreen(store: store, analytics: true),
      initialize: (store, _) => store.load(),
    ),
    feature<PortfolioStore>(
      InvestorRoutes.portfolioList,
      '/investor/portfolio/list/:status',
      (_, state, store) {
        final filter = InvestorInvestmentStatus.values
            .where((value) => value.name == state.pathParameters['status'])
            .firstOrNull;
        return filter == null
            ? const InvestorPage(
                title: 'Portfolio',
                child: Center(
                  child: Text('This portfolio view could not be found.'),
                ),
              )
            : PortfolioScreen(store: store, listFilter: filter);
      },
      initialize: (store, _) => store.load(),
    ),
    for (final details in [false, true])
      feature<InvestorNotificationsStore>(
        details ? InvestorRoutes.notification : InvestorRoutes.notifications,
        details ? '/investor/notifications/:id' : '/investor/notifications',
        (_, state, store) => InvestorNotificationsScreen(
          store: store,
          entity: entity,
          id: state.pathParameters['id'],
        ),
        initialize: (store, _) => store.load(),
      ),
    _route(
      InvestorRoutes.kycMember,
      '/investor/kyc/:entity/member/:role/:section',
      (context, state) {
        final entity = investorEntity(state.pathParameters['entity']);
        final role = entity == null
            ? null
            : KycMemberPlan.role(entity, state.pathParameters['role']);
        final section = KycMemberSection.tryParse(
          state.pathParameters['section'],
        );
        final id = state.uri.queryParameters['id'];
        final returnStep =
            state.uri.queryParameters['return'] ?? role?.parentStep;
        if (entity == null ||
            role == null ||
            section == null ||
            id != null && id.isEmpty ||
            returnStep == null ||
            !KycPlans.steps(entity).any(
              (step) => step.id == returnStep && step.permitsMemberRole(role),
            ) ||
            section == KycMemberSection.allocation &&
                (id == null ||
                    ![
                      KycMemberRole.beneficiary,
                      KycMemberRole.shareholder,
                    ].contains(role)) ||
            [
                  KycMemberSection.invite,
                  KycMemberSection.preview,
                ].contains(section) &&
                role == KycMemberRole.beneficiary) {
          return InvestorPage(
            title: 'Member details',
            child: ErrorView(
              message: 'This member page could not be found.',
              onRetry: () => context.goNamed(InvestorRoutes.profile),
            ),
          );
        }
        return _scope<KycMemberStore>(
          state: state,
          create: () => get<KycMemberStore>(param1: entity),
          initialize: (store) => store.load(role, id: id),
          builder: (_, store) => KycMemberScreen(
            store: store,
            role: role,
            section: section,
            id: id,
            returnStep: returnStep,
          ),
        );
      },
    ),
    _route(InvestorRoutes.kycTax, '/investor/kyc/individual/tax/:section', (
      context,
      state,
    ) {
      final section = KycTaxSection.tryParse(state.pathParameters['section']);
      final residencyId = state.uri.queryParameters['residency'];
      if (section == null ||
          residencyId != null &&
              (residencyId.isEmpty || section != KycTaxSection.residency)) {
        return InvestorPage(
          title: 'Tax & PEP Declaration',
          child: ErrorView(
            message: 'This tax declaration section could not be found.',
            onRetry: () => context.goNamed(
              InvestorRoutes.kyc,
              pathParameters: {'entity': 'individual', 'step': 'tax'},
            ),
          ),
        );
      }
      return _scope<KycStore>(
        state: state,
        create: () => get<KycStore>(param1: EntityType.individual),
        initialize: (store) async {
          await store.load(requestedStep: 'tax');
          if (section == KycTaxSection.residency) {
            store.beginTaxResidency(residencyId);
          }
        },
        builder: (_, store) => KycTaxScreen(
          store: store,
          section: section,
          residencyId: residencyId,
        ),
      );
    }),
    _route(
      InvestorRoutes.kycIntro,
      '/investor/verification',
      (context, state) => const KycIntroductionScreen(),
    ),
    _route(
      InvestorRoutes.kycEntity,
      '/investor/verification/entity',
      (context, state) =>
          KycEntityScreen(accountContext: get<InvestorAccountContext>()),
    ),
    _route(
      InvestorRoutes.kycDocuments,
      '/investor/verification/documents',
      (context, state) => const KycRequiredDocumentsScreen(),
    ),
    _route(InvestorRoutes.kyc, '/investor/kyc/:entity/:step', (context, state) {
      final entity = investorEntity(state.pathParameters['entity']);
      if (entity == null) {
        return InvestorPage(
          title: 'KYC Verification',
          child: ErrorView(
            message: 'This investor type could not be found.',
            onRetry: () => context.goNamed(InvestorRoutes.profile),
          ),
        );
      }
      return _scope<KycStore>(
        state: state,
        create: () => get<KycStore>(param1: entity),
        initialize: (store) =>
            store.load(requestedStep: state.pathParameters['step']),
        builder: (_, store) => KycScreen(store: store),
      );
    }),
    for (final item in [
      (
        InvestorRoutes.paymentMethods,
        '/investor/profile/payment-methods',
        null,
        null,
      ),
      (
        InvestorRoutes.addCard,
        '/investor/profile/payment-methods/card',
        PaymentMethodKind.card,
        null,
      ),
      (
        InvestorRoutes.manageCards,
        '/investor/profile/payment-methods/cards',
        null,
        PaymentMethodKind.card,
      ),
      (
        InvestorRoutes.addBank,
        '/investor/profile/payment-methods/bank',
        PaymentMethodKind.bankAccount,
        null,
      ),
      (
        'investor-bank-details',
        '/investor/profile/bank-details',
        null,
        PaymentMethodKind.bankAccount,
      ),
    ])
      feature<PaymentMethodsStore>(item.$1, item.$2, (context, state, store) {
        final kindName = state.uri.queryParameters['kind'];
        final selection = state.uri.queryParameters['select'];
        final kind = switch (kindName) {
          'card' => PaymentMethodKind.card,
          'bankAccount' => PaymentMethodKind.bankAccount,
          _ => null,
        };
        final fixedKind = item.$3 ?? item.$4;
        final invalid =
            (kindName != null && kind == null) ||
            (selection != null &&
                selection != 'true' &&
                selection != 'false') ||
            (kind != null && fixedKind != null && kind != fixedKind) ||
            ['kind', 'select'].any(
              (key) => (state.uri.queryParametersAll[key]?.length ?? 0) > 1,
            );
        if (invalid) {
          return InvestorPage(
            title: 'Payment Methods',
            child: ErrorView(
              message: 'This payment-method selection could not be found.',
              onRetry: () => context.goNamed(InvestorRoutes.paymentMethods),
            ),
          );
        }
        return PaymentMethodsScreen(
          store: store,
          form: item.$3,
          manage: item.$1 == InvestorRoutes.manageCards,
          filter: item.$4 ?? kind,
          select: selection == 'true',
        );
      }, initialize: (store, _) => store.load()),
    for (final item in [
      (Routes.editProfile, '/investor/profile/edit', ProfilePage.edit),
      (
        Routes.notificationPreferences,
        '/investor/profile/notifications',
        ProfilePage.preferences,
      ),
      (Routes.language, '/investor/profile/language', ProfilePage.language),
    ])
      _route(
        'investor-${item.$1}',
        item.$2,
        (_, state) => _scope<ProfileStore>(
          state: state,
          create: () => get<ProfileStore>(),
          screenDisposes: true,
          builder: (_, store) => ProfileScreen(
            store: store,
            page: item.$3,
            routePrefix: 'investor-',
          ),
        ),
      ),
    feature<InvestorProfileStore>(
      InvestorRoutes.riskProfile,
      '/investor/profile/risk-profile',
      (_, _, store) => RiskProfileScreen(store: store),
      initialize: (store, _) => store.load(),
    ),
    for (final item in [
      (Routes.security, '/investor/profile/security', SecurityPage.menu),
      (
        Routes.password,
        '/investor/profile/security/password',
        SecurityPage.password,
      ),
      (Routes.pin, '/investor/profile/security/pin', SecurityPage.pin),
      (
        Routes.biometrics,
        '/investor/profile/security/biometrics',
        SecurityPage.biometrics,
      ),
      (
        Routes.devices,
        '/investor/profile/security/devices',
        SecurityPage.devices,
      ),
      (
        Routes.twoFactor,
        '/investor/profile/security/2fa',
        SecurityPage.twoFactor,
      ),
      (
        Routes.twoFactorSms,
        '/investor/profile/security/2fa/sms',
        SecurityPage.sms,
      ),
      (
        Routes.twoFactorApp,
        '/investor/profile/security/2fa/app',
        SecurityPage.authenticator,
      ),
    ])
      _route(
        'investor-${item.$1}',
        item.$2,
        (_, state) => _scope<SecurityStore>(
          state: state,
          create: () => get<SecurityStore>(),
          screenDisposes: true,
          builder: (_, store) => SecurityScreen(
            store: store,
            page: item.$3,
            routePrefix: 'investor-',
            onLogout: onLogout,
          ),
        ),
      ),
    for (final item in [
      (Routes.help, '/investor/profile/help', InformationPage.help),
      (Routes.about, '/investor/profile/about', InformationPage.about),
    ])
      _route(
        'investor-${item.$1}',
        item.$2,
        (_, state) => _scope<InformationStore>(
          state: state,
          create: () => get<InformationStore>(),
          builder: (_, store) => InformationScreen(
            page: item.$3,
            store: store,
            routePrefix: 'investor-',
          ),
        ),
      ),
    _route(
      'investor-${Routes.chat}',
      '/investor/support/chat',
      (_, state) => _scope<ChatStore>(
        state: state,
        create: () => get<ChatStore>(),
        screenDisposes: true,
        builder: (_, store) => ChatScreen(store: store),
      ),
    ),
  ];
}
