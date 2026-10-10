import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/main.dart' as application;
import '../test/helpers/client_review_journey.dart';
import '../test/helpers/native_assets.dart';

void main() {
  final binding = _NativeTextBinding();
  var converted = false;
  registerClientReviewJourney(
    launch: (tester) async {
      final testErrorHandler = FlutterError.onError;
      await application.main();
      FlutterError.onError = testErrorHandler;
      await tester.pumpAndSettle();
      return tester
          .widget<DevelopifyApp>(find.byType(DevelopifyApp))
          .dependencies;
    },
    capture: (tester, name) async {
      await settleNativeImages(tester);
      binding.reportData ??= <String, dynamic>{};
      final view = tester.view;
      binding.reportData!['viewport'] = {
        'width': view.physicalSize.width / view.devicePixelRatio,
        'height': view.physicalSize.height / view.devicePixelRatio,
        'topInset': view.padding.top / view.devicePixelRatio,
        'bottomInset': view.padding.bottom / view.devicePixelRatio,
        'pixelRatio': view.devicePixelRatio,
        'textScaleSamples': {
          for (final size in [12.0, 14.0, 36.0, 48.0])
            '$size': MediaQuery.textScalerOf(
              tester.element(find.byType(Scaffold).first),
            ).scale(size),
        },
        'nativeTextScaleSamples': {
          for (final size in [12.0, 14.0, 36.0, 48.0])
            '$size': ui.PlatformDispatcher.instance.scaleFontSize(size),
        },
      };
      if (defaultTargetPlatform == TargetPlatform.android && !converted) {
        await binding.convertFlutterSurfaceToImage();
        converted = true;
        await tester.pump();
      }
      await binding.takeScreenshot(name);
    },
  );
}

class _NativeTextBinding extends IntegrationTestWidgetsFlutterBinding {
  @override
  Widget wrapWithDefaultView(Widget rootWidget) => super.wrapWithDefaultView(
    // TestPlatformDispatcher linearizes fonts; use the real native scaler here.
    MediaQuery(
      data: MediaQueryData.fromView(
        ui.PlatformDispatcher.instance.implicitView!,
      ),
      child: rootWidget,
    ),
  );
}
