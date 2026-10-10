import 'package:developify_mobile/core/services/transaction_authorization.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'package:developify_mobile/features/investor/data/api_investor_account_repository.dart';
import 'package:developify_mobile/features/investor/data/api_investor_catalog_repository.dart';
import 'package:developify_mobile/features/investor/data/api_kyc_repository.dart';
import 'package:developify_mobile/features/investor/data/api_transaction_authorization.dart';
import 'package:developify_mobile/features/investor/data/mock_investor_account_repository.dart';
import 'package:developify_mobile/features/investor/data/mock_investor_catalog_repository.dart';
import 'package:developify_mobile/features/investor/data/mock_kyc_repository.dart';
import 'package:developify_mobile/features/investor/domain/investor_repository.dart';
import 'package:developify_mobile/features/investor/domain/investor_account_context.dart';
import 'package:developify_mobile/features/investor/domain/investor_drafts.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_repository.dart';
import 'package:developify_mobile/features/investor/presentation/stores/payment_methods_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/transactions_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investor_profile_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/portfolio_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investor_notifications_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/transfer_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investor_signup_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investment_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/project_detail_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/explore_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/kyc_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/kyc_member_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/wallet_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investor_home_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/core/network/api_client.dart';
import 'package:developify_mobile/core/services/mock_behavior.dart';
import 'package:developify_mobile/core/services/push_notification_service.dart';
import 'package:developify_mobile/core/services/session_service.dart';
import 'package:developify_mobile/core/services/telemetry.dart';
import 'package:developify_mobile/core/storage/token_storage.dart';
import 'package:developify_mobile/features/authentication/data/api_auth_repository.dart';
import 'package:developify_mobile/features/authentication/data/mock_auth_repository.dart';
import 'package:developify_mobile/features/authentication/domain/auth_repository.dart';
import 'package:developify_mobile/features/authentication/presentation/stores/auth_store.dart';
import 'package:developify_mobile/features/authentication/presentation/stores/signup_store.dart';
import 'package:developify_mobile/features/authentication/presentation/stores/recovery_store.dart';
import 'package:developify_mobile/features/landowner/data/api_landowner_repository.dart';
import 'package:developify_mobile/features/landowner/data/mock_landowner_repository.dart';
import 'package:developify_mobile/features/landowner/domain/landowner_repository.dart';
import 'package:developify_mobile/features/landowner/presentation/stores/earnings_store.dart';
import 'package:developify_mobile/features/landowner/presentation/stores/home_store.dart';
import 'package:developify_mobile/features/landowner/presentation/stores/properties_store.dart';
import 'package:developify_mobile/features/landowner/presentation/stores/property_detail_store.dart';
import 'package:developify_mobile/features/landowner/presentation/stores/submission_store.dart';
import 'package:developify_mobile/features/notifications/data/api_notification_repository.dart';
import 'package:developify_mobile/features/notifications/data/mock_notification_repository.dart';
import 'package:developify_mobile/features/notifications/domain/notification_repository.dart';
import 'package:developify_mobile/features/notifications/presentation/chat_store.dart';
import 'package:developify_mobile/features/notifications/presentation/notifications_store.dart';
import 'package:developify_mobile/features/onboarding/presentation/onboarding_store.dart';
import 'package:developify_mobile/features/profile/data/api_profile_repository.dart';
import 'package:developify_mobile/features/profile/data/mock_profile_repository.dart';
import 'package:developify_mobile/features/profile/domain/profile_repository.dart';
import 'package:developify_mobile/features/profile/presentation/stores/information_store.dart';
import 'package:developify_mobile/features/profile/presentation/stores/payout_store.dart';
import 'package:developify_mobile/features/profile/presentation/stores/profile_store.dart';
import 'package:developify_mobile/features/profile/presentation/stores/security_store.dart';
import 'package:developify_mobile/features/shared/presentation/experience_store.dart';

