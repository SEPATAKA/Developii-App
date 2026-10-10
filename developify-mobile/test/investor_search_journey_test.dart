import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/features/investor/domain/investor_account_context.dart';
import 'package:developify_mobile/features/investor/domain/investor_repository.dart';
import 'package:developify_mobile/features/investor/presentation/screens/investor_search_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/project_screen.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'helpers/fonts.dart';

void main() {
  setUpAll(loadAppFonts);
  Future<(AppDependencies, GoRouter)> mount(
    WidgetTester tester,
    String path, {
    double width = 393,
    double scale = 1,
    bool favourite = false,
  }) async {
    tester.view.physicalSize = Size(width, 852);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    final dependencies = await AppDependencies.create(
      environment: const AppEnvironment(mockDelay: Duration.zero),
    );
    dependencies.session.signIn(
      const AppUser(
        id: 'search-investor',
        name: 'Babatunde Yusuf',
        email: 'investor@example.test',
      ),
      experience: Experience.investor,
    );
    if (favourite) {
      await tester.runAsync(
        () => dependencies.container<InvestorCatalogRepository>().setFavourite(
          'saffron-towers',
          true,
        ),
      );
    }
    final router = createAppRouter(dependencies, initialLocation: path);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await tester.runAsync(dependencies.dispose);
    });
    await tester.pumpWidget(
      DevelopifyApp(dependencies: dependencies, router: router),
    );
    await tester.pumpAndSettle();
    return (dependencies, router);
  }

  testWidgets(
    'Search suggestions, empty recovery and project return retain the query',
    (tester) async {
      final (dependencies, router) = await mount(tester, '/investor/explore');
      await tester.tap(find.bySemanticsLabel('Search projects'));
      await tester.pumpAndSettle();
      expect(find.byType(InvestorSearchScreen), findsOneWidget);
      expect(find.text('Recent Searches'), findsOneWidget);
      final field = find.byKey(const ValueKey('field-'));
      await tester.enterText(field, 'No matching project');
      await tester.pumpAndSettle();
      expect(find.text('Result (0)'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Clear search'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Search Cape Town'));
      await tester.pumpAndSettle();
      expect(
        dependencies
            .container<InvestorCatalogRepository>()
            .recentSearches
            .first,
        'Cape Town',
      );
      final screen = tester.widget<InvestorSearchScreen>(
        find.byType(InvestorSearchScreen),
      );
      expect(
        screen.store.results.every((project) => project.city == 'Capetown'),
        isTrue,
      );
      expect(screen.store.results, isNotEmpty);
      await tester.tap(find.byType(InvestorProjectRow).first);
      await tester.pumpAndSettle();
      expect(find.byType(InvestorProjectScreen), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<InvestorSearchScreen>(find.byType(InvestorSearchScreen))
            .store,
        same(screen.store),
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'Cape Town',
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [360.0, 393.0, 430.0]) {
    testWidgets(
      'Search remains editable above the keyboard with large text at $width',
      (tester) async {
        await mount(
          tester,
          '/investor/explore/search',
          width: width,
          scale: 1.6,
        );
        final field = find.byKey(const ValueKey('field-'));
        await tester.enterText(field, 'A place that has no matching property');
        tester.view.viewInsets = const FakeViewPadding(bottom: 291);
        await tester.pumpAndSettle();
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
        expect(field.hitTestable(), findsOneWidget);
        expect(tester.getRect(field).bottom, lessThanOrEqualTo(561));
        expect(find.text('Result (0)'), findsOneWidget);
        await tester.tap(find.bySemanticsLabel('Clear search'));
        await tester.pumpAndSettle();
        expect(find.text('Recent Searches'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Wishlist removes a saved project and exposes a recoverable empty state',
    (tester) async {
      final (dependencies, _) = await mount(
        tester,
        '/investor/explore/wishlist',
        favourite: true,
      );
      expect(find.text('Wishlist'), findsOneWidget);
      final store = tester
          .widget<InvestorSearchScreen>(find.byType(InvestorSearchScreen))
          .store;
      expect(store.results.single.id, 'saffron-towers');
      await tester.tap(find.byType(InvestorFavouriteButton));
      await tester.pumpAndSettle();
      expect(find.text('No favourite projects yet'), findsOneWidget);
      expect(
        dependencies.container<InvestorCatalogRepository>().favouriteIds,
        isEmpty,
      );
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Explore'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Search rejects invalid primitive parameters', (tester) async {
    final (_, router) = await mount(tester, '/investor/explore/search?q=a&q=b');
    expect(find.text('This project search is invalid.'), findsOneWidget);
    for (final path in [
      '/investor/explore/wishlist?mode=unknown',
      '/investor/explore/search?q=${'x' * 121}',
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(find.text('This project search is invalid.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  test(
    'Search history is bounded and isolated between entities and users',
    () async {
      final dependencies = await AppDependencies.create(
        environment: const AppEnvironment(mockDelay: Duration.zero),
      );
      addTearDown(dependencies.dispose);
      dependencies.session.signIn(
        const AppUser(
          id: 'search-history-user',
          name: 'Test Investor',
          email: 'history@example.test',
        ),
        experience: Experience.investor,
      );
      final repository = dependencies.container<InvestorCatalogRepository>();
      final context = dependencies.container<InvestorAccountContext>();
      for (var index = 0; index < 7; index++) {
        repository.rememberSearch('Project $index');
      }
      expect(repository.recentSearches.length, 5);
      expect(repository.recentSearches.first, 'Project 6');
      repository.rememberSearch('project 6');
      expect(
        repository.recentSearches
            .where((item) => item.toLowerCase() == 'project 6')
            .length,
        1,
      );
      context.selectEntity(EntityType.trust);
      expect(repository.recentSearches, isNot(contains('project 6')));
      context.selectEntity(EntityType.individual);
      expect(repository.recentSearches.first, 'project 6');
      dependencies.session.signOut();
      dependencies.session.signIn(
        const AppUser(
          id: 'different-search-user',
          name: 'Another Investor',
          email: 'another@example.test',
        ),
        experience: Experience.investor,
      );
      expect(repository.recentSearches, isNot(contains('project 6')));
    },
  );
}
