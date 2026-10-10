import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/feedback.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/stores/kyc_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/entity_kyc_form.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/natural_kyc_form.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_document_actions.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/trust_kyc_review.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_checklist_view.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/natural_kyc_review.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/organisation_kyc_review.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_result_sheet.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

class KycScreen extends StatelessWidget {
  const KycScreen({super.key, required this.store});
  final KycStore store;
  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) {
      if (store.status == LoadStatus.initial ||
          store.status == LoadStatus.loading) {
        return const InvestorPage(
          title: 'KYC Verification',
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (store.draft == null || store.status == LoadStatus.error) {
        return InvestorPage(
          title: 'KYC Verification',
          child: InvestorEmptyState(
            title: 'Unable to load verification',
            message: store.error ?? 'Please try again.',
            action: 'Retry',
            onAction: store.load,
          ),
        );
      }
      return PopScope(
        canPop:
            !store.busy &&
            !store.hasUnsavedChanges &&
            store.selectedStep == 'overview',
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _back(context);
        },
        child: store.selectedStep == 'overview'
            ? KycChecklistView(
                store: store,
                onBack: () => _exit(context),
                onSaveAndExit: () => _exit(context, confirmUnsaved: false),
              )
            : store.entity == EntityType.individual &&
                  store.selectedStep == 'review' &&
                  store.editable
            ? NaturalKycReview(store: store, onBack: () => _back(context))
            : store.entity == EntityType.trust &&
                  (store.selectedStep == 'review' || !store.editable)
            ? TrustKycReview(
                store: store,
                onBack: () => _back(context),
                onExit: () => _exit(context),
              )
            : InvestorPage(
                title: store.selectedStep == 'review'
                    ? 'Review & Submit'
                    : store.entity == EntityType.individual &&
                          store.selectedStep == 'identity' &&
                          (store.draft!.values['idType'] ?? '').isNotEmpty
                    ? 'International passport'
                    : store.step?.title ?? 'KYC Verification',
                onBack: () => _back(context),
                bodyPadding:
                    store.entity == EntityType.company &&
                            store.selectedStep == 'moi' ||
                        store.entity == EntityType.stokvel &&
                            store.selectedStep == 'bank'
                    ? EdgeInsets.symmetric(horizontal: 11.w)
                    : null,
                headerLeadingInset: store.entity == EntityType.individual
                    ? 21.5
                    : 22,
                titleCenterOffset: store.entity == EntityType.individual
                    ? switch (store.selectedStep) {
                        'identity' =>
                          (store.draft!.values['idType'] ?? '').isEmpty
                              ? 8
                              : -14.5,
                        'address' || 'bank' => 5,
                        'tax' => 4,
                        'funds' => -4,
                        _ => 0,
                      }
                    : store.entity == EntityType.trust &&
                          store.selectedStep == 'authority'
                    ? -4.5
                    : store.entity == EntityType.company &&
                          store.selectedStep == 'moi'
                    ? 8
                    : 0,
                titleOverflow: TextOverflow.ellipsis,
                bottom:
                    store.entity == EntityType.individual &&
                        store.editable &&
                        store.step != null &&
                        !(store.selectedStep == 'identity' &&
                            (store.draft!.values['idType'] ?? '').isEmpty)
                    ? AppButton(
                        label: store.selectedStep == 'bank'
                            ? 'Submit for verification'
                            : store.selectedStep == 'tax'
                            ? 'Continue to review'
                            : 'Continue',
                        loading:
                            store.busy &&
                            store.uploading == null &&
                            store.selectedStep != 'identity',
                        onPressed: store.canContinue
                            ? () => _continue(context)
                            : null,
                      )
                    : store.entity != EntityType.individual &&
                          store.editable &&
                          store.step != null
                    ? Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: store.selectedStep == 'beneficiaries'
                                  ? 'Save & exit'
                                  : 'Save & Exit',
                              style: AppButtonStyle.secondary,
                              onPressed: store.busy
                                  ? null
                                  : () => _exit(context),
                            ),
                          ),
                          SizedBox(width: 18.w),
                          Expanded(
                            child: AppButton(
                              label: store.selectedStep == 'beneficiaries'
                                  ? 'Save & continue'
                                  : 'Save and Continue',
                              loading: store.busy,
                              onPressed: store.canContinue
                                  ? store.continueStep
                                  : null,
                            ),
                          ),
                        ],
                      )
                    : null,
                child: SingleChildScrollView(
                  child: store.selectedStep == 'review' || !store.editable
                      ? _KycReview(store: store)
                      : _KycStepForm(store: store),
                ),
              ),
      );
    },
  );
  Future<void> _continue(BuildContext context) async {
    if (!store.canContinue) return;
    if (store.reviewingStep) {
      store.continueStep();
      return;
    }
    if (store.selectedStep == 'identity') {
      if (!await store.simulateIdentityCheck() || !context.mounted) return;
      store.selectStep('overview');
      await showKycProgressSheet(context);
      return;
    }
    if (store.selectedStep == 'address' || store.selectedStep == 'bank') {
      if (!store.saveAndExit()) return;
      final action = await showKycProgressSheet(context);
      if (!context.mounted || action != 'primary') return;
    }
    store.continueStep();
  }

  void _back(BuildContext context) {
    if (store.busy) return;
    if (store.reviewingStep) {
      store.selectStep('review');
      return;
    }
    if (store.editable &&
        store.entity == EntityType.individual &&
        store.selectedStep == 'identity' &&
        (store.draft!.values['idType'] ?? '').isNotEmpty) {
      store.edit('idType', '');
      return;
    }
    if (store.selectedStep != 'overview') {
      store.selectStep('overview');
      return;
    }
    _exit(context);
  }

  Future<void> _exit(BuildContext context, {bool confirmUnsaved = true}) async {
    if (store.busy) return;
    if (confirmUnsaved && store.hasUnsavedChanges) {
      final save = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Save and exit?'),
          content: const Text(
            'Your verification progress will be available when you return to this profile.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep editing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save & Exit'),
            ),
          ],
        ),
      );
      if (!context.mounted || save != true) return;
    }
    if (!store.saveAndExit()) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(InvestorRoutes.home);
    }
  }
}

