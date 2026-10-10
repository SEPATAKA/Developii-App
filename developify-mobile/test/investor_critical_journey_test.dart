import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers/fonts.dart';
import 'helpers/investor_critical_journeys.dart';

void main() {
  setUpAll(loadAppFonts);
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.implicitView!.physicalSize = const Size(
      393,
      852,
    );
    binding.platformDispatcher.implicitView!.devicePixelRatio = 1;
    binding.platformDispatcher.implicitView!.padding = const FakeViewPadding(
      top: 56,
      bottom: 34,
    );
    addTearDown(binding.platformDispatcher.implicitView!.reset);
  });
  registerInvestorCriticalJourneys();
}
