import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/features/investor/data/kyc_demo_fixtures.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_plan.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_repository.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_validation.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

typedef InvestorChecklistFrame = ({
  EntityType entity,
  String checked,
  String verified,
  double height,
  bool approved,
});

const Map<String, InvestorChecklistFrame> investorChecklistFrames = {
  '51540': (
    entity: EntityType.individual,
    checked: '010100',
    verified: '010100',
    height: 852,
    approved: false,
  ),
  '57853': (
    entity: EntityType.trust,
    checked: '000000',
    verified: '000000',
    height: 1118,
    approved: false,
  ),
  '57973': (
    entity: EntityType.trust,
    checked: '000000',
    verified: '000000',
    height: 1118,
    approved: false,
  ),
  '50308': (
    entity: EntityType.individual,
    checked: '010100',
    verified: '010100',
    height: 1147.0,
    approved: false,
  ),
  '50419': (
    entity: EntityType.individual,
    checked: '010100',
    verified: '010100',
    height: 1148.0,
    approved: false,
  ),
  '50971': (
    entity: EntityType.individual,
    checked: '111100',
    verified: '111100',
    height: 1127.0,
    approved: false,
  ),
  '51080': (
    entity: EntityType.individual,
    checked: '111100',
    verified: '111100',
    height: 1127.0,
    approved: false,
  ),
  '50750': (
    entity: EntityType.individual,
    checked: '110100',
    verified: '110100',
    height: 852.0,
    approved: false,
  ),
  '50860': (
    entity: EntityType.individual,
    checked: '010100',
    verified: '010100',
    height: 1148.0,
    approved: false,
  ),
  '51652': (
    entity: EntityType.individual,
    checked: '111111',
    verified: '111111',
    height: 1144.0,
    approved: true,
  ),
  '51759': (
    entity: EntityType.individual,
    checked: '111111',
    verified: '111111',
    height: 852.0,
    approved: true,
  ),
  '50530': (
    entity: EntityType.individual,
    checked: '110100',
    verified: '110100',
    height: 852.0,
    approved: false,
  ),
  '50640': (
    entity: EntityType.individual,
    checked: '110100',
    verified: '110100',
    height: 852.0,
    approved: false,
  ),
  '51194': (
    entity: EntityType.individual,
    checked: '111110',
    verified: '111100',
    height: 1127.0,
    approved: false,
  ),
  '51302': (
    entity: EntityType.individual,
    checked: '111110',
    verified: '111100',
    height: 1127.0,
    approved: false,
  ),
  '55075': (
    entity: EntityType.trust,
    checked: '000000',
    verified: '000000',
    height: 1118.0,
    approved: false,
  ),
  '55195': (
    entity: EntityType.trust,
    checked: '000000',
    verified: '000000',
    height: 1118.0,
    approved: false,
  ),
  '55315': (
    entity: EntityType.trust,
    checked: '100000',
    verified: '010100',
    height: 1118.0,
    approved: false,
  ),
  '55434': (
    entity: EntityType.trust,
    checked: '100000',
    verified: '010100',
    height: 1118.0,
    approved: false,
  ),
  '55553': (
    entity: EntityType.trust,
    checked: '110000',
    verified: '010100',
    height: 1118.0,
    approved: false,
  ),
  '55671': (
    entity: EntityType.trust,
    checked: '110000',
    verified: '010100',
    height: 1118.0,
    approved: false,
  ),
  '78683': (
    entity: EntityType.company,
    checked: '000000',
    verified: '000000',
    height: 1118.0,
    approved: false,
  ),
  '78803': (
    entity: EntityType.company,
    checked: '000000',
    verified: '000000',
    height: 1118.0,
    approved: false,
  ),
  '79161': (
    entity: EntityType.company,
    checked: '111000',
    verified: '000000',
    height: 1118.0,
    approved: false,
  ),
  '79278': (
    entity: EntityType.company,
    checked: '111100',
    verified: '000000',
    height: 1118.0,
    approved: false,
  ),
  '79394': (
    entity: EntityType.company,
    checked: '111100',
    verified: '000000',
    height: 1118.0,
    approved: false,
  ),
  '79510': (
    entity: EntityType.company,
    checked: '111110',
    verified: '000000',
    height: 1118.0,
    approved: false,
  ),
  '79854': (
    entity: EntityType.company,
    checked: '111000',
    verified: '000000',
    height: 1118.0,
    approved: false,
  ),
  '79971': (
    entity: EntityType.company,
    checked: '100000',
    verified: '000000',
    height: 1118.0,
    approved: false,
  ),
  '78923': (
    entity: EntityType.company,
    checked: '110000',
    verified: '000000',
    height: 1118.0,
    approved: false,
  ),
  '79041': (
    entity: EntityType.company,
    checked: '000000',
    verified: '000000',
    height: 1118.0,
    approved: false,
  ),
  '79625': (
    entity: EntityType.company,
    checked: '111110',
    verified: '000000',
    height: 1118.0,
    approved: false,
  ),
  '79740': (
    entity: EntityType.company,
    checked: '111111',
    verified: '000000',
    height: 1118.0,
    approved: false,
  ),
  '83317': (
    entity: EntityType.stokvel,
    checked: '100000',
    verified: '000000',
    height: 1118.0,
    approved: false,
  ),
  '83438': (
    entity: EntityType.stokvel,
    checked: '110000',
    verified: '000000',
    height: 1118.0,
    approved: false,
  ),
  '82344': (
    entity: EntityType.stokvel,
    checked: '000000',
    verified: '000000',
    height: 1118.0,
    approved: false,
  ),
  '82464': (
    entity: EntityType.stokvel,
    checked: '000000',
    verified: '000000',
    height: 1118.0,
    approved: false,
  ),
  '82824': (
    entity: EntityType.stokvel,
    checked: '000000',
    verified: '000000',
    height: 1118.0,
    approved: false,
  ),
  '82944': (
    entity: EntityType.stokvel,
    checked: '111000',
    verified: '000000',
    height: 1118.0,
    approved: false,
  ),
  '83067': (
    entity: EntityType.stokvel,
    checked: '111110',
    verified: '000000',
    height: 1118.0,
    approved: false,
  ),
  '83192': (
    entity: EntityType.stokvel,
    checked: '111110',
    verified: '000000',
    height: 1118.0,
    approved: false,
  ),
  '82584': (
    entity: EntityType.stokvel,
    checked: '000000',
    verified: '000000',
    height: 1118.0,
    approved: false,
  ),
  '82704': (
    entity: EntityType.stokvel,
    checked: '000000',
    verified: '000000',
    height: 1118.0,
    approved: false,
  ),
};

