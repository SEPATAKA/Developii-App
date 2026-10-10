import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/features/landowner/domain/property.dart';
import 'package:developify_mobile/features/landowner/presentation/earnings_screen.dart';
import 'package:developify_mobile/features/landowner/presentation/properties_screen.dart';
import 'package:developify_mobile/features/landowner/presentation/widgets/home_header.dart';
import 'package:developify_mobile/features/landowner/presentation/widgets/home_submit_property_card.dart';
import 'package:developify_mobile/features/landowner/presentation/widgets/property_card.dart';
import 'package:developify_mobile/features/landowner/presentation/widgets/market_insight_card.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'helpers/fonts.dart';
import 'helpers/fidelity_capture.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  setUp(() {
    binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  });
  tearDown(() {
    binding.platformDispatcher.clearAccessibilityFeaturesTestValue();
    binding.platformDispatcher.clearTextScaleFactorTestValue();
    final view = binding.platformDispatcher.implicitView!;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
    view.resetPadding();
  });

  testWidgets(
    'Dashboard geometry, property filters and search match the current frames',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 56, bottom: 34);
      final deps = await AppDependencies.create(
        environment: const AppEnvironment(mockDelay: Duration.zero),
      );
      deps.session.signIn(
        const AppUser(
          id: 'owner',
          name: 'Babatunde Yusuf',
          email: 'owner@example.test',
        ),
      );
      final router = createAppRouter(deps, initialLocation: '/home');
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: DevelopifyApp(dependencies: deps, router: router),
        ),
      );
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-7954');
      expect(tester.getSize(find.byType(HomeHeader)).height, closeTo(366, 1));
      expect(
        tester.getTopLeft(find.byType(HomeSubmitPropertyCard)).dy,
        closeTo(381, 1),
      );
      expect(tester.getTopLeft(find.byType(PropertyCard)).dy, closeTo(523, 1));
      expect(tester.getSize(find.byType(PropertyCard)).height, closeTo(103, 1));
      expect(
        tester.getTopLeft(find.byType(MarketInsightCard)).dy,
        closeTo(650, 1),
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('property-progress-ridge-live')))
            .width,
        closeTo(200, .1),
      );
      expect(tester.takeException(), isNull);

      router.go('/properties');
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-9146');
      expect(
        tester.getTopLeft(find.byType(PropertySearchField)).dy,
        closeTo(200, 1),
      );
      expect(
        tester.getSize(find.byType(PropertySearchField)).height,
        closeTo(44, 1),
      );
      expect(tester.getTopLeft(find.text('9 properties')).dy, closeTo(263, 1));
      expect(
        tester.getTopLeft(find.byType(PropertyCard).first).dy,
        closeTo(295, 1),
      );
      final store = tester
          .widget<PropertiesScreen>(find.byType(PropertiesScreen))
          .store;
      tester.view.physicalSize = const Size(393, 1093);
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-8572');
      tester.view.physicalSize = const Size(393, 852);
      await tester.pumpAndSettle();
      for (final (filter, frame, count) in [
        (PropertyStatus.draft, '4105-8707', 1),
        (PropertyStatus.underReview, '4105-8782', 2),
        (PropertyStatus.offerReady, '4105-8871', 2),
        (PropertyStatus.live, '4105-8962', 2),
        (PropertyStatus.paused, '4105-9053', 2),
      ]) {
        store.setFilter(filter);
        await tester.pumpAndSettle();
        await captureFidelity(tester, key, frame);
        expect(store.visibleItems.length, count);
        expect(tester.takeException(), isNull, reason: frame);
      }
      store.setFilter(null);
      await tester.enterText(
        find.byKey(const ValueKey('property-search')),
        'Sea Point',
      );
      await tester.pumpAndSettle();
      expect(store.visibleItems.single.id, 'sea-point');
      await captureFidelity(tester, key, 'properties-search');
      await tester.enterText(
        find.byKey(const ValueKey('property-search')),
        'No matching place',
      );
      await tester.pumpAndSettle();
      expect(store.visibleItems, isEmpty);
      expect(find.text('No Properties Yet'), findsOneWidget);
      await captureFidelity(tester, key, 'properties-search-empty');
      await tester.enterText(find.byKey(const ValueKey('property-search')), '');
      await tester.pumpAndSettle();
      expect(store.visibleItems.length, 9);
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(393, 909);
      router.go('/earnings');
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-15053');
      expect(
        tester.getTopLeft(find.byType(LinkedPayoutAccount)).dy,
        closeTo(349, 1),
      );
      expect(
        tester.getSize(find.byType(LinkedPayoutAccount)).height,
        closeTo(72, 1),
      );
      expect(
        tester.getTopLeft(find.byType(EarningsActivity)).dy,
        closeTo(474, 1),
      );
      expect(
        tester.getSize(find.byType(EarningsActivity)).height,
        closeTo(305, 1),
      );
      expect(find.text('Marula Heigths'), findsNWidgets(4));
      await tester.tap(find.bySemanticsLabel('Hide balance'));
      await tester.pumpAndSettle();
      expect(find.text('****'), findsNWidgets(2));
      expect(find.text('Hidden'), findsNothing);
      await captureFidelity(tester, key, '4105-15179');
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(360, 780);
      binding.platformDispatcher.textScaleFactorTestValue = 1.3;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      router.go('/home');
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -450),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await deps.dispose();
    },
  );
}