final class AppDependencies {
  AppDependencies._(this.container);
  final GetIt container;
  SessionService get session => container<SessionService>();
  PushNotificationService get push => container<PushNotificationService>();
  TelemetryServices get telemetry => container<TelemetryServices>();
  static Future<AppDependencies> create({
    AppEnvironment environment = const AppEnvironment(),
    TokenStorage? tokenStorage,
    TelemetryServices? telemetry,
    SessionService? session,
    DateTime Function()? mockClock,
  }) async {
    final get = GetIt.asNewInstance();
    final sessionService = session ?? SessionService();
    final tokens =
        tokenStorage ??
        (environment.mockMode
            ? MemoryTokenStorage()
            : SecureTokenStorage(const FlutterSecureStorage()));
    final services =
        telemetry ?? await TelemetryServices.initialize(environment);
    final push = OneSignalPushService(environment.oneSignalAppId);
    await push.initialize();
    final useApi = !environment.mockMode && environment.apiUri != null;
    get.registerSingleton<AppEnvironment>(environment);
    get.registerSingleton<SessionService>(
      sessionService,
      dispose: (value) => value.dispose(),
    );
    get.registerSingleton<TokenStorage>(tokens);
    get.registerSingleton<AuthTokenProvider>(tokens);
    get.registerSingleton<TelemetryServices>(services);
    get.registerSingleton<AnalyticsService>(services.analytics);
    get.registerSingleton<CrashReporter>(services.crashes);
    get.registerSingleton<FeatureConfigService>(services.config);
    get.registerSingleton<PerformanceService>(services.performance);
    get.registerSingleton<PushNotificationService>(
      push,
      dispose: (value) => value.dispose(),
    );
    final apiClient = ApiClient(environment: environment, tokens: tokens);
    get.registerSingleton<ApiClient>(
      apiClient,
      dispose: (value) => value.dispose(),
    );
    get.registerSingleton<InvestorAccountContext>(
      InvestorAccountContext(sessionService),
      dispose: (value) => value.dispose(),
    );
    get.registerSingleton<InvestorDrafts>(
      InvestorDrafts(get<InvestorAccountContext>()),
      dispose: (value) => value.dispose(),
    );

    if (useApi) {
      final authRepo = ApiAuthRepository(apiClient, tokens);
      apiClient.setRefreshHandler(authRepo.refreshSession);
      get.registerSingleton<AuthRepository>(authRepo);
      get.registerSingleton<TransactionAuthorization>(
        ApiTransactionAuthorization(sessionService, apiClient),
        dispose: (value) => value.dispose(),
      );
      get.registerSingleton<InvestorCatalogRepository>(
        ApiInvestorCatalogRepository(apiClient, get<InvestorAccountContext>()),
        dispose: (value) => value.dispose(),
      );
      get.registerSingleton<InvestorAccountRepository>(
        ApiInvestorAccountRepository(apiClient, get<InvestorAccountContext>()),
        dispose: (value) => value.dispose(),
      );
      get.registerSingleton<KycRepository>(
        ApiKycRepository(apiClient),
        dispose: (value) => value.dispose(),
      );
      get.registerSingleton<LandownerRepository>(
        ApiLandownerRepository(apiClient),
        dispose: (value) => value.dispose(),
      );
      get.registerSingleton<NotificationRepository>(
        ApiNotificationRepository(apiClient),
      );
      get.registerSingleton<ProfileRepository>(
        ApiProfileRepository(
          apiClient,
          sessionService,
          authorization: get<TransactionAuthorization>(),
        ),
        dispose: (value) => value.dispose(),
      );
    } else {
      get.registerSingleton<TransactionAuthorization>(
        MockTransactionAuthorization(sessionService),
        dispose: (value) => value.dispose(),
      );
      get.registerSingleton<InvestorCatalogRepository>(
        MockInvestorCatalogRepository(
          MockBehavior.fromEnvironment(environment),
          get<InvestorAccountContext>(),
          scenario: environment.mockScenario,
        ),
        dispose: (value) => value.dispose(),
      );
      get.registerSingleton<InvestorAccountRepository>(
        MockInvestorAccountRepository(
          MockBehavior.fromEnvironment(environment),
          get<InvestorAccountContext>(),
          scenario: environment.mockScenario,
          authorization: get<TransactionAuthorization>(),
          catalog: get<InvestorCatalogRepository>(),
        ),
        dispose: (value) => value.dispose(),
      );
      get.registerSingleton<KycRepository>(
        MockKycRepository(
          MockBehavior.fromEnvironment(environment),
          get<InvestorAccountContext>(),
          get<InvestorAccountRepository>(),
          scenario: environment.mockScenario,
          now: mockClock,
        ),
        dispose: (value) => value.dispose(),
      );
      get.registerSingleton<AuthRepository>(
        MockAuthRepository(MockBehavior.fromEnvironment(environment)),
      );
      get.registerSingleton<LandownerRepository>(
        MockLandownerRepository(
          MockBehavior.fromEnvironment(environment),
          session: sessionService,
        ),
        dispose: (value) => value.dispose(),
      );
      get.registerSingleton<NotificationRepository>(
        MockNotificationRepository(MockBehavior.fromEnvironment(environment)),
      );
      get.registerSingleton<ProfileRepository>(
        MockProfileRepository(
          MockBehavior.fromEnvironment(environment),
          sessionService,
          authorization: get<TransactionAuthorization>(),
        ),
        dispose: (value) => value.dispose(),
      );
    }
    get.registerFactory<OnboardingStore>(() => OnboardingStore(sessionService));
    get.registerFactoryParam<AuthStore, Experience?, void>(
      (experience, _) => AuthStore(
        get<AuthRepository>(),
        sessionService,
        experience: experience ?? Experience.landowner,
      ),
    );
    get.registerFactory<SignupStore>(
      () => SignupStore(get<AuthRepository>(), sessionService),
    );
    get.registerFactory<RecoveryStore>(
      () => RecoveryStore(get<AuthRepository>()),
    );
    get.registerFactory<HomeStore>(() => HomeStore(get<LandownerRepository>()));
    get.registerFactory<PropertiesStore>(
      () => PropertiesStore(get<LandownerRepository>()),
    );
    get.registerFactory<PropertyDetailStore>(
      () => PropertyDetailStore(get<LandownerRepository>()),
    );
    get.registerFactory<EarningsStore>(
      () => EarningsStore(get<LandownerRepository>()),
    );
    get.registerFactoryParam<SubmissionStore, String, void>(
      (id, _) => SubmissionStore(get<LandownerRepository>(), id),
    );
    get.registerFactory<NotificationsStore>(
      () => NotificationsStore(get<NotificationRepository>()),
    );
    get.registerFactory<ChatStore>(
      () => ChatStore(get<NotificationRepository>()),
    );
    get.registerFactory<ProfileStore>(
      () => ProfileStore(get<ProfileRepository>()),
    );
    get.registerFactory<PayoutStore>(
      () => PayoutStore(get<ProfileRepository>()),
    );
    get.registerFactory<SecurityStore>(
      () => SecurityStore(get<ProfileRepository>()),
    );
    get.registerFactory<InformationStore>(InformationStore.new);
    get.registerFactory<ExperienceStore>(ExperienceStore.new);
    get.registerFactory<InvestorHomeStore>(
      () => InvestorHomeStore(
        get<InvestorAccountRepository>(),
        get<InvestorCatalogRepository>(),
      ),
    );
    get.registerFactory<ExploreStore>(
      () => ExploreStore(get<InvestorCatalogRepository>()),
    );
    get.registerFactory<InvestorProjectDetailStore>(
      () => InvestorProjectDetailStore(
        get<InvestorCatalogRepository>(),
        get<InvestorAccountRepository>(),
      ),
    );
    get.registerFactory<InvestmentStore>(
      () => InvestmentStore(
        get<InvestorCatalogRepository>(),
        get<InvestorAccountRepository>(),
        get<InvestorDrafts>(),
      ),
    );
    get.registerFactory<TransferStore>(
      () => TransferStore(
        get<InvestorAccountRepository>(),
        get<InvestorDrafts>(),
      ),
    );
    get.registerFactory<WalletStore>(
      () => WalletStore(get<InvestorAccountRepository>()),
    );
    get.registerFactory<PaymentMethodsStore>(
      () => PaymentMethodsStore(get<InvestorAccountRepository>()),
    );
    get.registerFactory<TransactionsStore>(
      () => TransactionsStore(get<InvestorAccountRepository>()),
    );
    get.registerFactory<PortfolioStore>(
      () => PortfolioStore(get<InvestorAccountRepository>()),
    );
    get.registerFactory<InvestorNotificationsStore>(
      () => InvestorNotificationsStore(get<InvestorAccountRepository>()),
    );
    get.registerFactory<InvestorProfileStore>(
      () => InvestorProfileStore(
        get<ProfileRepository>(),
        get<InvestorAccountRepository>(),
        get<KycRepository>(),
        get<InvestorAccountContext>(),
      ),
    );
    get.registerFactoryParam<KycStore, EntityType, void>(
      (entity, _) => KycStore(get<KycRepository>(), entity),
    );
    get.registerFactoryParam<KycMemberStore, EntityType, void>(
      (entity, _) => KycMemberStore(get<KycRepository>(), entity),
    );
    get.registerFactoryParam<InvestorSignupStore, EntityType, bool>(
      (entity, nonResident) => InvestorSignupStore(
        get<AuthRepository>(),
        sessionService,
        get<TransactionAuthorization>(),
        entity: entity,
      )..nonResident = nonResident,
    );
    return AppDependencies._(get);
  }

  Future<void> logout() async {
    session.signOut();
    container<LandownerRepository>().clearSession();
    container<NotificationRepository>().clearSession();
    container<ProfileRepository>().clearSession();
    container<AuthRepository>().clearSession();
    try {
      await container<TokenStorage>().clearToken();
      await container<TokenStorage>().clearRefreshToken();
    } on Object catch (error, stack) {
      await telemetry.crashes.record(error, stack);
    }
    await push.removeExternalUserId();
  }

  Future<void> dispose() => container.reset();
}
