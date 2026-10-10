import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/features/investor/data/kyc_demo_fixtures.dart';
import 'package:developify_mobile/features/investor/data/mock_kyc_repository.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_plan.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_repository.dart';
import 'package:developify_mobile/features/investor/presentation/screens/kyc_screen.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'package:developify_mobile/core/errors/result.dart';

Future<void> seedInvestorIdentityFrame(
  KycRepository repository,
  String node,
) async {
  if (!const {'47906', '48414', '49316', '51410'}.contains(node)) return;
  const entity = EntityType.individual;
  final draft = (await repository.load(entity) as Success<KycDraft>).value;
  repository.save(
    draft.copyWith(
      values: {...draft.values, 'idType': 'International passport'},
    ),
  );
  for (final key in [
    'identityFront',
    'identityBack',
    if (node == '51410') 'selfie',
  ]) {
    final result = await repository.upload(
      entity,
      key,
      name: '$key.jpg',
      bytes: 120 * 1024,
      mimeType: 'image/jpeg',
    );
    if (result is! Success<KycDraft>) {
      throw StateError('Unable to seed identity preview.');
    }
  }
}

Future<void> showInvestorDocumentFrame(
  WidgetTester tester,
  AppDependencies dependencies,
  String node,
) async {
  if (node == '47906') {
    final store = tester.widget<KycScreen>(find.byType(KycScreen)).store;
    unawaited(store.simulateIdentityCheck());
    await tester.pump(const Duration(milliseconds: 100));
    expect(store.busy, isTrue);
    return;
  }
  const pending = {'46883', '47442', '47514'};
  const failed = {'47290', '47366'};
  const completed = {'46980', '47076', '47586', '47657'};
  if (!pending.contains(node) &&
      !failed.contains(node) &&
      !completed.contains(node)) {
    return;
  }
  final store = tester.widget<KycScreen>(find.byType(KycScreen)).store;
  final bank = {'46883', '46980', '47076'}.contains(node);
  if (bank) {
    const values = KycDemoFixtures.naturalProofOfAccount;
    for (final field
        in KycPlans.naturalPerson
            .firstWhere((step) => step.id == 'bank')
            .fields) {
      store.edit(field.key, values[field.key]!);
    }
  }
  if (failed.contains(node)) {
    (dependencies.container<KycRepository>() as MockKycRepository).behavior
        .failNext();
  }
  final key = bank ? 'bankProof' : 'addressProof';
  final operation = store.upload(
    key,
    name: bank
        ? completed.contains(node)
              ? 'Electricity Bill.pdf'
              : 'Account Confirmation.pdf'
        : failed.contains(node)
        ? 'Electricity bill.pdf'
        : 'Electricity Bill.pdf',
    bytes: 120 * 1024,
    mimeType: 'application/pdf',
  );
  if (pending.contains(node)) {
    unawaited(operation);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 200));
    expect(store.documentUploads[key]!.status, KycUploadStatus.uploading);
    expect(store.canContinue, isFalse);
  } else {
    await tester.pumpAndSettle();
    expect(await operation, !failed.contains(node));
    if (failed.contains(node)) {
      expect(store.documentUploads[key]!.status, KycUploadStatus.failed);
      expect(store.canContinue, isFalse);
    } else {
      expect(store.documentUploads, isEmpty);
      expect(store.canContinue, isTrue);
    }
  }
}
