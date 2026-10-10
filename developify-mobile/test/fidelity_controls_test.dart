import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/app/router/landowner_shell.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_chrome.dart';
import 'package:developify_mobile/core/widgets/app_field.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/password_visibility_button.dart';
import 'package:developify_mobile/features/landowner/presentation/submission_screen.dart';
import 'package:developify_mobile/features/landowner/presentation/widgets/deeds_office_selection_sheet.dart';
import 'package:developify_mobile/features/landowner/presentation/widgets/property_selection_sheet.dart';
import 'package:developify_mobile/features/landowner/presentation/widgets/home_submit_property_card.dart';
import 'package:developify_mobile/features/landowner/presentation/widgets/properties_submit_another_property_card.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'helpers/fidelity_capture.dart';
import 'helpers/fonts.dart';

Finder _icon(String asset) => find.byWidgetPredicate(
  (widget) => widget is AppIcon && widget.asset == asset,
);

Future<void> _host(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(theme: AppTheme.light, home: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  setUp(() {
    binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  });
  tearDown(() {
    binding.platformDispatcher.clearAccessibilityFeaturesTestValue();
    final view = binding.platformDispatcher.implicitView!;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
    view.resetPadding();
  });
  void referenceView(WidgetTester tester) {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 56, bottom: 34);
  }

  testWidgets(
    'Auth and action headers share the exact back artwork and circle',
    (tester) async {
      referenceView(tester);
      for (final layout in AppHeaderLayout.values) {
        await _host(
          tester,
          AppPage(
            title: 'Step 1 of 9',
            headerLayout: layout,
            child: const SizedBox(),
          ),
        );
        expect(find.byType(AppBackButton), findsOneWidget);
        final svg = find.descendant(
          of: _icon(AppAssets.back),
          matching: find.byType(SvgPicture),
        );
        expect(tester.getSize(svg), const Size(24.75, 24.75));
        expect(
          tester.getTopLeft(svg),
          Offset(
            (layout == AppHeaderLayout.centeredTitle ? 13 : 22) + 4.125,
            77.125,
          ),
        );
        expect(tester.getSize(find.byType(AppBackButton)), const Size(44, 44));
        expect(
          tester.getSize(find.text('Step 1 of 9')).height,
          closeTo(19, .1),
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'Password visibility changes the exact SVG and preserves focus and selection',
    (tester) async {
      referenceView(tester);
      var visible = false;
      await _host(
        tester,
        Scaffold(
          body: StatefulBuilder(
            builder: (_, setState) => AppField(
              label: 'Password',
              obscure: !visible,
              suffix: PasswordVisibilityButton(
                visible: visible,
                onPressed: () => setState(() => visible = !visible),
              ),
            ),
          ),
        ),
      );
      final field = find.byKey(const ValueKey('field-Password'));
      await tester.enterText(field, 'Fidelity2026');
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'Fidelity2026',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      await tester.pump();
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      final rect = tester.getRect(field);
      expect(_icon(AppAssets.passwordConcealed), findsOneWidget);
      await tester.tap(find.byType(PasswordVisibilityButton));
      await tester.pumpAndSettle();
      final revealed = tester.widget<EditableText>(find.byType(EditableText));
      expect(_icon(AppAssets.passwordRevealedOutline), findsOneWidget);
      expect(revealed.obscureText, false);
      expect(revealed.focusNode, same(editable.focusNode));
      expect(revealed.focusNode.hasFocus, true);
      expect(revealed.controller.selection.baseOffset, 4);
      expect(revealed.controller.text, 'Fidelity2026');
      expect(tester.getRect(field), rect);
      await tester.tap(find.byType(PasswordVisibilityButton));
      await tester.pumpAndSettle();
      expect(_icon(AppAssets.passwordConcealed), findsOneWidget);
    },
  );

  testWidgets('Navigation uses separate authored active and inactive paths', (
    tester,
  ) async {
    referenceView(tester);
    var selection = 0;
    for (var index = 0; index < 4; index++) {
      await _host(
        tester,
        Scaffold(
          bottomNavigationBar: LandownerBottomNavigation(
            currentIndex: index,
            onSelected: (value) => selection = value,
          ),
        ),
      );
      expect(
        _icon(
          index == 1
              ? AppAssets.navPropertiesActive
              : AppAssets.navPropertiesInactive,
        ),
        findsOneWidget,
      );
      expect(
        _icon(index == 0 ? AppAssets.navHomeActive : AppAssets.navHomeInactive),
        findsOneWidget,
      );
      expect(
        _icon(
          index == 2
              ? AppAssets.navEarningsActive
              : AppAssets.navEarningsInactive,
        ),
        findsOneWidget,
      );
      expect(
        _icon(
          index == 3
              ? AppAssets.navProfileActive
              : AppAssets.navProfileInactive,
        ),
        findsOneWidget,
      );
      expect(
        tester.getSize(find.byType(LandownerBottomNavigation)).height,
        closeTo(98, 1),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('landowner-tab-1'))).width,
        closeTo(78.6, .1),
      );
      await tester.tap(find.byKey(const ValueKey('landowner-tab--1')));
      expect(selection, -1);
    }
  });

  testWidgets('Home and Properties use distinct measured submission cards', (
    tester,
  ) async {
    referenceView(tester);
    var tapped = '';
    final key = GlobalKey();
    await _host(
      tester,
      RepaintBoundary(
        key: key,
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                HomeSubmitPropertyCard(onTap: () => tapped = 'home'),
                const SizedBox(height: 20),
                PropertiesSubmitAnotherPropertyCard(
                  onTap: () => tapped = 'properties',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(_icon(AppAssets.homeSubmitProperty), findsOneWidget);
    expect(_icon(AppAssets.propertiesSubmitAnother), findsOneWidget);
    expect(
      tester.getSize(find.byType(HomeSubmitPropertyCard)),
      const Size(369, 81),
    );
    expect(
      tester.getSize(find.byType(PropertiesSubmitAnotherPropertyCard)),
      const Size(369, 71),
    );
    await tester.tap(find.byType(HomeSubmitPropertyCard));
    expect(tapped, 'home');
    await tester.tap(find.byType(PropertiesSubmitAnotherPropertyCard));
    expect(tapped, 'properties');
    await captureFidelity(tester, key, 'submission-cards');
  });

  testWidgets('Select trailing icon preserves its 24 pixel viewport', (
    tester,
  ) async {
    referenceView(tester);
    await _host(
      tester,
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: AppSelect(
            label: 'Property Type',
            value: '',
            hint: 'E.g ( Vacant land, Existing building)',
            onTap: () {},
          ),
        ),
      ),
    );
    final icon = _icon(AppAssets.chevronDown);
    expect(tester.getSize(icon), const Size(24, 24));
    expect(tester.getTopLeft(icon).dx, 348);
    expect(tester.getSize(find.byType(AppSelect)).height, closeTo(67, 1));
  });

  testWidgets(
    'Deeds Office selects, reopens, closes and dismisses before the submission route',
    (tester) async {
      referenceView(tester);
      final deps = await AppDependencies.create(
        environment: const AppEnvironment(mockDelay: Duration.zero),
      );
      deps.session.signIn(
        const AppUser(
          id: 'fidelity',
          name: 'Babatunde Yusuf',
          email: 'owner@example.test',
        ),
      );
      final router = createAppRouter(deps, initialLocation: '/submit/1');
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: DevelopifyApp(dependencies: deps, router: router),
        ),
      );
      await tester.pumpAndSettle();
      final store = tester
          .widget<SubmissionScreen>(find.byType(SubmissionScreen))
          .store;
      final field = find.byKey(const ValueKey('deeds-office-field'));
      Future<void> open() async {
        await tester.ensureVisible(field);
        await tester.tap(field);
        await tester.pumpAndSettle();
      }

      await open();
      expect(find.byType(DeedsOfficeSelectionSheet), findsOneWidget);
      expect(
        tester.getRect(find.byKey(const ValueKey('deeds-office-sheet'))).top,
        closeTo(167, 1),
      );
      expect(_icon(AppAssets.flagSouthAfrica), findsNWidgets(8));
      await captureFidelity(tester, key, '4105-18022');
      await tester.tap(find.byKey(const ValueKey('deeds-office-0')));
      await tester.pumpAndSettle();
      expect(store.draft.deedsOffice, 'Cape Town (WC)');
      expect(find.byType(DeedsOfficeSelectionSheet), findsNothing);
      await open();
      expect(
        tester
            .widget<DeedsOfficeSelectionSheet>(
              find.byType(DeedsOfficeSelectionSheet),
            )
            .selected,
        'Cape Town (WC)',
      );
      await captureFidelity(tester, key, 'deeds-office-selected');
      await tester.tap(find.byKey(const ValueKey('selection-sheet-close')));
      await tester.pumpAndSettle();
      expect(store.draft.deedsOffice, 'Cape Town (WC)');
      await open();
      await tester.tapAt(const Offset(190, 140));
      await tester.pumpAndSettle();
      expect(find.byType(DeedsOfficeSelectionSheet), findsNothing);
      await open();
      await binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(DeedsOfficeSelectionSheet), findsNothing);
      expect(find.byType(SubmissionScreen), findsOneWidget);
      expect(store.step, 1);
      expect(store.draft.deedsOffice, 'Cape Town (WC)');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await deps.dispose();
    },
  );

  testWidgets(
    'Property Basics geometry, selection sheets and completion state',
    (tester) async {
      referenceView(tester);
      final deps = await AppDependencies.create(
        environment: const AppEnvironment(mockDelay: Duration.zero),
      );
      deps.session.signIn(
        const AppUser(
          id: 'fidelity',
          name: 'Babatunde Yusuf',
          email: 'owner@example.test',
        ),
      );
      final router = createAppRouter(deps, initialLocation: '/submit/1');
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: DevelopifyApp(dependencies: deps, router: router),
        ),
      );
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-15429');
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('submission-progress'))),
        const Offset(12, 137),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('submission-progress-track'))),
        const Size(338, 10),
      );
      expect(
        tester.getTopLeft(find.text('Property Basics')),
        const Offset(12, 178),
      );
      expect(
        tester.getTopLeft(find.text('Enter Property Name')),
        const Offset(24, 327.5),
      );
      for (final (label, y) in [
        ('Property Name', 292),
        ('Property number', 380),
        ('Property Type', 468),
        ('Property Size', 556),
        ('Deeds Office', 644),
      ]) {
        expect(
          tester.getTopLeft(find.text(label)).dy,
          closeTo(y, 1),
          reason: label,
        );
      }
      final continueButton = find.widgetWithText(TextButton, 'Continue');
      expect(tester.widget<TextButton>(continueButton).onPressed, isNull);
      expect(
        tester.getRect(continueButton),
        const Rect.fromLTWH(12, 769, 369, 48),
      );
      await tester.tap(find.byKey(const ValueKey('type-selection-field')));
      await tester.pumpAndSettle();
      expect(find.byType(PropertySelectionSheet), findsOneWidget);
      expect(
        tester.getRect(find.byKey(const ValueKey('propertyType-sheet'))).top,
        closeTo(516, 1),
      );
      await captureFidelity(tester, key, '4105-17823');
      await tester.tap(find.byKey(const ValueKey('selection-sheet-close')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('type-selection-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('propertyType-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('field-Unit')));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(const ValueKey('unit-sheet'))).top,
        closeTo(446, 1),
      );
      await captureFidelity(tester, key, '4105-17920');
      await tester.tap(find.byKey(const ValueKey('unit-0')));
      await tester.pumpAndSettle();
      final store = tester
          .widget<SubmissionScreen>(find.byType(SubmissionScreen))
          .store;
      expect(store.draft.propertyType, 'Vacant Land');
      expect(store.draft.unit, 'Square Metre');
      expect(find.text('Square Metre'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('field-Property Name')),
        'Malibongwe Drive',
      );
      await tester.enterText(
        find.byKey(const ValueKey('field-Property number')),
        'Erf 4412',
      );
      await tester.enterText(
        find.byKey(const ValueKey('field-Property Size')),
        '1.22',
      );
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      expect(tester.widget<TextButton>(continueButton).onPressed, isNull);
      await tester.tap(find.byKey(const ValueKey('deeds-office-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('deeds-office-2')));
      await tester.pumpAndSettle();
      expect(tester.widget<TextButton>(continueButton).onPressed, isNotNull);
      await captureFidelity(tester, key, 'property-basics-complete');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await deps.dispose();
    },
  );

  testWidgets('Every production SVG loads and parses', (tester) async {
    referenceView(tester);
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final icons = manifest
        .listAssets()
        .where(
          (asset) =>
              asset.startsWith('assets/icons/') && asset.endsWith('.svg'),
        )
        .toList();
    expect(icons, isNotEmpty);
    for (final asset in icons) {
      final data = await rootBundle.load(asset);
      expect(data.lengthInBytes, greaterThan(0), reason: asset);
    }
    await _host(
      tester,
      Scaffold(
        body: Wrap(children: [for (final asset in icons) AppIcon(asset)]),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
