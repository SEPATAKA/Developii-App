import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/app/router/route_names.dart';
import 'package:developify_mobile/core/services/push_notification_service.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';

class DevelopifyApp extends StatefulWidget {
  const DevelopifyApp({super.key, required this.dependencies, this.router});
  final AppDependencies dependencies;
  final GoRouter? router;
  @override
  State<DevelopifyApp> createState() => _DevelopifyAppState();
}

class _DevelopifyAppState extends State<DevelopifyApp> {
  late final GoRouter _router =
      widget.router ?? createAppRouter(widget.dependencies);
  StreamSubscription<PushTarget>? _pushTaps;
  String? _externalId;
  @override
  void initState() {
    super.initState();
    widget.dependencies.session.startExpiryMonitoring();
    // TODO: Retain validated taps until authenticated entity scope and router
    // readiness are confirmed; see docs/OBSERVABILITY_AND_NOTIFICATIONS.md.
    _pushTaps = widget.dependencies.push.taps.listen((target) {
      switch (target.destination) {
        case PushDestination.notifications:
          _router.goNamed(Routes.notifications);
        case PushDestination.property:
          _router.goNamed(Routes.property, pathParameters: {'id': target.id!});
      }
    });
    widget.dependencies.session.addListener(_syncPushIdentity);
  }

  void _syncPushIdentity() {
    final id = widget.dependencies.session.user?.id;
    if (_externalId == id) return;
    _externalId = id;
    if (id == null) {
      unawaited(widget.dependencies.push.removeExternalUserId());
    } else {
      unawaited(widget.dependencies.push.setExternalUserId(id));
    }
  }

  @override
  void dispose() {
    widget.dependencies.session.stopExpiryMonitoring();
    widget.dependencies.session.removeListener(_syncPushIdentity);
    unawaited(_pushTaps?.cancel());
    if (widget.router == null) _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScreenUtilInit(
    designSize: const Size(393, 852),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) => MaterialApp.router(
      title: 'Developify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: child!,
      ),
      routerConfig: _router,
    ),
  );
}
