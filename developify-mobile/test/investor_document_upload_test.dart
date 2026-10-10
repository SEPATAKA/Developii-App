import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/features/investor/data/mock_kyc_repository.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_repository.dart';
import 'package:developify_mobile/features/investor/presentation/screens/kyc_screen.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'helpers/fonts.dart';

void main() {
  setUpAll(loadAppFonts);
  for (final width in [360.0, 393.0, 430.0]) {
    testWidgets(
      'Document upload cancels and retries at $width with enlarged text',
      (tester) async {
        tester.view.physicalSize = Size(width, 852);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 56, bottom: 34);
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final dependencies = await AppDependencies.create(
          environment: const AppEnvironment(
            mockDelay: Duration(seconds: 2),
            mockScenario: MockScenario.incompleteKyc,
          ),
        );
        dependencies.session.signIn(
          const AppUser(
            id: 'document-upload',
            name: 'Babatunde Yusuf',
            email: 'investor@example.test',
          ),
          experience: Experience.investor,
        );
        final router = createAppRouter(
          dependencies,
          initialLocation: '/investor/kyc/individual/address',
        );
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox());
          router.dispose();
          await tester.runAsync(dependencies.dispose);
        });
        await tester.pumpWidget(
          DevelopifyApp(dependencies: dependencies, router: router),
        );
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        final store = tester.widget<KycScreen>(find.byType(KycScreen)).store;
        Future<void> start() async {
          final upload = find.bySemanticsLabel(
            RegExp('^Choose a file for Upload'),
          );
          await tester.scrollUntilVisible(upload, 200);
          await tester.tap(upload);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Choose Document'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.text('Uploading...'), findsOneWidget);
          expect(
            tester
                .widget<AppButton>(
                  find.byWidgetPredicate(
                    (widget) =>
                        widget is AppButton && widget.label == 'Continue',
                  ),
                )
                .onPressed,
            isNull,
          );
          expect(store.draft!.documents.containsKey('addressProof'), isFalse);
        }

        await start();
        final cancel = find.bySemanticsLabel('Cancel document upload');
        await tester.ensureVisible(cancel);
        await tester.tap(cancel);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        expect(store.documentUploads, isEmpty);
        expect(store.draft!.documents.containsKey('addressProof'), isFalse);
        final repository =
            dependencies.container<KycRepository>() as MockKycRepository;
        repository.behavior.failNext();
        await start();
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(find.text('Failed'), findsOneWidget);
        expect(store.draft!.documents.containsKey('addressProof'), isFalse);
        final retry = find.text('Try Again');
        await tester.ensureVisible(retry);
        await tester.tap(retry);
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Uploading...'), findsOneWidget);
        expect(store.canContinue, isFalse);
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(find.text('Completed'), findsOneWidget);
        expect(store.canContinue, isTrue);
        expect(store.documentUploads, isEmpty);
        expect(
          store.draft!.documents['addressProof']!.name,
          'addressProof.pdf',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
