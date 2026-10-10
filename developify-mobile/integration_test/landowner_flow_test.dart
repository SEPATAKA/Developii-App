import '../test/helpers/native_assets.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/features/authentication/presentation/recovery_screen.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/password_visibility_button.dart';
import 'package:developify_mobile/features/landowner/presentation/submission_screen.dart';
import 'package:developify_mobile/features/landowner/presentation/home_screen.dart';
import 'package:developify_mobile/features/landowner/presentation/earnings_screen.dart';
import 'package:developify_mobile/features/profile/presentation/profile_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/investor_home_screen.dart';
import 'package:developify_mobile/features/landowner/presentation/widgets/deeds_office_selection_sheet.dart';
import 'package:developify_mobile/features/landowner/domain/landowner_repository.dart';
import 'package:developify_mobile/features/landowner/presentation/stores/submission_store.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'package:developify_mobile/features/onboarding/presentation/onboarding_screen.dart';
import '../test/helpers/qa_credentials.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const captureScreenshots = bool.fromEnvironment(
    'CAPTURE_NATIVE_SCREENSHOTS',
    defaultValue: true,
  );
  testWidgets('Landowner native journey and primary visual capture', (
    tester,
  ) async {
    final deps = await AppDependencies.create(
      environment: const AppEnvironment(mockDelay: Duration(milliseconds: 100)),
    );
    final router = createAppRouter(deps, initialLocation: '/onboarding');
    final captureKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: DevelopifyApp(dependencies: deps, router: router),
      ),
    );
    Future<void> capture(String name) async {
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 400));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: name);
      await settleNativeImages(
        tester,
        settleAnimations: find.byType(OnboardingScreen).evaluate().isEmpty,
      );
      if (captureScreenshots) await binding.takeScreenshot(name);
    }

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 400));
    if (captureScreenshots && defaultTargetPlatform == TargetPlatform.android) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
    }
    await capture('onboarding-1');
    expect(find.text('Get started'), findsOneWidget);
    final onboarding = tester
        .widget<OnboardingScreen>(find.byType(OnboardingScreen))
        .store;
    final carousel = tester.widget<PageView>(find.byType(PageView)).controller!;
    final firstPhysicalPage = carousel.page!.round();
    Future<void> awaitSlide(int logicalPage) async {
      for (var attempt = 0; attempt < 45; attempt++) {
        if (onboarding.page == logicalPage &&
            !carousel.position.isScrollingNotifier.value) {
          return;
        }
        await tester.pump(const Duration(milliseconds: 200));
      }
      fail(
        'Onboarding did not settle on logical page $logicalPage; '
        'actual page ${onboarding.page}, physical page ${carousel.page}',
      );
    }

    for (var step = 1; step <= 5; step++) {
      await awaitSlide(step % 4);
      expect(carousel.page, closeTo(firstPhysicalPage + step, .01));
      expect(
        find.byKey(ValueKey('onboarding-dot-${step % 4}')),
        findsOneWidget,
      );
      await capture(
        step < 4 ? 'onboarding-${step + 1}' : 'onboarding-loop-${step % 4 + 1}',
      );
    }
    await tester.drag(find.byType(PageView), const Offset(380, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(onboarding.page, 0);
    await capture('onboarding-manual-back');
    await awaitSlide(1);
    await tester.drag(find.byType(PageView), const Offset(-380, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(onboarding.page, 2);
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(onboarding.page, 3);
    expect(find.text('Continue'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await capture('welcome');
    await tester.tap(find.text('I already have an account'));
    await capture('sign-in');
    await tester.enterText(
      find.byKey(const ValueKey('field-Email Address')),
      QaCredentials.email,
    );
    await tester.enterText(
      find.byKey(const ValueKey('field-Password')),
      QaCredentials.password,
    );
    await tester.tap(find.byType(PasswordVisibilityButton));
    await tester.pump();
    await capture('sign-in-password-visible');
    await tester.tap(find.byType(PasswordVisibilityButton));
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await capture('home');
    expect(deps.session.isAuthenticated, true);
    await tester.tap(find.byKey(const ValueKey('landowner-tab-1')));
    await capture('properties');
    await tester.enterText(
      find.byKey(const ValueKey('property-search')),
      'Ridge',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('landowner-tab-2')));
    await tester.pumpAndSettle();
    expect(find.byType(EarningsScreen), findsOneWidget);
    await capture('earnings-via-tab');
    await tester.tap(find.byKey(const ValueKey('landowner-tab-3')));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    await capture('profile-via-tab');
    await tester.tap(find.byKey(const ValueKey('landowner-tab-1')));
    await tester.pumpAndSettle();
    expect(find.text('Ridge'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('property-search')), '');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.tap(find.byKey(const ValueKey('landowner-tab--1')));
    await capture('property-basics');
    Future<void> tapVisible(Finder target) async {
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pump();
      if (find.text('Landowner Portal').evaluate().isNotEmpty) {
        await tester.pump(const Duration(milliseconds: 700));
      }
      await tester.pumpAndSettle();
    }

    final type = find.byKey(const ValueKey('type-selection-field'));
    await tapVisible(type);
    await capture('property-type');
    await tester.tap(find.byKey(const ValueKey('selection-sheet-close')));
    await tester.pumpAndSettle();
    await tapVisible(type);
    await tester.tap(find.byKey(const ValueKey('propertyType-0')));
    await tester.pumpAndSettle();
    await tapVisible(find.byKey(const ValueKey('field-Unit')));
    await capture('unit-type');
    await tester.tap(find.byKey(const ValueKey('unit-1')));
    await tester.pumpAndSettle();
    final deeds = find.byKey(const ValueKey('deeds-office-field'));
    await tapVisible(deeds);
    await capture('deeds-office');
    await tester.tap(find.byKey(const ValueKey('deeds-office-0')));
    await tester.pumpAndSettle();
    await tapVisible(deeds);
    expect(
      tester
          .widget<DeedsOfficeSelectionSheet>(
            find.byType(DeedsOfficeSelectionSheet),
          )
          .selected,
      'Cape Town (WC)',
    );
    await capture('deeds-office-selected');
    await tester.tap(find.byKey(const ValueKey('selection-sheet-close')));
    await tester.pumpAndSettle();
    await tapVisible(deeds);
    await binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(DeedsOfficeSelectionSheet), findsNothing);
    for (final field in [
      ('Property Name', 'Native journey property'),
      ('Property number', '21'),
      ('Property Size', '1.4'),
    ]) {
      final target = find.byKey(ValueKey('field-${field.$1}'));
      await tester.ensureVisible(target);
      await tester.enterText(target, field.$2);
    }
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tapVisible(find.widgetWithText(AppButton, 'Continue'));
    expect(
      tester.widget<SubmissionScreen>(find.byType(SubmissionScreen)).step,
      2,
    );
    final draftId = tester
        .widget<SubmissionScreen>(find.byType(SubmissionScreen))
        .store
        .draft
        .id;
    await capture('submission-location');
    await tester.tap(find.text('Save & Exit'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('landowner-tab-1')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('property-search')),
      'Native journey',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tapVisible(find.text('Native journey property'));
    expect(
      tester
          .widget<SubmissionScreen>(find.byType(SubmissionScreen))
          .store
          .draft
          .id,
      draftId,
    );
    expect(
      tester.widget<SubmissionScreen>(find.byType(SubmissionScreen)).step,
      2,
    );
    await capture('submission-resumed');
    await binding.handlePopRoute();
    await tester.pumpAndSettle();
    router.go('/home');
    await tester.pumpAndSettle();
    final signedInUser = deps.session.user!;
    deps.session.signOut();
    router.go('/forgot-password');
    await capture('recovery-email');
    final recovery = tester
        .widget<RecoveryScreen>(find.byType(RecoveryScreen))
        .store;
    recovery.setEmail('landowner@example.test');
    await recovery.submit();
    await capture('recovery-code');
    recovery.setCode('000000');
    await recovery.submit();
    await capture('recovery-code-error');
    recovery.setCode('123456');
    await recovery.submit();
    await capture('recovery-password');
    deps.session.signIn(signedInUser);
    router.go('/home');
    await tester.pumpAndSettle();
    for (final item in [
      ('properties', '/properties'),
      ('earnings', '/earnings'),
      ('notifications', '/notifications'),
      ('notification-detail', '/notifications/approved'),
      ('support-chat', '/support/chat'),
      ('property-detail', '/properties/ridge-live'),
      for (var step = 1; step <= 9; step++)
        ('submit-$step', '/submit/$step?draft=marula-draft'),
      ('profile', '/profile'),
      ('edit-profile', '/profile/edit'),
      ('payout', '/profile/payout'),
      ('new-payout', '/profile/payout/new'),
      ('notification-preferences', '/profile/notifications'),
      ('language', '/profile/language'),
      ('security', '/profile/security'),
      ('password', '/profile/security/password'),
      ('pin', '/profile/security/pin'),
      ('biometrics', '/profile/security/biometrics'),
      ('devices', '/profile/security/devices'),
      ('two-factor', '/profile/security/2fa'),
      ('two-factor-sms', '/profile/security/2fa/sms'),
      ('two-factor-app', '/profile/security/2fa/app'),
      ('help', '/profile/help'),
      ('about', '/profile/about'),
      ('privacy', '/profile/privacy'),
      ('terms', '/profile/terms'),
    ]) {
      router.go(item.$2);
      await capture(item.$1);
    }
    router.go('/home');
    await tester.pumpAndSettle();
    final landownerHome = tester
        .widget<HomeScreen>(find.byType(HomeScreen))
        .store;
    final userBeforeSwitch = deps.session.user;
    await tapVisible(find.byTooltip('Switch experience'));
    await capture('experience-switch');
    await tapVisible(find.text('Investor'));
    expect(deps.session.experience, Experience.investor);
    expect(find.byType(InvestorHomeScreen), findsOneWidget);
    await capture('investor-after-landowner');
    await tapVisible(find.bySemanticsLabel('Switch experience'));
    await tapVisible(find.text('Landowner'));
    expect(deps.session.experience, Experience.landowner);
    expect(deps.session.user, same(userBeforeSwitch));
    expect(
      tester.widget<HomeScreen>(find.byType(HomeScreen)).store,
      same(landownerHome),
    );
    await capture('landowner-returned');
    final submission = SubmissionStore(
      deps.container<LandownerRepository>(),
      'marula-draft',
    );
    submission.addDocument('identity');
    submission.addDocument('title');
    submission.addDocument('rates');
    submission.update(submission.draft.copyWith(accepted: true));
    submission.save();
    submission.dispose();
    unawaited(router.push('/submit/9?draft=marula-draft'));
    await capture('submit-review-ready');
    await tapVisible(find.widgetWithText(AppButton, 'Continue'));
    await capture('submit-success');
    await tester.tap(find.text('Track this  submission'));
    await capture('properties-after-submit');
    expect(tester.takeException(), isNull);
    router.go('/home');
    await tester.pumpAndSettle();
    final boundary =
        captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final rendered = await boundary.toImage(pixelRatio: 1);
    final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
    binding.reportData ??= <String, dynamic>{};
    binding.reportData!['logicalSize'] = {
      'width': rendered.width,
      'height': rendered.height,
      'pngBytes': bytes!.lengthInBytes,
    };
    binding.reportData!['platform'] = defaultTargetPlatform.name;
    rendered.dispose();
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    await deps.dispose();
  });
}