Iterable<(String, String, double, bool, MockScenario)>
get investorChecklistFrameCases => [
  for (final entry in investorChecklistFrames.entries)
    if (!const {'50308', '55075', '78683', '82344'}.contains(entry.key))
      (
        entry.key,
        '/investor/kyc/${entry.value.entity.name}/overview',
        entry.value.height,
        true,
        entry.value.approved
            ? MockScenario.success
            : MockScenario.incompleteKyc,
      ),
];

Future<void> seedInvestorChecklistFrame(
  KycRepository repository,
  String node,
) async {
  final frame = investorChecklistFrames[node];
  if (frame == null) return;
  final entity = frame.entity;
  final plan = KycPlans.steps(entity);
  final rows = switch (entity) {
    EntityType.individual => [
      'identity',
      'selfie',
      'address',
      'contact',
      'tax',
      'funds',
    ],
    EntityType.trust => [
      'deed',
      'authority',
      'resolution',
      'trustees',
      'beneficiaries',
      'funds',
    ],
    EntityType.company => [
      'registration',
      'moi',
      'shareholders',
      'resolution',
      'directors',
      'funds',
    ],
    EntityType.stokvel => [
      'constitution',
      'resolution',
      'officers',
      'register',
      'bank',
      'funds',
    ],
  };
  KycDraft requireSuccess(Result<KycDraft> result) => switch (result) {
    Success(:final value) => value,
    Failure(:final error) => throw StateError(
      'Checklist $node: ${error.message} ${error.fields}',
    ),
  };
  Future<KycDraft> current() async =>
      requireSuccess(await repository.load(entity));
  if (frame.approved) {
    final draft = await current();
    if (plan.any((step) => !draft.verifiedSteps.contains(step.id))) {
      throw StateError('Checklist $node requires an approved application.');
    }
    return;
  }
  final ready = {
    for (final (index, step) in rows.indexed)
      if (step != 'contact' &&
          (frame.checked[index] == '1' || frame.verified[index] == '1'))
        step,
  };
  final approved = {
    for (final (index, step) in rows.indexed)
      if (step != 'contact' && frame.verified[index] == '1') step,
  };
  final fixture = KycDemoFixtures.verified(entity, DateTime(2026, 7, 22));
  final draft = await current();
  final values = {
    ...draft.values,
    for (final step in plan.where((step) => ready.contains(step.id)))
      for (final field in step.fields)
        if (fixture.values.containsKey(field.key))
          field.key: fixture.values[field.key]!,
  };
  requireSuccess(repository.save(draft.copyWith(values: values)));
  for (final slot
      in plan
          .where((step) => ready.contains(step.id))
          .expand((step) => step.documents)) {
    if (draft.documents.containsKey(slot.key)) continue;
    requireSuccess(
      await repository.upload(
        entity,
        slot.key,
        name: '${slot.key}.pdf',
        bytes: 120 * 1024,
        mimeType: 'application/pdf',
      ),
    );
  }
  final roles = plan
      .where((step) => ready.contains(step.id))
      .expand((step) => step.memberRoles)
      .toSet();
  for (final role in roles) {
    final checked =
        ready.contains('trustees') ||
        ready.contains('directors') ||
        ready.contains('officers');
    final count = role == KycMemberRole.trustee ? 3 : 1;
    for (var index = 0; index < count; index++) {
      requireSuccess(
        repository.saveMember(
          entity,
          KycMember(
            id: 'checklist-${role.name}-$index',
            firstName: ['Adaeze', 'Sipho', 'Thandi'][index],
            lastName: 'Okoye',
            role: role,
            identityNumber: 'mock-${role.name}-$index',
            email: '${role.name}.$index@example.test',
            birthDate: '2000-02-02',
            relationship: role == KycMemberRole.beneficiary ? 'Daughter' : '',
            shareBasisPoints:
                role == KycMemberRole.shareholder ||
                    role == KycMemberRole.beneficiary
                ? 10000
                : 0,
            identityVerified: checked,
            addressVerified: checked,
          ),
        ),
      );
    }
  }
  if (ready.contains('resolution') && entity != EntityType.stokvel) {
    requireSuccess(await repository.requestResolutionSignatures(entity));
    final resolution = plan.firstWhere((step) => step.id == 'resolution');
    for (final member in (await current()).members.where(
      resolution.includesMember,
    )) {
      requireSuccess(
        await repository.simulateResolutionSignature(entity, member.id),
      );
    }
  }
  final completed = requireSuccess(repository.save(await current()));
  for (final id in ready) {
    final errors = KycValidation.step(
      completed,
      plan.firstWhere((step) => step.id == id),
    );
    if (errors.isNotEmpty || !completed.completedSteps.contains(id)) {
      throw StateError('Checklist $node cannot complete $id: $errors');
    }
  }
  for (final id in approved) {
    requireSuccess(await repository.simulateRequirementApproval(entity, id));
  }
}
