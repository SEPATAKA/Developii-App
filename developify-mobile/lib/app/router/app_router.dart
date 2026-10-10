import 'package:developify_mobile/app/router/investor_routes.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/router/route_names.dart';
import 'package:developify_mobile/app/router/app_transition_page.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/authentication/presentation/auth_screen.dart';
import 'package:developify_mobile/features/authentication/presentation/signup_screen.dart';
import 'package:developify_mobile/features/authentication/presentation/stores/signup_store.dart';
import 'package:developify_mobile/features/authentication/presentation/recovery_screen.dart';
import 'package:developify_mobile/features/authentication/presentation/stores/auth_store.dart';
import 'package:developify_mobile/features/authentication/presentation/stores/recovery_store.dart';
import 'package:developify_mobile/features/landowner/domain/landowner_repository.dart';
import 'package:developify_mobile/features/landowner/presentation/home_screen.dart';
import 'package:developify_mobile/features/landowner/presentation/earnings_screen.dart';
import 'package:developify_mobile/features/landowner/presentation/properties_screen.dart';
import 'package:developify_mobile/features/landowner/presentation/property_detail_screen.dart';
import 'package:developify_mobile/features/landowner/presentation/submission_screen.dart';
import 'package:developify_mobile/features/landowner/presentation/stores/home_store.dart';
import 'package:developify_mobile/features/landowner/presentation/stores/properties_store.dart';
import 'package:developify_mobile/features/landowner/presentation/stores/property_detail_store.dart';
import 'package:developify_mobile/features/landowner/presentation/stores/earnings_store.dart';
import 'package:developify_mobile/features/landowner/presentation/stores/submission_store.dart';
import 'package:developify_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:developify_mobile/features/notifications/presentation/notifications_store.dart';
import 'package:developify_mobile/features/notifications/presentation/chat_screen.dart';
import 'package:developify_mobile/features/notifications/presentation/chat_store.dart';
import 'package:developify_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:developify_mobile/features/onboarding/presentation/onboarding_store.dart';
import 'package:developify_mobile/features/profile/presentation/profile_screen.dart';
import 'package:developify_mobile/features/profile/presentation/payout_screen.dart';
import 'package:developify_mobile/features/profile/presentation/security_screen.dart';
import 'package:developify_mobile/features/profile/presentation/information_screen.dart';
import 'package:developify_mobile/features/profile/presentation/stores/profile_store.dart';
import 'package:developify_mobile/features/profile/presentation/stores/payout_store.dart';
import 'package:developify_mobile/features/profile/presentation/stores/security_store.dart';
import 'package:developify_mobile/features/profile/presentation/stores/information_store.dart';
import 'package:developify_mobile/features/shared/presentation/experience_screen.dart';
import 'package:developify_mobile/features/shared/presentation/experience_store.dart';
import 'package:developify_mobile/app/router/landowner_shell.dart';

