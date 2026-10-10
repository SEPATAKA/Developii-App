import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';

abstract interface class AnalyticsService {
  Future<void> screen(String name);
}

abstract interface class CrashReporter {
  Future<void> record(Object error, StackTrace stack, {bool fatal = false});
}

abstract interface class FeatureConfigService {
  int get reviewBusinessDays;
  Future<void> refresh();
}

abstract interface class PerformanceService {
  Future<T> trace<T>(String name, Future<T> Function() operation);
}

final class NoopAnalytics implements AnalyticsService {
  @override
  Future<void> screen(String name) async {}
}

final class NoopCrashReporter implements CrashReporter {
  @override
  Future<void> record(
    Object error,
    StackTrace stack, {
    bool fatal = false,
  }) async {}
}

final class DefaultFeatureConfig implements FeatureConfigService {
  @override
  int get reviewBusinessDays => 10;
  @override
  Future<void> refresh() async {}
}

final class NoopPerformance implements PerformanceService {
  @override
  Future<T> trace<T>(String name, Future<T> Function() operation) =>
      operation();
}

final class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this._analytics);
  final FirebaseAnalytics _analytics;
  @override
  Future<void> screen(String name) async {
    try {
      await _analytics.logScreenView(screenName: name);
    } on Object {
      return;
    }
  }
}

final class FirebaseCrashReporter implements CrashReporter {
  FirebaseCrashReporter(this._crashlytics);
  final FirebaseCrashlytics _crashlytics;
  @override
  Future<void> record(
    Object error,
    StackTrace stack, {
    bool fatal = false,
  }) async {
    try {
      await _crashlytics.recordError(
        error.runtimeType.toString(),
        stack,
        fatal: fatal,
      );
    } on Object {
      return;
    }
  }
}

final class FirebaseFeatureConfig implements FeatureConfigService {
  FirebaseFeatureConfig(this._config);
  final FirebaseRemoteConfig _config;
  @override
  int get reviewBusinessDays {
    final value = _config.getInt('review_business_days');
    return value >= 1 && value <= 30 ? value : 10;
  }

  @override
  Future<void> refresh() async {
    try {
      await _config.fetchAndActivate();
    } on Object {
      return;
    }
  }
}

Future<void> _stopTrace(Trace trace) async {
  try {
    await trace.stop();
  } on Object {
    return;
  }
}

final class FirebasePerformanceService implements PerformanceService {
  FirebasePerformanceService(this._performance);
  final FirebasePerformance _performance;
  @override
  Future<T> trace<T>(String name, Future<T> Function() operation) async {
    Trace? trace;
    try {
      trace = _performance.newTrace(name);
      await trace.start();
    } on Object {
      trace = null;
    }
    try {
      return await operation();
    } finally {
      if (trace != null) await _stopTrace(trace);
    }
  }
}

final class TelemetryServices {
  TelemetryServices({
    required this.analytics,
    required this.crashes,
    required this.config,
    required this.performance,
    this.firebaseConfigured = false,
  });
  factory TelemetryServices.disabled() => TelemetryServices(
    analytics: NoopAnalytics(),
    crashes: NoopCrashReporter(),
    config: DefaultFeatureConfig(),
    performance: NoopPerformance(),
  );
  final AnalyticsService analytics;
  final CrashReporter crashes;
  final FeatureConfigService config;
  final PerformanceService performance;
  final bool firebaseConfigured;

  static Future<TelemetryServices> initialize(
    AppEnvironment environment, {
    FirebaseOptions? options,
  }) async {
    if (!environment.firebaseEnabled) return TelemetryServices.disabled();
    try {
      final app = Firebase.apps.isEmpty
          ? await Firebase.initializeApp(options: options)
          : Firebase.app();
      final analytics = FirebaseAnalytics.instanceFor(app: app);
      final crashlytics = FirebaseCrashlytics.instance;
      final performance = FirebasePerformance.instance;
      final config = FirebaseRemoteConfig.instanceFor(app: app);
      await Future.wait([
        analytics.setAnalyticsCollectionEnabled(environment.telemetryEnabled),
        crashlytics.setCrashlyticsCollectionEnabled(
          environment.telemetryEnabled,
        ),
        performance.setPerformanceCollectionEnabled(
          environment.telemetryEnabled,
        ),
        config.setDefaults({'review_business_days': 10}),
        config.setConfigSettings(
          RemoteConfigSettings(
            fetchTimeout: const Duration(seconds: 10),
            minimumFetchInterval: const Duration(hours: 12),
          ),
        ),
      ]);
      return TelemetryServices(
        analytics: environment.telemetryEnabled
            ? FirebaseAnalyticsService(analytics)
            : NoopAnalytics(),
        crashes: environment.telemetryEnabled
            ? FirebaseCrashReporter(crashlytics)
            : NoopCrashReporter(),
        config: FirebaseFeatureConfig(config),
        performance: environment.telemetryEnabled
            ? FirebasePerformanceService(performance)
            : NoopPerformance(),
        firebaseConfigured: true,
      );
    } on Object {
      if (kDebugMode) {
        debugPrint('Firebase is unavailable; optional services are disabled.');
      }
      return TelemetryServices.disabled();
    }
  }
}
