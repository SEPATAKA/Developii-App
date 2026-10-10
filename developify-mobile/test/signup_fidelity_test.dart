import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/core/widgets/password_visibility_button.dart';
import 'package:developify_mobile/core/widgets/password_strength_meter.dart';
import 'package:developify_mobile/core/widgets/phone_number_field.dart';
import 'package:developify_mobile/features/authentication/presentation/signup_screen.dart';
import 'package:developify_mobile/features/authentication/presentation/widgets/landowner_consent.dart';
import 'package:developify_mobile/features/authentication/presentation/widgets/landowner_entity_choices.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'helpers/fidelity_capture.dart';
import 'helpers/fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  testWidgets(
    'Signup geometry, consent, country, owner selection and back flow',
    (tester) async {
      tester.view.physicalSize = const Size(393, 922);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 56, bottom: 34);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final deps = await AppDependencies.create(
        environment: const AppEnvironment(mockDelay: Duration.zero),
      );
      final router = createAppRouter(deps, initialLocation: '/welcome');
      final boundary = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: DevelopifyApp(dependencies: deps, router: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('List my land'));
      await tester.pumpAndSettle();
      expect(find.byType(SignupScreen), findsOneWidget);
      final store = tester
          .widget<SignupScreen>(find.byType(SignupScreen))
          .store;
      await captureFidelity(tester, boundary, '4105-7269');
      expect(tester.getTopLeft(find.text('Get started')).dy, closeTo(146, 1));
      expect(tester.getTopLeft(find.text('Full Name')).dy, closeTo(248, 1));
      expect(
        tester.getTopLeft(find.byType(PasswordStrengthMeter)).dy,
        closeTo(681, 1),
      );
      expect(
        tester.getTopLeft(find.byType(LandownerConsent)).dy,
        closeTo(756, 1),
      );
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('create-landowner-account')))
            .dy,
        closeTo(827, 1),
      );
      for (final field in [
        ('Full Name', 'Babatunde Yusuf'),
        ('Email Address', 'Thomashook@gmail.com'),
        ('Phone Number', '71081280182'),
        ('Password', 'Winner2026\$\$\$'),
        ('Confirm Password', 'Winner2026\$\$\$'),
      ]) {
        final finder = find.byKey(ValueKey('field-${field.$1}'));
        await tester.ensureVisible(finder);
        await tester.enterText(finder, field.$2);
        await tester.pump();
      }
      await tester.tap(find.byType(PasswordVisibilityButton).first);
      await tester.tap(find.byType(PasswordVisibilityButton).last);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(store.passwordVisible, isTrue);
      expect(store.confirmationVisible, isTrue);
      expect(store.passwordStrength, 4);
      await captureFidelity(tester, boundary, '4105-7326');
      expect(tester.getTopLeft(find.text('Full Name')).dy, closeTo(251, 1));
      expect(store.continueToEntity(), isFalse);
      expect(store.choosingEntity, isFalse);
      store.acceptTerms(true);
      await tester.pumpAndSettle();
      await captureFidelity(tester, boundary, '4105-7382');
      await tester.enterText(
        find.byKey(const ValueKey('field-Phone Number')),
        '',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      runInAction(() {
        store.invalidCredentials = true;
      });
      await tester.pumpAndSettle();
      await captureFidelity(tester, boundary, '4105-7439');
      expect(store.canAttemptDetails, isTrue);
      await tester.tap(find.byKey(const ValueKey('create-landowner-account')));
      await tester.pumpAndSettle();
      expect(store.choosingEntity, isFalse);
      expect(store.error, 'Enter a valid phone number');
      await tester.enterText(
        find.byKey(const ValueKey('field-Phone Number')),
        '71081280182',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Full Name')).dy, closeTo(237, 1));
      await tester.tap(find.byKey(const ValueKey('phone-country')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('South Africa (+27)'));
      await tester.pumpAndSettle();
      expect(store.dialCode, '+27');
      expect(store.phone, '71081280182');
      await tester.ensureVisible(
        find.byKey(const ValueKey('create-landowner-account')),
      );
      await tester.tap(find.byKey(const ValueKey('create-landowner-account')));
      await tester.pumpAndSettle();
      expect(find.byType(LandownerEntityChoices), findsOneWidget);
      await captureFidelity(tester, boundary, '4105-7496');
      expect(
        tester.getTopLeft(find.byType(LandownerEntityChoices)).dy,
        closeTo(196, 1),
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(PhoneNumberField), findsOneWidget);
      expect(store.password, 'Winner2026\$\$\$');
      expect(store.phone, '71081280182');
      tester.view.physicalSize = const Size(360, 780);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(LandownerConsent));
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(
        find.byKey(const ValueKey('create-landowner-account')),
      );
      await tester.tap(find.byKey(const ValueKey('create-landowner-account')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('owner-entity-company')),
      );
      await tester.tap(find.byKey(const ValueKey('owner-entity-company')));
      expect(store.entity, EntityType.company);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(
        find.byKey(const ValueKey('create-landowner-account')),
      );
      await tester.tap(find.byKey(const ValueKey('create-landowner-account')));
      await tester.pumpAndSettle();
      expect(deps.session.isAuthenticated, isTrue);
      expect(deps.session.user?.name, 'Babatunde Yusuf');
      expect(deps.session.user?.entity, EntityType.company);
      expect(deps.session.user?.phone, '+27 71081280182');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await deps.dispose();
    },
  );
}
