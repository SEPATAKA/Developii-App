import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/presentation/stores/kyc_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_fields.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_form_panel.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_members.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_resolution_members.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_supporting_documents.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

class EntityKycForm extends StatelessWidget {
  const EntityKycForm({
    super.key,
    required this.store,
    required this.onUpload,
    required this.onDelete,
  });
  final KycStore store;
  final ValueChanged<KycDocumentDefinition> onUpload;
  final ValueChanged<KycDocumentDefinition> onDelete;

  @override
  Widget build(BuildContext context) {
    final step = store.step!;
    final rows = _fieldRows();
    final authority =
        store.entity == EntityType.trust && step.id == 'authority';
    final trustResolution =
        store.entity == EntityType.trust && step.id == 'resolution';
    final compactPanel =
        store.entity == EntityType.company && step.id == 'moi' ||
        store.entity == EntityType.stokvel && step.id == 'bank';
    return Padding(
      padding: EdgeInsets.only(
        top:
            (step.id == 'funds' && store.entity != EntityType.stokvel ? 23 : 27)
                .w,
        bottom: 24.w,
      ),
      child: Column(
        key: ValueKey('${store.entity.name}-${step.id}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (step.description.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.only(left: compactPanel ? 1.w : 0),
              child: Text(
                step.description,
                style: AppTextStyles.text(16, color: AppColors.muted),
              ),
            ),
            SizedBox(
              height:
                  (step.id == 'funds' && store.entity == EntityType.company
                          ? 23
                          : store.entity == EntityType.trust
                          ? step.id == 'funds'
                                ? 23
                                : step.id == 'trustees'
                                ? 20
                                : authority
                                ? 31
                                : trustResolution
                                ? 34
                                : 32
                          : step.id == 'shareholders'
                          ? 36
                          : 27)
                      .w,
            ),
          ],
          if (!['trustees', 'shareholders', 'directors'].contains(step.id))
            Text(
              step.section,
              style: AppTextStyles.text(
                14,
                weight: FontWeight.w500,
                height: authority ? 22 / 14 : 1.2,
              ),
            ),
          if (!['trustees', 'shareholders', 'directors'].contains(step.id))
            SizedBox(
              height:
                  (authority
                          ? 8
                          : compactPanel || trustResolution
                          ? 10
                          : 12)
                      .w,
            ),
          if (step.id == 'funds')
            ..._funds(context)
          else if (authority)
            KycFormPanel(
              spacing: 0,
              padding: EdgeInsets.fromLTRB(19.w, 22.w, 19.w, 7.w),
              children: [
                _field('authorityIssued'),
                SizedBox(height: 21.w),
                _field('issuingOffice'),
                SizedBox(height: 14.w),
                _field('trusteeCount'),
                SizedBox(height: 2.w),
                Padding(
                  padding: EdgeInsets.only(right: 2.w),
                  child: _field('reissued'),
                ),
              ],
            )
          else if (trustResolution)
            KycFormPanel(
              spacing: 0,
              padding: EdgeInsets.fromLTRB(19.w, 22.w, 19.w, 19.w),
              children: [
                _field('resolutionDate'),
                SizedBox(height: 21.w),
                _field('meetingLocation'),
                SizedBox(height: 14.w),
                _field('investmentCap'),
                SizedBox(height: 14.w),
                _field('signatory'),
              ],
            )
          else if (store.entity == EntityType.trust && step.id == 'deed')
            KycFormPanel(
              spacing: 0,
              children: [
                _field('trustName'),
                SizedBox(height: 22.w),
                _row(context, ['trustRegistration', 'trustRegistered']),
                SizedBox(height: 14.w),
                _field('masterOffice'),
                SizedBox(height: 14.w),
                _field('trustType'),
              ],
            )
          else if (compactPanel)
            KycFormPanel(
              spacing: 0,
              padding: EdgeInsets.fromLTRB(
                19.w,
                22.w,
                16.w,
                (step.id == 'moi' ? 9 : 13.6).w,
              ),
              children: [
                for (final (index, keys) in rows.indexed) ...[
                  if (index > 0)
                    SizedBox(
                      height:
                          (index == rows.length - 1
                                  ? step.id == 'moi'
                                        ? 8
                                        : 4
                                  : 16)
                              .w,
                    ),
                  Padding(
                    padding: EdgeInsets.only(
                      right: step.id == 'moi' && index == rows.length - 1
                          ? 9.w
                          : 0,
                    ),
                    child: _row(context, keys),
                  ),
                ],
              ],
            )
          else if (rows.isNotEmpty)
            KycFormPanel(
              spacing: step.id == 'beneficiaries' ? 22 : 16,
              padding:
                  step.id == 'resolution' && store.entity == EntityType.company
                  ? EdgeInsets.fromLTRB(
                      18.w,
                      20.w,
                      18.w,
                      (store.draft!.values['resolutionNotes']?.isNotEmpty ==
                                  true
                              ? 16
                              : 32)
                          .w,
                    )
                  : null,
              children: [for (final keys in rows) _row(context, keys)],
            ),
          if (step.memberRoles.isNotEmpty) ...[
            if (rows.isNotEmpty)
              SizedBox(
                height:
                    (trustResolution
                            ? 21
                            : step.id == 'resolution' &&
                                  store.entity == EntityType.company
                            ? 17
                            : 24)
                        .w,
              ),
            if (step.id == 'resolution')
              KycResolutionMembers(store: store)
            else
              KycMembers(store: store),
          ],
          for (final document in step.documents) ...[
            SizedBox(
              height:
                  (authority
                          ? 24
                          : compactPanel
                          ? 17
                          : step.id == 'resolution' &&
                                store.entity == EntityType.stokvel
                          ? 14
                          : step.id == 'resolution' &&
                                store.entity == EntityType.company
                          ? 17
                          : 20)
                      .w,
            ),
            if (document.multiple)
              KycSupportingDocuments(store: store, definition: document)
            else ...[
              if (_completedBelowPicker(document)) ...[
                _replacementPicker(document, showTitle: true),
                SizedBox(height: 10.w),
              ],
              InvestorDocumentTile(
                centered: true,
                showFileExtension:
                    step.id == 'moi' ||
                    step.id == 'resolution' &&
                        store.entity == EntityType.company,
                showTitle:
                    !_completedBelowPicker(document) &&
                    !((step.id == 'authority' ||
                            step.id == 'registration' ||
                            trustResolution) &&
                        store.draft!.documents[document.key] != null),
                minimumHeight:
                    step.id == 'funds' && store.entity == EntityType.stokvel
                    ? 141
                    : step.id == 'moi' || step.id == 'shareholders'
                    ? 115
                    : step.id == 'resolution' &&
                          store.entity == EntityType.trust
                    ? 167
                    : step.id == 'resolution' &&
                          store.entity == EntityType.company
                    ? 115
                    : step.id == 'bank' || step.id == 'resolution'
                    ? 140
                    : 167,
                title:
                    step.id == 'resolution' &&
                        store.entity == EntityType.stokvel
                    ? 'Upload signed minutes'
                    : step.id == 'resolution' &&
                          store.entity == EntityType.company
                    ? 'Upload'
                    : step.id == 'bank' ||
                          step.id == 'register' ||
                          step.id == 'resolution' ||
                          step.id == 'funds'
                    ? document.title
                    : 'Upload',
                chooseLabel:
                    step.id == 'resolution' &&
                        store.entity == EntityType.stokvel
                    ? document.title
                    : step.id == 'funds' && store.entity == EntityType.trust
                    ? 'Upload supporting documents'
                    : 'Choose a file',
                helperText:
                    step.id == 'funds' && store.entity == EntityType.trust
                    ? 'Statements, sale agreements, donations deed, etc'
                    : 'Ensure your document is in PNG, JPG or PDF with a maximum file size of 5MB.',
                document: store.draft!.documents[document.key],
                uploadAttempt: store.documentUploads[document.key],
                onRetry: store.busy
                    ? null
                    : () => store.retryUpload(document.key),
                onCancel: () => store.cancelUpload(document.key),
                loading: store.uploading == document.key,
                enabled: !store.busy,
                error: store.errors[document.key],
                onChoose: () => onUpload(document),
                onDelete: () => onDelete(document),
              ),
              if (_completedAbovePicker(document)) ...[
                SizedBox(
                  height:
                      (step.id == 'authority'
                              ? 24
                              : step.id == 'registration' || trustResolution
                              ? 20
                              : 10)
                          .w,
                ),
                _replacementPicker(
                  document,
                  showTitle:
                      step.id == 'authority' ||
                      step.id == 'registration' ||
                      trustResolution,
                ),
              ],
            ],
          ],
          if (store.error != null) InlineError(store.error),
        ],
      ),
    );
  }

  bool _completedBelowPicker(KycDocumentDefinition document) =>
      store.draft!.documents[document.key] != null &&
      (store.entity == EntityType.company &&
              const {'moi', 'shareholders'}.contains(store.selectedStep) ||
          store.entity == EntityType.stokvel &&
              store.selectedStep == 'constitution');

  bool _completedAbovePicker(KycDocumentDefinition document) =>
      store.draft!.documents[document.key] != null &&
      (store.entity == EntityType.trust &&
              const {
                'deed',
                'authority',
                'resolution',
              }.contains(store.selectedStep) ||
          store.entity == EntityType.company &&
              const {
                'registration',
                'resolution',
              }.contains(store.selectedStep) ||
          store.entity == EntityType.stokvel && store.selectedStep == 'bank');

  Widget _replacementPicker(
    KycDocumentDefinition document, {
    required bool showTitle,
  }) => InvestorDocumentTile(
    title:
        store.entity == EntityType.trust && store.selectedStep == 'resolution'
        ? document.title
        : 'Upload',
    document: null,
    centered: true,
    showTitle: showTitle,
    minimumHeight: switch ((store.entity, store.selectedStep)) {
      (EntityType.trust, 'deed') => 246,
      (EntityType.company, 'registration') => 167,
      (EntityType.company, _) || (EntityType.stokvel, 'constitution') => 115,
      (EntityType.stokvel, 'bank') => 140,
      _ => 167,
    },
    chooseLabel: 'Choose a file',
    helperText:
        'Ensure your document is in PNG, JPG or PDF with a maximum file size of 5MB.',
    loading: store.uploading == document.key,
    enabled: !store.busy,
    onChoose: () => onUpload(document),
    onDelete: () => onDelete(document),
  );

  List<Widget> _funds(BuildContext context) {
    final fields = [
      for (final field in store.step!.fields)
        if (field.key != 'fundSources') _field(field.key),
    ];
    if (store.entity == EntityType.stokvel) {
      return [
        KycFormPanel(children: fields),
        SizedBox(height: 18.w),
        _field('fundSources'),
      ];
    }
    return [
      _field('fundSources'),
      SizedBox(height: 20.w),
      Text(
        store.entity == EntityType.trust ? 'Capital Snapshot' : 'Financials',
        style: AppTextStyles.text(14, weight: FontWeight.w500, height: 22 / 14),
      ),
      SizedBox(height: 8.w),
      KycFormPanel(spacing: 21, children: fields),
    ];
  }

  List<List<String>> _fieldRows() =>
      switch ((store.entity, store.selectedStep)) {
        (EntityType.trust, 'deed') => [
          ['trustName'],
          ['trustRegistration', 'trustRegistered'],
          ['masterOffice'],
          ['trustType'],
        ],
        (EntityType.trust, 'authority') => [
          ['authorityIssued'],
          ['issuingOffice'],
          ['trusteeCount'],
          ['reissued'],
        ],
        (EntityType.trust, 'beneficiaries') => [
          ['founderName'],
          ['founderIdentity', 'founderCountry'],
        ],
        (EntityType.company, 'registration') => [
          ['companyName'],
          ['tradingName'],
          ['companyRegistration', 'incorporated'],
          ['companyType', 'vat'],
          ['registeredAddress'],
          ['industry'],
        ],
        (EntityType.company, 'moi') => [
          ['moiDate'],
          ['shareCapital'],
          ['preemptiveRights', 'transferRestrictions', 'externalDirectors'],
        ],
        (EntityType.stokvel, 'constitution') => [
          ['stokvelName'],
          ['founded', 'memberCount'],
          ['stokvelType'],
          ['nasasa'],
          ['nasasaId'],
        ],
        (EntityType.stokvel, 'bank') => [
          ['bank'],
          ['accountNumber', 'branchCode'],
          ['accountName'],
          ['useForWithdrawals'],
        ],
        _ => [
          for (final field in store.step!.fields.where(
            (field) => field.visible(store.draft!.values),
          ))
            [field.key],
        ],
      };

  Widget _row(BuildContext context, List<String> keys) {
    if (keys.length == 1) return _field(keys.single);
    if (keys.every(
      (key) => store.step!.fields.any(
        (field) => field.key == key && field.kind == KycFieldKind.toggle,
      ),
    )) {
      return Column(children: [for (final key in keys) _field(key)]);
    }
    if (MediaQuery.textScalerOf(context).scale(14) > 18) {
      return Column(
        children: [
          for (final (index, key) in keys.indexed) ...[
            if (index > 0) SizedBox(height: 16.w),
            _field(key),
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, key) in keys.indexed) ...[
          if (index > 0) SizedBox(width: 8.w),
          Expanded(child: _field(key)),
        ],
      ],
    );
  }

  Widget _field(String key) {
    final field = store.step!.fields.firstWhere((field) => field.key == key);
    return KycField(
      key: ValueKey(key),
      grouped: true,
      toggleHeight:
          store.entity == EntityType.company && store.selectedStep == 'moi'
          ? 36
          : null,
      multilineHeight: key == 'resolutionNotes'
          ? store.draft!.values[key]?.isNotEmpty == true
                ? 145
                : 129
          : null,
      labelSpacing: key == 'resolutionNotes' ? 10 : 4,
      outline:
          key == 'resolutionNotes' ||
          key == 'masterOffice' ||
          key == 'trustType' ||
          store.entity == EntityType.stokvel &&
              const {
                'signatory',
                'stokvelType',
                'bank',
                'frequency',
              }.contains(key),
      multilineLines: store.selectedStep == 'resolution' ? 6 : 3,
      showChoiceIndicator:
          store.selectedStep != 'beneficiaries' &&
          !const {'nasasa', 'companyType'}.contains(key) &&
          (key != 'trustType' || (store.draft!.values[key] ?? '').isEmpty),
      definition: field,
      value: store.draft!.values[key] ?? '',
      error: store.errors[key],
      enabled: !store.busy,
      onChanged: (value) => store.edit(key, value),
    );
  }
}
