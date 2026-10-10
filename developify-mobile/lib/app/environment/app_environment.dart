enum MockScenario {
  success,
  empty,
  networkFailure,
  lowBalance,
  incompleteKyc,
  pendingVerification,
  rejectedVerification,
  noProjects,
  noTransactions,
  noNotifications,
  noPortfolio,
  withdrawalUnavailable,
  paymentMethodUnavailable,
  validationFailure,
  missingItem,
}

final class AppEnvironment {
  const AppEnvironment({
    this.apiBaseUrl = '',
    this.mockMode = true,
    this.mockDelay = const Duration(milliseconds: 350),
    this.mockScenario = MockScenario.success,
    this.oneSignalAppId = '',
    this.firebaseEnabled = false,
    this.telemetryEnabled = false,
  });

  factory AppEnvironment.fromDefines() {
    const scenario = String.fromEnvironment(
      'MOCK_SCENARIO',
      defaultValue: 'success',
    );
    return AppEnvironment(
      apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
      mockMode: const bool.fromEnvironment('MOCK_MODE', defaultValue: true),
      mockDelay: const Duration(
        milliseconds: int.fromEnvironment('MOCK_DELAY_MS', defaultValue: 350),
      ),
      mockScenario: switch (scenario) {
        'empty' => MockScenario.empty,
        'network_failure' => MockScenario.networkFailure,
        'low_balance' => MockScenario.lowBalance,
        'incomplete_kyc' => MockScenario.incompleteKyc,
        'pending_verification' => MockScenario.pendingVerification,
        'rejected_verification' => MockScenario.rejectedVerification,
        'no_projects' => MockScenario.noProjects,
        'no_transactions' => MockScenario.noTransactions,
        'no_notifications' => MockScenario.noNotifications,
        'no_portfolio' => MockScenario.noPortfolio,
        'withdrawal_unavailable' => MockScenario.withdrawalUnavailable,
        'payment_method_unavailable' => MockScenario.paymentMethodUnavailable,
        'validation_failure' => MockScenario.validationFailure,
        'missing_item' => MockScenario.missingItem,
        _ => MockScenario.success,
      },
      oneSignalAppId: const String.fromEnvironment('ONESIGNAL_APP_ID'),
      firebaseEnabled: const bool.fromEnvironment('FIREBASE_ENABLED'),
      telemetryEnabled: const bool.fromEnvironment('TELEMETRY_ENABLED'),
    );
  }

  final String apiBaseUrl;
  final bool mockMode;
  final Duration mockDelay;
  final MockScenario mockScenario;
  final String oneSignalAppId;
  final bool firebaseEnabled;
  final bool telemetryEnabled;

  Uri? get apiUri {
    final uri = Uri.tryParse(apiBaseUrl.trim());
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }
    final isLocalHttp =
        uri.scheme == 'http' &&
        (uri.host == 'localhost' ||
            uri.host == '127.0.0.1' ||
            uri.host == '10.0.2.2');
    if (uri.scheme != 'https' && !isLocalHttp) {
      return null;
    }
    return uri;
  }
}
