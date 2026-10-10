import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/features/authentication/presentation/recovery_screen.dart';
import 'package:developify_mobile/features/profile/data/mock_profile_repository.dart';
import 'package:developify_mobile/features/profile/domain/profile_repository.dart';
import 'package:developify_mobile/features/profile/presentation/security_screen.dart';
import 'package:developify_mobile/features/profile/presentation/widgets/security_success_sheet.dart';
import 'package:developify_mobile/features/profile/presentation/widgets/transaction_pin_field.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'package:developify_mobile/features/investor/presentation/screens/investor_profile_screen.dart';
import 'helpers/fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<(AppDependencies, GoRouter)> mount(
    WidgetTester tester, {
    required String route,
    double width = 393,
    Duration delay = Duration.zero,
  }) async {
    tester.view.physicalSize = Size(width, 852);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 56, bottom: 34);
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    final dependencies = await AppDependencies.create(
      environment: AppEnvironment(mockDelay: delay),
    );
    dependencies.session.signIn(
      const AppUser(
        id: 'profile-investor',
        name: 'Babatunde Yusuf',
        email: 'investor@example.test',
        hasProfilePhoto: false,
      ),
      experience: Experience.investor,
    );
    final router = createAppRouter(dependencies, initialLocation: route);
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

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, String label, String value) async {
    final field = find.byKey(ValueKey('field-$label'));
    await tester.ensureVisible(field);
    await tester.enterText(field, value);
    await tester.pumpAndSettle();
  }

  for (final width in [360.0, 393.0, 430.0]) {
    testWidgets(
      'Investor profile switches entity and cancels or confirms logout at $width',
      (tester) async {
        final (dependencies, router) = await mount(
          tester,
          route: '/investor/profile',
          width: width,
        );
        final store = tester
            .widget<InvestorProfileScreen>(find.byType(InvestorProfileScreen))
            .store;
        await tap(
          tester,
          find.bySemanticsLabel(RegExp('Switch investor profile,')),
        );
        await tap(tester, find.text('Trust'));
        await tap(tester, find.text('Non-Resident / Diaspora'));
        await tap(tester, find.widgetWithText(AppButton, 'Use this entity'));
        expect(store.entity, EntityType.individual);
        expect(store.nonResident, isTrue);
        expect(dependencies.session.isAuthenticated, isTrue);
        await tap(
          tester,
          find.bySemanticsLabel(RegExp('Switch investor profile,')),
        );
        await tap(tester, find.text('Natural Person'));
        await tap(tester, find.widgetWithText(AppButton, 'Use this entity'));
        expect(store.entity, EntityType.individual);
        expect(store.nonResident, isFalse);
        final logout = find.byKey(const ValueKey('profile-menu-Logout'));
        await tester.scrollUntilVisible(
          logout,
          400,
          scrollable: find.byType(Scrollable).first,
        );
        await tap(tester, logout);
        expect(find.text('Log out of Developify'), findsOneWidget);
        await tap(tester, find.widgetWithText(AppButton, 'Cancel'));
        expect(dependencies.session.isAuthenticated, isTrue);
        expect(find.byType(InvestorProfileScreen), findsOneWidget);
        await tap(tester, logout);
        await tap(tester, find.widgetWithText(AppButton, 'Logout'));
        expect(dependencies.session.isAuthenticated, isFalse);
        expect(store.isDisposed, isTrue);
        expect(store.user, isNull);
        expect(store.account, isNull);
        router.go('/investor/wallet');
        await tester.pumpAndSettle();
        expect(router.state.uri.path, '/investor/welcome-back');
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets('Investor profile save, recovery and shared state at $width', (
      tester,
    ) async {
      final (dependencies, router) = await mount(
        tester,
        route: '/investor/profile/edit',
        width: width,
      );
      final repository =
          dependencies.container<ProfileRepository>() as MockProfileRepository;
      expect(find.text('Residential'), findsNothing);
      await tap(tester, find.byKey(const ValueKey('profile-change-photo')));
      await enter(tester, 'Full Name', 'Babatunde Updated');
      await enter(tester, 'Email Address', 'invalid');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      final save = find.byKey(const ValueKey('profile-save'));
      expect(tester.getBottomLeft(save).dy, lessThanOrEqualTo(552));
      await tap(tester, save);
      expect(dependencies.session.user!.name, 'Babatunde Yusuf');
      expect(dependencies.session.user!.hasProfilePhoto, false);
      await enter(tester, 'Email Address', 'updated@example.test');
      tester.view.resetViewInsets();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      repository.behavior.failNext();
      await tap(tester, save);
      expect(find.text('Unable to connect. Please try again.'), findsWidgets);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Leave without saving?'), findsOneWidget);
      await tap(tester, find.widgetWithText(AppButton, 'Keep editing'));
      await tap(tester, save);
      expect(dependencies.session.user!.name, 'Babatunde Updated');
      expect(dependencies.session.user!.email, 'updated@example.test');
      expect(dependencies.session.user!.hasProfilePhoto, true);
      expect(
        dependencies.session.user!.address,
        '14 Protea Ave, Randburg, Gauteng, 2184',
      );
      dependencies.session.selectExperience(Experience.landowner);
      router.go('/profile/edit');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const ValueKey('field-Full Name')),
                matching: find.byType(TextField),
              ),
            )
            .controller!
            .text,
        'Babatunde Updated',
      );
      await tester.scrollUntilVisible(
        find.text('Residential'),
        250,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('profile-edit-content')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Residential'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Investor SMS, PIN and preference return at $width', (
      tester,
    ) async {
      final (dependencies, _) = await mount(
        tester,
        route: '/investor/profile/security',
        width: width,
      );
      await tap(tester, find.text('Setup 2FA'));
      await tap(tester, find.text('SMS Authentication'));
      await enter(tester, 'Phone Number', '9012345678');
      await tap(tester, find.widgetWithText(AppButton, 'Send code'));
      expect(find.textContaining('simulate SMS verification'), findsOneWidget);
      final code = find.descendant(
        of: find.byType(CodeField),
        matching: find.byType(TextField),
      );
      await tester.enterText(code, '000000');
      await tap(tester, find.widgetWithText(AppButton, 'Verify'));
      expect(tester.widget<CodeField>(find.byType(CodeField)).invalid, true);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(CodeField), findsNothing);
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const ValueKey('field-Phone Number')),
                matching: find.byType(TextField),
              ),
            )
            .controller!
            .text,
        '9012345678',
      );
      await tap(tester, find.widgetWithText(AppButton, 'Send code'));
      await tester.enterText(code, '123456');
      await tap(tester, find.widgetWithText(AppButton, 'Verify'));
      expect(find.byType(SecuritySuccessSheet), findsOneWidget);
      expect(
        find.textContaining('No SMS service is connected'),
        findsOneWidget,
      );
      await tap(tester, find.widgetWithText(AppButton, 'Done'));
      final screen = tester.widget<SecurityScreen>(find.byType(SecurityScreen));
      expect(screen.store.twoFactorEnabled, true);
      await tap(tester, find.text('Change  Transaction PIN'));
      await enter(tester, 'Enter Current Password', 'ExistingPass123!');
      await tap(tester, find.widgetWithText(AppButton, 'Continue'));
      expect(find.byType(TransactionPinField), findsOneWidget);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.enterText(
        find.byKey(const ValueKey('transaction-pin-field')),
        '5678',
      );
      await tester.pumpAndSettle();
      final next = find.widgetWithText(AppButton, 'Continue');
      expect(tester.getBottomLeft(next).dy, lessThanOrEqualTo(552));
      tester.view.resetViewInsets();
      await tap(tester, next);
      expect(find.byKey(const ValueKey('transaction-pin-field')), findsNothing);
      expect(
        tester
            .widget<TransactionPinField>(find.byType(TransactionPinField))
            .completed,
        isTrue,
      );
      expect(
        tester.widget<SecurityScreen>(find.byType(SecurityScreen)).store.pin,
        isEmpty,
      );
      await tap(tester, find.widgetWithText(AppButton, 'Done'));
      expect(
        dependencies
            .container<ProfileRepository>()
            .securityPreferences
            .twoFactorEnabled,
        true,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Investor password form validates, retries and blocks pending Back',
    (tester) async {
      final (dependencies, _) = await mount(
        tester,
        route: '/investor/profile/security/password',
        width: 360,
        delay: const Duration(milliseconds: 300),
      );
      final repository =
          dependencies.container<ProfileRepository>() as MockProfileRepository;
      await enter(tester, 'Current Password', 'ExistingPass123!');
      await enter(tester, 'New Password', 'Replacement123!');
      await enter(tester, 'Confirm New Password', 'Mismatch123!');
      final update = find.widgetWithText(AppButton, 'Update Password');
      expect(tester.widget<AppButton>(update).onPressed, isNull);
      expect(find.text('Passwords do not match'), findsOneWidget);
      await enter(tester, 'Confirm New Password', 'Replacement123!');
      repository.behavior.failNext();
      await tap(tester, update);
      expect(find.text('Unable to connect. Please try again.'), findsOneWidget);
      expect(repository.securityPreferences.previousDevices, hasLength(2));
      await tester.tap(update);
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pump();
      expect(find.text('Change Password'), findsOneWidget);
      expect(
        tester
            .widget<SecurityScreen>(find.byType(SecurityScreen))
            .store
            .canPerform('change-password'),
        false,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.byType(SecuritySuccessSheet), findsOneWidget);
      expect(repository.securityPreferences.previousDevices, isEmpty);
      final screen = tester.widget<SecurityScreen>(
        find.byType(SecurityScreen, skipOffstage: false),
      );
      expect(screen.store.password, isEmpty);
      expect(screen.store.newPassword, isEmpty);
      for (final field in tester.widgetList<TextField>(
        find.descendant(
          of: find.byType(SecurityScreen, skipOffstage: false),
          matching: find.byType(TextField, skipOffstage: false),
          skipOffstage: false,
        ),
      )) {
        expect(field.controller!.text, isEmpty);
      }
      await tap(tester, find.widgetWithText(AppButton, 'Done'));
      expect(find.text('Security'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Investor information Back stays in the current experience', (
    tester,
  ) async {
    final (dependencies, router) = await mount(
      tester,
      route: '/investor/privacy',
    );
    await tap(tester, find.bySemanticsLabel('Back'));
    expect(find.text('About Developify'), findsOneWidget);
    expect(dependencies.session.experience, Experience.investor);
    await tap(tester, find.text('Terms & Condition'));
    await tap(tester, find.bySemanticsLabel('Back'));
    expect(find.text('About Developify'), findsOneWidget);
    router.go('/investor/profile/help');
    await tester.pumpAndSettle();
    await tap(tester, find.bySemanticsLabel('Back'));
    expect(router.routeInformationProvider.value.uri.path, '/investor/profile');
    expect(dependencies.session.experience, Experience.investor);
    expect(tester.takeException(), isNull);
  });
}
