import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_member_plan.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/stores/kyc_member_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_allocation_form.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_invite_form.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_invite_sent_sheet.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_member_form.dart';

class KycMemberScreen extends StatelessWidget {
  const KycMemberScreen({
    super.key,
    required this.store,
    required this.role,
    required this.section,
    required this.returnStep,
    this.id,
  });
  final KycMemberStore store;
  final KycMemberRole role;
  final KycMemberSection section;
  final String returnStep;
  final String? id;

  void _finish(BuildContext context, bool saved) {
    if (store.busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (context.canPop()) {
      context.pop(saved);
    } else {
      context.goNamed(
        InvestorRoutes.kyc,
        pathParameters: {'entity': store.entity.name, 'step': returnStep},
      );
    }
  }

  Future<void> _next(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (section == KycMemberSection.invite ||
        section == KycMemberSection.preview) {
      if (await store.invite() && context.mounted) {
        final receipt =
            store.application!.invitationReceipts[store.invitation.memberId];
        if (receipt == null) return;
        final action = await showKycInviteSentSheet(
          context,
          receipt: receipt,
          recipient: store.values['firstName']?.trim().isNotEmpty == true
              ? store.values['firstName']!.trim()
              : 'this member',
        );
        if (!context.mounted || store.isDisposed) return;
        if (action == null) {
          _finish(context, true);
          return;
        }
        final destination = action == 'resolution'
            ? 'resolution'
            : switch (store.entity) {
                EntityType.trust => 'trustees',
                EntityType.company => 'directors',
                _ => 'officers',
              };
        if (context.canPop() && destination == returnStep) {
          _finish(context, true);
          return;
        }
        context.goNamed(
          InvestorRoutes.kyc,
          pathParameters: {'entity': store.entity.name, 'step': destination},
        );
      }
      return;
    }
    if (section == KycMemberSection.allocation) {
      if (store.saveAllocations()) _finish(context, true);
      return;
    }
    if (!store.save()) return;
    if (role == KycMemberRole.beneficiary) {
      final savedId = store.draft!.id;
      final allocated = await _push(
        context,
        KycMemberSection.allocation,
        memberId: savedId,
      );
      if (!context.mounted || store.isDisposed) return;
      if (allocated != true) {
        await store.load(role, id: savedId);
        return;
      }
    }
    if (context.mounted) _finish(context, true);
  }

  Future<bool?> _push(
    BuildContext context,
    KycMemberSection next, {
    String? memberId,
  }) => context.pushNamed<bool>(
    InvestorRoutes.kycMember,
    pathParameters: {
      'entity': store.entity.name,
      'role': role.name,
      'section': next.name,
    },
    queryParameters: {
      'return': returnStep,
      if ((memberId ?? id) != null) 'id': (memberId ?? id)!,
    },
  );
  Future<void> _preview(BuildContext context) async {
    if (!store.validateInvite()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final sent = await _push(context, KycMemberSection.preview);
    if (!context.mounted || store.isDisposed) return;
    if (sent == true) {
      _finish(context, true);
    } else {
      await store.load(role, id: id);
    }
  }

  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) {
      final title = switch (section) {
        KycMemberSection.details =>
          '${!store.editable
              ? 'View'
              : store.member == null
              ? 'Add'
              : 'Edit'} ${role.label}',
        KycMemberSection.allocation =>
          role == KycMemberRole.shareholder
              ? 'Update share register'
              : 'Amount Allocation',
        KycMemberSection.invite => 'Email Invite',
        KycMemberSection.preview => 'Email preview',
      };
      if (store.status == LoadStatus.initial ||
          store.status == LoadStatus.loading) {
        return InvestorPage(
          title: title,
          child: const Center(child: CircularProgressIndicator()),
        );
      }
      if (store.status == LoadStatus.error || store.draft == null) {
        return InvestorPage(
          title: title,
          child: ErrorView(
            message: store.error ?? 'Unable to load this member.',
            onRetry: () => store.load(role, id: id),
          ),
        );
      }
      final enabled = switch (section) {
        KycMemberSection.details => store.canSave,
        KycMemberSection.allocation =>
          store.editable &&
              !store.busy &&
              store.allocations.isNotEmpty &&
              store.totalAllocation == 10000,
        _ => store.canInvite,
      };
      final left = AppButton(
        label: section == KycMemberSection.invite
            ? 'Preview email'
            : section == KycMemberSection.preview
            ? 'Back to edit'
            : section == KycMemberSection.allocation
            ? 'Back'
            : role == KycMemberRole.beneficiary
            ? 'Save & exit'
            : 'Cancel',
        style: AppButtonStyle.secondary,
        onPressed: store.busy
            ? null
            : section == KycMemberSection.invite
            ? () => _preview(context)
            : () => _finish(context, false),
      );
      final right = AppButton(
        label: section == KycMemberSection.invite
            ? 'Send Invite'
            : section == KycMemberSection.preview
            ? 'Send email'
            : role == KycMemberRole.shareholder &&
                  section == KycMemberSection.details
            ? 'Update Register'
            : 'Save & continue',
        loading: store.busy,
        onPressed: enabled ? () => _next(context) : null,
      );
      return PopScope(
        canPop: !store.busy,
        child: InvestorPage(
          title: title,
          headerLeadingInset: 22,
          onBack: () => _finish(context, false),
          bottom: MediaQuery.textScalerOf(context).scale(16) > 21
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    right,
                    SizedBox(height: 12.w),
                    left,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: left),
                    SizedBox(width: 20.w),
                    Expanded(child: right),
                  ],
                ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                top: section == KycMemberSection.preview
                    ? 12.w
                    : role == KycMemberRole.shareholder &&
                          section == KycMemberSection.details
                    ? 16.w
                    : 27.w,
                bottom: 28.w,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  switch (section) {
                    KycMemberSection.details => KycMemberForm(store: store),
                    KycMemberSection.allocation => KycAllocationForm(
                      store: store,
                    ),
                    KycMemberSection.invite => KycInviteForm(store: store),
                    KycMemberSection.preview => KycInvitePreview(store: store),
                  },
                  if (store.error != null) InlineError(store.error),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