GoRouter createAppRouter(
  AppDependencies dependencies, {
  String initialLocation = '/',
}) {
  final get = dependencies.container;
  final session = dependencies.session;
  if (initialLocation == '/') {
    session.selectExperience(Experience.investor, notify: false);
  }
  String? pendingLocation;
  bool loggingOut = false;
  final experienceShellKey = GlobalKey<StatefulNavigationShellState>();
  const publicPaths = {
    '/',
    '/onboarding',
    '/welcome',
    '/sign-in',
    '/create-account',
    '/welcome-back',
    '/forgot-password',
    '/onboarding-terms',
    '/investor/onboarding',
    '/investor/splash',
    '/investor/welcome',
    '/investor/sign-in',
    '/investor/create-account',
    '/investor/welcome-back',
    '/investor/forgot-password',
    '/investor/onboarding-terms',
    '/investor/terms',
    '/investor/privacy',
  };
  const primaryTabs = {
    Routes.home,
    Routes.properties,
    Routes.earnings,
    Routes.profile,
  };
  Page<void> page(
    BuildContext context,
    String name,
    LocalKey key,
    Widget child,
  ) => primaryTabs.contains(name)
      ? NoTransitionPage<void>(key: key, name: name, child: child)
      : AppTransitionPage(
          key: key,
          name: name,
          child: child,
          reducedMotion: AppDurations.reducedMotion(context),
          upward: name == Routes.welcome,
        );
  GoRoute route<T extends Object>(
    String name,
    String path,
    Widget Function(BuildContext, GoRouterState, T) builder,
  ) => GoRoute(
    name: name,
    path: path,
    pageBuilder: (context, state) => page(
      context,
      name,
      ValueKey('$name:${state.uri.path}'),
      _RouteStore<T>(
        key: ValueKey('$name:${state.uri.path}'),
        create: () => get<T>(),
        builder: (context, store) => builder(context, state, store),
      ),
    ),
  );
  void logout() {
    loggingOut = true;
    pendingLocation = null;
    unawaited(dependencies.logout());
  }

  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: session,
    redirect: (context, state) {
      final path = state.uri.path;
      final investor = path.startsWith('/investor/');
      if (!session.isAuthenticated && !publicPaths.contains(path)) {
        if (!loggingOut) pendingLocation = state.uri.toString();
        loggingOut = false;
        final prefix = investor ? '/investor' : '';
        return !session.onboardingComplete
            ? '$prefix/onboarding'
            : session.returningUser != null
            ? '$prefix/welcome-back'
            : '$prefix/sign-in';
      }
      final legal =
          path == '/investor/terms' ||
          path == '/investor/privacy' ||
          path == '/investor/onboarding-terms';
      if (session.isAuthenticated && publicPaths.contains(path) && !legal) {
        final destination =
            pendingLocation ??
            (path == '/investor/create-account'
                ? '/investor/kyc/${session.user!.entity.name}/overview'
                : session.experience == Experience.investor
                ? '/investor/home'
                : '/home');
        pendingLocation = null;
        return destination;
      }
      if (session.isAuthenticated && path != '/experience' && !legal) {
        session.selectExperience(
          investor ? Experience.investor : Experience.landowner,
          notify: false,
        );
      }
      return null;
    },
    errorBuilder: (context, _) => Scaffold(
      body: SafeArea(
        child: ErrorView(
          message: 'This page could not be found.',
          onRetry: () => context.goNamed(
            session.isAuthenticated ? Routes.home : Routes.welcome,
          ),
        ),
      ),
    ),
    routes: [
      ...investorPublicRoutes(dependencies),
      GoRoute(
        name: Routes.splash,
        path: '/',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: SplashScreen(
            onReady: () => context.goNamed(
              session.experience == Experience.investor
                  ? session.isAuthenticated
                        ? InvestorRoutes.home
                        : session.onboardingComplete
                        ? InvestorRoutes.signIn
                        : InvestorRoutes.onboarding
                  : session.isAuthenticated
                  ? Routes.home
                  : session.onboardingComplete
                  ? Routes.welcome
                  : Routes.onboarding,
            ),
          ),
        ),
      ),
      route<OnboardingStore>(
        Routes.onboarding,
        '/onboarding',
        (_, _, store) => OnboardingScreen(store: store),
      ),
      GoRoute(
        name: Routes.welcome,
        path: '/welcome',
        pageBuilder: (context, state) =>
            page(context, Routes.welcome, state.pageKey, const WelcomeScreen()),
      ),
      route<InformationStore>(
        Routes.legal,
        '/onboarding-terms',
        (context, state, store) => InformationScreen(
          page: InformationPage.onboardingTerms,
          store: store,
          onConsentAccepted: state.uri.queryParameters['return'] == 'signup'
              ? () => context.pop(true)
              : null,
        ),
      ),
      route<SignupStore>(
        Routes.signUp,
        '/create-account',
        (_, _, store) => SignupScreen(store: store),
      ),
      route<AuthStore>(
        Routes.signIn,
        '/sign-in',
        (_, _, store) => AuthScreen(store: store),
      ),
      route<AuthStore>(
        Routes.welcomeBack,
        '/welcome-back',
        (_, _, store) => AuthScreen(store: store, returning: true),
      ),
      route<RecoveryStore>(
        Routes.recovery,
        '/forgot-password',
        (_, _, store) => RecoveryScreen(store: store),
      ),
      StatefulShellRoute.indexedStack(
        key: experienceShellKey,
        pageBuilder: (_, state, shell) =>
            NoTransitionPage<void>(key: state.pageKey, child: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              StatefulShellRoute.indexedStack(
                pageBuilder: (context, state, shell) => NoTransitionPage<void>(
                  key: state.pageKey,
                  child: LandownerShell(shell: shell),
                ),
                branches: [
                  StatefulShellBranch(
                    routes: [
                      route<HomeStore>(
                        Routes.home,
                        '/home',
                        (_, _, store) => HomeScreen(
                          store: store,
                          displayName: session.user?.name ?? 'Landowner',
                        ),
                      ),
                    ],
                  ),
                  StatefulShellBranch(
                    routes: [
                      route<PropertiesStore>(
                        Routes.properties,
                        '/properties',
                        (_, _, store) => PropertiesScreen(store: store),
                      ),
                    ],
                  ),
                  StatefulShellBranch(
                    routes: [
                      route<EarningsStore>(
                        Routes.earnings,
                        '/earnings',
                        (_, _, store) => EarningsScreen(store: store),
                      ),
                    ],
                  ),
                  StatefulShellBranch(
                    routes: [
                      route<ProfileStore>(
                        Routes.profile,
                        '/profile',
                        (_, _, store) => ProfileScreen(
                          store: store,
                          onLogout: logout,
                          landowner: get<LandownerRepository>(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              route<PropertyDetailStore>(
                Routes.property,
                '/properties/:id',
                (_, state, store) => PropertyDetailScreen(
                  store: store,
                  id: state.pathParameters['id']!,
                ),
              ),
              route<NotificationsStore>(
                Routes.notifications,
                '/notifications',
                (_, _, store) => NotificationsScreen(store: store),
              ),
              route<NotificationsStore>(
                Routes.notification,
                '/notifications/:id',
                (_, state, store) => NotificationsScreen(
                  store: store,
                  notificationId: state.pathParameters['id']!,
                ),
              ),
              route<ChatStore>(
                Routes.chat,
                '/support/chat',
                (_, _, store) => ChatScreen(store: store),
              ),
              GoRoute(
                name: Routes.submit,
                path: '/submit/:step',
                redirect: (_, state) {
                  final step = int.tryParse(state.pathParameters['step'] ?? '');
                  return step == null || step < 1 || step > 9
                      ? '/submit/1'
                      : null;
                },
                pageBuilder: (context, state) {
                  final step = int.parse(state.pathParameters['step']!);
                  final draft =
                      state.uri.queryParameters['draft'] ?? 'new-draft';
                  return page(
                    context,
                    Routes.submit,
                    ValueKey(
                      'submit-$draft-$step-${state.uri.queryParameters['review']}',
                    ),
                    _RouteStore<SubmissionStore>(
                      key: ValueKey('submit-$draft-$step'),
                      create: () => get<SubmissionStore>(param1: draft),
                      builder: (_, store) => SubmissionScreen(
                        store: store,
                        step: step,
                        review: state.uri.queryParameters['review'] == 'true',
                      ),
                    ),
                  );
                },
              ),
              for (final item in [
                (Routes.editProfile, '/profile/edit', ProfilePage.edit),
                (Routes.payout, '/profile/payout', ProfilePage.payout),
                (
                  Routes.notificationPreferences,
                  '/profile/notifications',
                  ProfilePage.preferences,
                ),
                (Routes.language, '/profile/language', ProfilePage.language),
              ])
                route<ProfileStore>(
                  item.$1,
                  item.$2,
                  (_, _, store) => ProfileScreen(store: store, page: item.$3),
                ),
              route<PayoutStore>(
                Routes.newPayout,
                '/profile/payout/new',
                (_, _, store) => PayoutScreen(store: store),
              ),
              for (final item in [
                (Routes.security, '/profile/security', SecurityPage.menu),
                (
                  Routes.password,
                  '/profile/security/password',
                  SecurityPage.password,
                ),
                (Routes.pin, '/profile/security/pin', SecurityPage.pin),
                (
                  Routes.biometrics,
                  '/profile/security/biometrics',
                  SecurityPage.biometrics,
                ),
                (
                  Routes.devices,
                  '/profile/security/devices',
                  SecurityPage.devices,
                ),
                (
                  Routes.twoFactor,
                  '/profile/security/2fa',
                  SecurityPage.twoFactor,
                ),
                (
                  Routes.twoFactorSms,
                  '/profile/security/2fa/sms',
                  SecurityPage.sms,
                ),
                (
                  Routes.twoFactorApp,
                  '/profile/security/2fa/app',
                  SecurityPage.authenticator,
                ),
              ])
                route<SecurityStore>(
                  item.$1,
                  item.$2,
                  (_, _, store) => SecurityScreen(
                    store: store,
                    page: item.$3,
                    onLogout: logout,
                  ),
                ),
              for (final item in [
                (Routes.help, '/profile/help', InformationPage.help),
                (Routes.about, '/profile/about', InformationPage.about),
                (Routes.privacy, '/profile/privacy', InformationPage.privacy),
                (Routes.terms, '/profile/terms', InformationPage.terms),
              ])
                route<InformationStore>(
                  item.$1,
                  item.$2,
                  (_, _, store) =>
                      InformationScreen(page: item.$3, store: store),
                ),
            ],
          ),
          StatefulShellBranch(
            routes: investorAuthenticatedRoutes(dependencies, onLogout: logout),
          ),
        ],
      ),
      GoRoute(
        name: Routes.experience,
        path: '/experience',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          name: Routes.experience,
          opaque: false,
          barrierDismissible: true,
          barrierColor: AppColors.modalScrim,
          barrierLabel: 'Close switch',
          transitionDuration: AppDurations.motion(context, AppDurations.page),
          reverseTransitionDuration: AppDurations.motion(
            context,
            AppDurations.page,
          ),
          transitionsBuilder: (_, animation, _, child) => SlideTransition(
            position: Tween(begin: const Offset(0, .2), end: Offset.zero)
                .animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: _RouteStore<ExperienceStore>(
            create: () => get<ExperienceStore>(),
            builder: (_, store) => ExperienceScreen(
              store: store,
              current: session.experience,
              onSwitch: (experience) {
                if (context.canPop()) context.pop();
                session.selectExperience(experience, notify: false);
                final shell = experienceShellKey.currentState;
                if (shell == null) {
                  context.goNamed(
                    experience == Experience.investor
                        ? InvestorRoutes.home
                        : Routes.home,
                  );
                } else {
                  shell.goBranch(experience == Experience.landowner ? 0 : 1);
                }
              },
            ),
          ),
        ),
      ),
    ],
  );
}

class _RouteStore<T> extends StatefulWidget {
  const _RouteStore({super.key, required this.create, required this.builder});
  final T Function() create;
  final Widget Function(BuildContext, T) builder;
  @override
  State<_RouteStore<T>> createState() => _RouteStoreState<T>();
}

class _RouteStoreState<T> extends State<_RouteStore<T>> {
  late final T store = widget.create();
  @override
  Widget build(BuildContext context) => widget.builder(context, store);
}
