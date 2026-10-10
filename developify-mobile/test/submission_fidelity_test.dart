import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/features/landowner/domain/landowner_repository.dart';
import 'package:developify_mobile/features/landowner/domain/submission_draft.dart';
import 'package:developify_mobile/features/landowner/presentation/submission_screen.dart';
import 'package:developify_mobile/features/landowner/presentation/widgets/upload_tile.dart';
import 'package:developify_mobile/features/landowner/presentation/widgets/submission_success_sheet.dart';
import 'package:developify_mobile/features/landowner/presentation/widgets/submission_selection.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'helpers/fidelity_capture.dart';
import 'helpers/fonts.dart';

const _photos = [
  LocalAttachment(id: 'photo-0', name: 'North boundary'),
  LocalAttachment(id: 'photo-1', name: 'South boundary'),
  LocalAttachment(id: 'photo-2', name: 'East boundary'),
  LocalAttachment(id: 'photo-3', name: 'West boundary'),
];
const _documents = {
  'title': LocalAttachment(id: 'title', name: 'TD_Erf4412_2019.pdf'),
  'rates': LocalAttachment(id: 'rates', name: 'CityJoburg_Rates_May.p'),
  'zoning': LocalAttachment(id: 'zoning', name: 'TD_Erf4412_2019.pdf'),
  'identity': LocalAttachment(id: 'identity', name: 'Themba_ID_Certified.pdf'),
  'valuation': LocalAttachment(id: 'valuation', name: 'Valuation_Report.pdf'),
};
SubmissionDraft _draft(
  String id,
  int step, {
  bool filled = true,
  bool trust = false,
  bool accepted = false,
}) => SubmissionDraft(
  id: id,
  step: step,
  name: filled ? 'Marula Heights' : '',
  legalDescription: 'Malibongwe Erf 4412',
  propertyNumber: filled ? '12' : '',
  propertyType: filled ? 'Vacant land' : '',
  size: filled ? '1.4' : '',
  unit: filled ? 'Hectares' : '',
  deedsOffice: filled ? 'Johannesburg' : '',
  address: filled ? 'Malibongwe Drive, off Republic Rd' : '',
  town: filled ? 'Randburg' : '',
  city: filled ? 'Johannesburg' : '',
  province: filled ? 'GP' : '',
  postalCode: filled ? '2194' : '',
  country: filled ? 'South Africa' : '',
  latitude: filled ? '-26.076245' : '',
  longitude: filled ? '27.958114' : '',
  photos: filled ? _photos : [],
  documents: filled
      ? {
          ..._documents,
          if (step == 7 && !trust)
            'co-owner': const LocalAttachment(
              id: 'co-owner',
              name: 'co-owner.pdf',
            ),
          if (trust)
            for (final key in [
              'trustees',
              'trust-resolution',
              'trust-mandate',
              'trust-deed',
            ])
              key: LocalAttachment(id: key, name: '$key.pdf'),
        }
      : step == 8
      ? {'valuation': _documents['valuation']!}
      : {},
  entity: trust ? EntityType.trust : EntityType.individual,
  coOwners: filled && step == 7 && !trust,
  deal: filled && step != 8 ? 'Long - term lease' : '',
  price: filled ? 'R 4,800,000' : '',
  monthlyLease: filled ? 'R 28,000' : '',
  hasValuation: step == 8 || filled,
  accepted: accepted,
);

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  setUp(
    () => binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true),
  );
  tearDown(() {
    binding.platformDispatcher.clearAccessibilityFeaturesTestValue();
    binding.platformDispatcher.clearTextScaleFactorTestValue();
    final view = binding.platformDispatcher.implicitView!;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
    view.resetPadding();
  });
  void viewport(WidgetTester tester, double height, [double width = 393]) {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 56, bottom: 34);
  }

  const user = AppUser(
    id: 'owner',
    name: 'Babatunde Yusuf',
    email: 'owner@example.test',
  );

  testWidgets('Submission authored states and long-form layouts', (
    tester,
  ) async {
    viewport(tester, 852);
    final deps = await AppDependencies.create(
      environment: const AppEnvironment(mockDelay: Duration.zero),
    );
    deps.session.signIn(user);
    final repo = deps.container<LandownerRepository>();
    final router = createAppRouter(deps, initialLocation: '/home');
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: DevelopifyApp(dependencies: deps, router: router),
      ),
    );
    await tester.pumpAndSettle();
    for (final (frame, step, height, filled, trust) in [
      ('18155', 1, 852.0, true, false),
      ('15501', 2, 1047.0, false, false),
      ('17735', 2, 1047.0, true, false),
      ('15589', 3, 852.0, false, false),
      ('17667', 3, 852.0, true, false),
      ('15681', 4, 852.0, false, false),
      ('15783', 4, 852.0, true, false),
      ('15732', 5, 852.0, false, false),
      ('15849', 5, 852.0, true, false),
      ('15915', 6, 852.0, false, false),
      ('15990', 6, 852.0, true, false),
      ('16070', 7, 817.0, false, false),
      ('16219', 7, 817.0, true, false),
      ('16403', 7, 817.0, true, false),
      ('16136', 7, 1000.0, false, true),
      ('16302', 7, 1000.0, true, true),
      ('16486', 8, 1205.0, false, false),
      ('16610', 8, 1205.0, true, false),
      ('16734', 9, 1607.0, true, false),
      ('16960', 9, 1607.0, true, false),
    ]) {
      viewport(tester, height);
      repo.saveDraft(
        _draft(
          frame,
          step,
          filled: filled,
          trust: trust,
          accepted: frame == '16960',
        ),
      );
      if (frame == '18155') {
        repo.saveDraft(
          repo
              .readDraft(frame)
              .copyWith(
                propertyNumber: '21',
                propertyType: 'Existing building)',
              ),
        );
      }
      router.go('/submit/$step?draft=$frame');
      await tester.pumpAndSettle();
      expect(find.text('Step $step of 9'), findsOneWidget);
      await captureFidelity(tester, key, '4105-$frame');
      expect(tester.takeException(), isNull, reason: frame);
      if (step == 7) expect(find.text('70%'), findsOneWidget);
      if (step == 9) expect(find.text('90%'), findsOneWidget);
    }
    viewport(tester, 874, 402);
    await tester.pumpAndSettle();
    await captureFidelity(tester, key, '4105-17188');
    viewport(tester, 852, 402);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(AppButton, 'Continue'));
    await tester.tap(find.widgetWithText(AppButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(SubmissionSuccessSheet), findsOneWidget);
    await captureFidelity(tester, key, '4105-17416');
    viewport(tester, 780, 360);
    binding.platformDispatcher.textScaleFactorTestValue = 1.3;
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Back to dahsboard'));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Back to dahsboard'));
    await tester.pumpAndSettle();
    expect(find.text('Good Morning!'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    await deps.dispose();
  });

  testWidgets(
    'Submission skip, validation, removal, review edits and draft persistence',
    (tester) async {
      viewport(tester, 852);
      final deps = await AppDependencies.create(
        environment: const AppEnvironment(mockDelay: Duration.zero),
      );
      deps.session.signIn(user);
      final repo = deps.container<LandownerRepository>();
      repo.saveDraft(
        _draft(
          'interaction',
          4,
        ).copyWith(documents: {'valuation': _documents['valuation']!}),
      );
      final router = createAppRouter(
        deps,
        initialLocation: '/submit/4?draft=interaction',
      );
      await tester.pumpWidget(
        DevelopifyApp(dependencies: deps, router: router),
      );
      await tester.pumpAndSettle();
      SubmissionScreen screen() =>
          tester.widget<SubmissionScreen>(find.byType(SubmissionScreen));
      for (var step = 4; step <= 6; step++) {
        expect(screen().store.step, step);
        expect(
          tester
              .widget<AppButton>(find.widgetWithText(AppButton, 'Continue'))
              .onPressed,
          isNull,
        );
        await tester.tap(find.text('Skip for now'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.widgetWithText(AppButton, 'Continue'));
      await tester.pumpAndSettle();
      expect(screen().store.errors['identity'], isNotNull);
      screen().store.addDocument('identity');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Add a co - owner'));
      await tester.tap(find.text('Add a co - owner'));
      await tester.pumpAndSettle();
      expect(screen().store.draft.coOwners, true);
      screen().store.removeDocument('co-owner');
      await tester.pumpAndSettle();
      expect(screen().store.draft.coOwners, false);
      await tester.tap(find.widgetWithText(AppButton, 'Continue'));
      await tester.pumpAndSettle();
      expect(screen().store.step, 8);
      screen().store.setField('monthly', 'Rbad');
      expect(screen().store.validateStep(8)['monthly'], isNotNull);
      screen().store.setField('monthly', 'R28,000');
      screen().store.setField('price', 'R4,800,000');
      expect(screen().store.validateStep(8), isEmpty);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(SubmissionValuationSwitch));
      await tester.tap(find.byType(SubmissionValuationSwitch));
      await tester.pumpAndSettle();
      expect(screen().store.draft.hasValuation, false);
      await tester.tap(find.byType(SubmissionValuationSwitch));
      await tester.pumpAndSettle();
      expect(screen().store.draft.documents.containsKey('valuation'), true);
      await tester.tap(find.widgetWithText(AppButton, 'Continue'));
      await tester.pumpAndSettle();
      expect(screen().store.step, 9);
      await tester.tap(find.text('Edit').first);
      await tester.pumpAndSettle();
      expect(screen().review, true);
      screen().store.setField('name', 'Updated property');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(screen().store.draft.name, 'Updated property');
      await tester.tap(find.text('Save & Exit'));
      await tester.pumpAndSettle();
      expect(repo.readDraft('interaction').name, 'Updated property');
      router.go('/submit/3?draft=interaction');
      await tester.pumpAndSettle();
      await tester.longPress(find.byType(DashedPhotoTile).first);
      await tester.pumpAndSettle();
      expect(screen().store.draft.photos.length, 3);
      expect(screen().store.validateStep(3)['photos'], isNotNull);
      await tester.tap(find.byType(DashedPhotoTile).last);
      await tester.pumpAndSettle();
      expect(screen().store.draft.photos.length, 4);
      viewport(tester, 780, 360);
      binding.platformDispatcher.textScaleFactorTestValue = 1.3;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await deps.dispose();
    },
  );
}
