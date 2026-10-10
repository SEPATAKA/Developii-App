import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/core/widgets/app_switch.dart';
import 'package:developify_mobile/features/profile/data/mock_profile_repository.dart';
import 'package:developify_mobile/features/profile/domain/profile_repository.dart';
import 'package:developify_mobile/features/profile/presentation/profile_screen.dart';
import 'package:developify_mobile/features/profile/presentation/widgets/language_choice.dart';
import 'package:developify_mobile/features/profile/presentation/widgets/preference_group.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'helpers/fidelity_capture.dart';
import 'helpers/fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  void viewport(WidgetTester tester, [double height = 852]) {
    tester.view.physicalSize = Size(393, height);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 56, bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  const user = AppUser(
    id: 'local-landowner',
    name: 'Babatunde Yusuf',
    email: 'Thomashook@gmail.com',
    phone: '+1 71081280182',
  );

  testWidgets(
    'Landowner Profile full height, menu navigation and scroll reachability',
    (tester) async {
      viewport(tester, 1439);
      final deps = await AppDependencies.create(
        environment: const AppEnvironment(mockDelay: Duration.zero),
      );
      deps.session.signIn(user.copyWith(email: 'bafreka@gmail.com'));
      final router = createAppRouter(
        deps,
        initialLocation: '/profile/language',
      );
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: DevelopifyApp(dependencies: deps, router: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('language-English (US)')));
      await tester.pumpAndSettle();
      router.go('/profile');
      await tester.pumpAndSettle();
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('profile-menu-Edit Profile')))
            .dy,
        closeTo(391, 1),
      );
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('profile-menu-Logout'))).dy,
        closeTo(1210, 1),
      );
      expect(find.text('Individual  Landowner'), findsOneWidget);
      expect(find.text('Tier 1'), findsNothing);
      await captureFidelity(tester, key, '4105-9411');
      await tester.tap(find.byKey(const ValueKey('profile-menu-Edit Profile')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('profile-edit-content')),
        findsOneWidget,
      );
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('profile-menu-Language')));
      await tester.pumpAndSettle();
      expect(find.byType(LanguageChoice), findsNWidgets(2));
      router.pop();
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(393, 852);
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-11089');
      tester.view.physicalSize = const Size(360, 780);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('profile-menu-Logout')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await deps.dispose();
    },
  );

  testWidgets('Preference states, persistence and failed update recovery', (
    tester,
  ) async {
    viewport(tester);
    final deps = await AppDependencies.create(
      environment: const AppEnvironment(mockDelay: Duration.zero),
    );
    deps.session.signIn(user);
    final router = createAppRouter(
      deps,
      initialLocation: '/profile/notifications',
    );
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: DevelopifyApp(dependencies: deps, router: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<AppSwitch>(find.byType(AppSwitch))
          .every((s) => s.value),
      isTrue,
    );
    expect(tester.getTopLeft(find.text('CHANNELS')).dy, closeTo(150, 1));
    expect(
      tester.getSize(find.byType(PreferenceGroup).first).height,
      closeTo(146, 1),
    );
    expect(tester.getTopLeft(find.text('TOPICS')).dy, closeTo(345, 1));
    expect(
      tester.getTopLeft(find.text('Marketing & tips')).dy,
      closeTo(588.5, 1),
    );
    await captureFidelity(tester, key, '4105-12469');
    final repository =
        deps.container<ProfileRepository>() as MockProfileRepository;
    for (final name in [
      ...repository.preferences.channels.keys,
      ...repository.preferences.topics.keys,
    ]) {
      await tester.tap(find.byKey(ValueKey('preference-$name')));
      await tester.pumpAndSettle();
    }
    expect(
      tester
          .widgetList<AppSwitch>(find.byType(AppSwitch))
          .every((s) => !s.value),
      isTrue,
    );
    await captureFidelity(tester, key, '4105-12572');
    router.go('/profile/language');
    await tester.pumpAndSettle();
    expect(find.byType(LanguageChoice), findsNWidgets(2));
    expect(
      tester.getTopLeft(find.byType(LanguageChoice).first).dy,
      closeTo(142, 1),
    );
    await captureFidelity(tester, key, '4105-10761');
    await tester.tap(find.byKey(const ValueKey('language-English (US)')));
    await tester.pumpAndSettle();
    expect(repository.preferences.language, 'English (US)');
    router.go('/profile/notifications');
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<AppSwitch>(find.byType(AppSwitch))
          .every((s) => !s.value),
      isTrue,
    );
    repository.behavior.failNext();
    await tester.tap(find.byKey(const ValueKey('preference-SMS')));
    await tester.pumpAndSettle();
    expect(repository.preferences.channels['SMS'], isFalse);
    expect(find.text('Unable to connect. Please try again.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('preference-SMS')));
    await tester.pumpAndSettle();
    expect(repository.preferences.channels['SMS'], isTrue);
    tester.view.physicalSize = const Size(360, 780);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    await deps.dispose();
  });

  testWidgets(
    'Edit Profile assets, complete form, photo and country persistence',
    (tester) async {
      viewport(tester, 997);
      final deps = await AppDependencies.create(
        environment: const AppEnvironment(mockDelay: Duration.zero),
      );
      deps.session.signIn(user);
      final router = createAppRouter(deps, initialLocation: '/profile/edit');
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: DevelopifyApp(dependencies: deps, router: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Full Name')).dy, closeTo(301, 1));
      expect(tester.getTopLeft(find.text('Residential')).dy, closeTo(741, 1));
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('profile-save'))).dy,
        closeTo(902, 1),
      );
      await captureFidelity(tester, key, '4105-11684');
      router.go('/profile/language');
      await tester.pumpAndSettle();
      deps.session.updateUser(user.copyWith(hasProfilePhoto: false));
      router.go('/profile/edit');
      await tester.pumpAndSettle();
      await captureFidelity(tester, key, '4105-12398');
      expect(tester.getTopLeft(find.text('Full Name')).dy, closeTo(306, 1));
      await tester.tap(find.byKey(const ValueKey('profile-change-photo')));
      await tester.pumpAndSettle();
      expect(find.text('Change Photo'), findsOneWidget);
      expect(
        tester
            .widget<ProfileScreen>(find.byType(ProfileScreen))
            .store
            .user!
            .hasProfilePhoto,
        isTrue,
      );
      await tester.enterText(
        find.byKey(const ValueKey('field-Full Name')),
        'Themba Nkosi',
      );
      await tester.tap(find.byKey(const ValueKey('field-Country')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('United Kingdom'));
      await tester.pumpAndSettle();
      expect(find.text('United Kingdom'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('profile-save')));
      await tester.pumpAndSettle();
      expect(deps.session.user!.name, 'Themba Nkosi');
      expect(deps.session.user!.hasProfilePhoto, isTrue);
      expect(deps.session.user!.countryCode, 'GB');
      router.go('/profile/edit');
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(360, 780);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey('profile-edit-content')),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('profile-save')).hitTestable(),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await deps.dispose();
    },
  );
}