class _KycStepForm extends StatelessWidget {
  const _KycStepForm({required this.store});
  final KycStore store;
  @override
  Widget build(BuildContext context) {
    if (store.entity == EntityType.individual) {
      return NaturalKycForm(
        store: store,
        onUpload: (document) =>
            KycDocumentActions(store).choose(context, document),
        onDelete: (document) =>
            KycDocumentActions(store).remove(context, document),
      );
    }
    return EntityKycForm(
      store: store,
      onUpload: (document) =>
          KycDocumentActions(store).choose(context, document),
      onDelete: (document) =>
          KycDocumentActions(store).remove(context, document),
    );
  }
}

class _KycReview extends StatelessWidget {
  const _KycReview({required this.store});
  final KycStore store;
  @override
  Widget build(BuildContext context) {
    final status = store.draft!.status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (status == VerificationStatus.pending ||
            status == VerificationStatus.verified ||
            status == VerificationStatus.correctionRequired) ...[
          Center(
            child: AppIcon(
              status == VerificationStatus.correctionRequired
                  ? AppAssets.investorFailure
                  : AppAssets.investorSuccess,
              size: 96,
            ),
          ),
          SizedBox(height: 24.w),
          Text(switch (status) {
            VerificationStatus.pending => 'Verification in review',
            VerificationStatus.verified => 'You’re verified',
            _ => 'Correction required',
          }, style: AppTextStyles.text(32, weight: FontWeight.w700)),
          SizedBox(height: 16.w),
          Text(
            status == VerificationStatus.pending
                ? 'Your documents have been received. We’ll let you know when verification is complete.'
                : status == VerificationStatus.verified
                ? 'Your verification is complete. You can now explore investment opportunities.'
                : store.draft!.correction ??
                      'Please review and correct your application.',
            style: AppTextStyles.body,
          ),
          SizedBox(height: 28.w),
        ] else ...[
          Text(
            'Review your details',
            style: AppTextStyles.text(32, weight: FontWeight.w700),
          ),
          SizedBox(height: 16.w),
          Text(
            'Confirm everything is correct before submitting your verification.',
            style: AppTextStyles.body,
          ),
          SizedBox(height: 24.w),
        ],
        if (store.entity == EntityType.company)
          CompanyKycReviewDetails(store: store)
        else if (store.entity == EntityType.stokvel)
          StokvelKycReviewDetails(store: store)
        else
          for (final step in store.steps)
            Padding(
              padding: EdgeInsets.only(bottom: 16.w),
              child: InvestorSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(step.title, style: AppTextStyles.section),
                        ),
                        if (store.editable)
                          TextButton(
                            onPressed: () => store.selectStep(step.id),
                            child: const Text('Edit'),
                          ),
                      ],
                    ),
                    for (final field in step.fields.where(
                      (field) =>
                          field.label.isNotEmpty &&
                          field.visible(store.draft!.values),
                    ))
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 6.w),
                        child: InvestorDetailRow(
                          field.label,
                          switch (store.draft!.values[field.key]) {
                            'true' => 'Yes',
                            'false' => 'No',
                            final value? when value.isNotEmpty =>
                              value.replaceAll('|', ', '),
                            _ => 'Not provided',
                          },
                        ),
                      ),
                    for (final document in step.documents)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 6.w),
                        child: InvestorDetailRow(
                          document.title,
                          store.draft!.documentsFor(document.key).isEmpty
                              ? document.required
                                    ? 'Required'
                                    : 'Not provided'
                              : store.draft!
                                    .documentsFor(document.key)
                                    .map((file) => file.name)
                                    .join('\n'),
                        ),
                      ),
                    if (step.id == 'tax' &&
                        store.draft!.values['secondaryTax'] == 'true')
                      for (final residency in store.draft!.taxResidencies)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.w),
                          child: InvestorDetailRow(
                            residency.country,
                            '${residency.tin}\n${residency.reason}\n${residency.status}',
                          ),
                        ),
                    for (final member in store.draft!.members.where(
                      step.includesMember,
                    ))
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 6.w),
                        child: InvestorDetailRow(
                          member.name,
                          member.signed
                              ? 'Signed'
                              : member.identityVerified &&
                                    member.addressVerified
                              ? 'Verified'
                              : 'Pending',
                        ),
                      ),
                  ],
                ),
              ),
            ),
        if (store.error != null) ...[
          InlineError(store.error!),
          SizedBox(height: 16.w),
        ],
        if (store.editable)
          AppButton(
            label: status == VerificationStatus.correctionRequired
                ? 'Submit Corrections'
                : 'Submit for Verification',
            loading: store.busy,
            onPressed: () async {
              final success = await store.submit();
              if (context.mounted && success) {
                showFeedback(context, 'Verification submission simulated.');
              }
            },
          ),
        if (status == VerificationStatus.pending) ...[
          AppButton(
            label: 'View Home',
            onPressed: () => context.goNamed(InvestorRoutes.home),
          ),
          SizedBox(height: 16.w),
          Text(
            'Mock verification controls',
            style: AppTextStyles.text(12, color: AppColors.muted),
          ),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: store.busy
                      ? null
                      : () => store.simulateReview(true),
                  child: const Text('Simulate approval'),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: store.busy
                      ? null
                      : () => store.simulateReview(false),
                  child: const Text('Request correction'),
                ),
              ),
            ],
          ),
        ],
        if (status == VerificationStatus.verified)
          AppButton(
            label: 'Explore Projects',
            onPressed: () => context.goNamed(InvestorRoutes.explore),
          ),
        SizedBox(height: 24.w),
      ],
    );
  }
}
