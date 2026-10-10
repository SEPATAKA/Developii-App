import '../test/helpers/native_assets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../test/helpers/investor_critical_journeys.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  var converted = false;
  double? launchTopInset;
  setUp(() {
    converted = false;
    launchTopInset = null;
  });
  registerInvestorCriticalJourneys(
    capture: (tester, name) async {
      if (!const bool.fromEnvironment('CAPTURE_NATIVE_SCREENSHOTS')) return;
      await settleNativeImages(tester);
      final view = tester.view;
      final topInset = view.padding.top / view.devicePixelRatio;
      launchTopInset ??= topInset;
      final metrics = <String, Object?>{
        'width': view.physicalSize.width / view.devicePixelRatio,
        'height': view.physicalSize.height / view.devicePixelRatio,
        'pixelRatio': view.devicePixelRatio,
        'topInset': topInset,
        'bottomInset': view.padding.bottom / view.devicePixelRatio,
        'keyboardInset': view.viewInsets.bottom / view.devicePixelRatio,
      };
      if (name == 'investor-logout-guard') {
        final header = find.textContaining('Logout?', findRichText: true);
        final headerTop = tester.getTopLeft(header).dy;
        metrics['headerTop'] = headerTop;
        expect(headerTop, greaterThanOrEqualTo(topInset));
        expect(headerTop, greaterThanOrEqualTo(launchTopInset!));
      }
      binding.reportData ??= <String, dynamic>{};
      final checkpoints =
          binding.reportData!.putIfAbsent(
                'viewportMetrics',
                () => <String, Object?>{},
              )
              as Map<String, Object?>;
      checkpoints[name] = metrics;
      debugPrint('Native viewport $name: $metrics');
      if (defaultTargetPlatform == TargetPlatform.android && !converted) {
        await binding.convertFlutterSurfaceToImage();
        converted = true;
        await tester.pump();
      }
      await binding.takeScreenshot(name);
    },
  );
}
