import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:developify_mobile/core/services/session_service.dart';
import 'package:developify_mobile/core/storage/session_storage.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';

Future<AppDependencies> bootstrap({
  AppEnvironment? environment,
  bool launch = true,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final resolvedEnvironment = environment ?? AppEnvironment.fromDefines();
  // Only the demo session is restorable here; live token/session contracts are
  // an integration responsibility documented in docs/API_INTEGRATION_GUIDE.md.
  final session = SessionService(
    storage: resolvedEnvironment.mockMode
        ? const SecureSessionStorage(FlutterSecureStorage())
        : null,
  );
  await session.restore();
  final dependencies = await AppDependencies.create(
    environment: resolvedEnvironment,
    session: session,
  );
  if (launch) {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      unawaited(
        dependencies.telemetry.crashes.record(
          details.exception,
          details.stack ?? StackTrace.current,
          fatal: true,
        ),
      );
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      if (kDebugMode) {
        debugPrint('Unhandled application error: ${error.runtimeType}');
      }
      unawaited(
        dependencies.telemetry.crashes.record(error, stack, fatal: true),
      );
      return true;
    };
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    runApp(DevelopifyApp(dependencies: dependencies));
  }
  return dependencies;
}
