import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/dashed_border.dart';
import 'package:developify_mobile/core/widgets/feedback.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_member_plan.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/stores/kyc_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_allocation_form.dart';

class KycMembers extends StatelessWidget {
  const KycMembers({super.key, required this.store});
  final KycStore store;

  Future<void> _open(
    BuildContext context,
    KycMemberRole role,
    KycMemberSection section, {
    KycMember? member,
  }) async {
    final step = store.selectedStep;
    FocusManager.instance.primaryFocus?.unfocus();
    await context.pushNamed<bool>(
      InvestorRoutes.kycMember,
      pathParameters: {
        'entity': store.entity.name,
        'role': role.name,
        'section': section.name,
      },
      queryParameters: {'return': step, if (member != null) 'id': member.id},
    );
    if (!context.mounted || store.isDisposed) return;
    await store.load(requestedStep: step);
  }

  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) {
      final step = store.selectedStep;
      final beneficiaries = step == 'beneficiaries';
      final shareholders = step == 'shareholders';
      final directors = step == 'directors';
      final officers = step == 'officers';
      final total = store.members.fold(
        0,
        (sum, member) => sum + _allocation(member),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (beneficiaries) _heading('Beneficiaries'),
          if (directors) ...[
            for (final (heading, people) in [
              (
                'Directors',
                store.members
                    .where(
                      (member) =>
                          member.role == KycMemberRole.director ||
                          member.details?.isDirector == true,
                    )
                    .toList(),
              ),
              (
                'Ultimate Beneficial Owners (> 5%)',
                store.members
                    .where(
                      (member) =>
                          member.role == KycMemberRole.shareholder &&
                          member.shareBasisPoints > 500,
                    )
                    .toList(),
              ),
            ]) ...[
              if (heading != 'Directors') SizedBox(height: 10.w),
              _heading(heading),
              for (final member in people)
                _member(
                  context,
                  member,
                  tall: true,
                  beneficialOwner: heading != 'Directors',
                ),
            ],
          ] else
            for (final member in store.members)
              _member(
                context,
                member,
                allocation: beneficiaries || shareholders,
                tall: officers,
              ),
          if (store.members.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 20.w),
              child: Column(
                children: [
                  Text(
                    beneficiaries ? 'No beneficiary yet' : 'No members yet',
                    style: AppTextStyles.text(14, weight: FontWeight.w500),
                  ),
                  SizedBox(height: 8.w),
                  Text(
                    beneficiaries
                        ? 'Your beneficiary list is empty. Add a trusted recipient to get started.'
                        : 'Add the people who need to complete this verification.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.text(12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          if (store.editable && (beneficiaries || shareholders || directors))
            AppButton(
              label: beneficiaries
                  ? 'Add a beneficiary'
                  : directors
                  ? 'Add another shareholder'
                  : 'Add a shareholder',
              style: AppButtonStyle.mintOutline,
              labelSize: 14,
              onPressed: store.busy
                  ? null
                  : () => _open(
                      context,
                      beneficiaries
                          ? KycMemberRole.beneficiary
                          : KycMemberRole.shareholder,
                      KycMemberSection.details,
                    ),
            ),
          if (beneficiaries) ...[
            SizedBox(height: 24.w),
            InvestorSurface(
              radius: 14,
              color: AppColors.warningSurface,
              border: AppColors.investorPepBorder,
              padding: EdgeInsets.all(16.w),
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text:
                          'Total beneficial interest must add up to 100%. At the moment it is at ',
                    ),
                    TextSpan(
                      text: kycShareLabel(total),
                      style: AppTextStyles.text(
                        12,
                        weight: FontWeight.w600,
                        color: AppColors.investorVerificationText,
                      ),
                    ),
                  ],
                ),
                style: AppTextStyles.text(
                  12,
                  height: 17 / 12,
                  color: AppColors.investorVerificationText,
                ),
              ),
            ),
          ],
          if (shareholders) ...[
            SizedBox(height: 20.w),
            _heading('Summary'),
            InvestorSurface(
              border: AppColors.border,
              radius: 10,
              padding: EdgeInsets.all(14.w),
              child: Row(
                children: [
                  for (final (index, entry) in [
                    ('Holders', '${store.members.length}'),
                    (
                      'UBOs > 5%',
                      '${store.members.where((member) => member.shareBasisPoints > 500).length}',
                    ),
                    ('Total', kycShareLabel(total)),
                  ].indexed) ...[
                    if (index > 0)
                      Container(
                        width: 1,
                        height: 42.w,
                        color: AppColors.borderStrong,
                      ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            entry.$1,
                            style: AppTextStyles.text(
                              14,
                              color: AppColors.muted,
                            ),
                          ),
                          SizedBox(height: 6.w),
                          Text(
                            entry.$2,
                            style: AppTextStyles.text(
                              16,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (store.editable && (step == 'trustees' || officers)) ...[
            SizedBox(height: (officers ? 9 : 16).w),
            _heading(
              officers ? 'Quick Actions' : 'Other Option',
              gap: officers ? 14 : 6,
            ),
            Semantics(
              button: true,
              child: InkWell(
                onTap: store.busy ? null : () => _invite(context),
                borderRadius: BorderRadius.circular(10.r),
                child: CustomPaint(
                  foregroundPainter: const DashedBorderPainter(
                    strokeWidth: 1,
                    color: AppColors.borderStrong,
                    radius: 10,
                    dashLength: 5,
                    gapLength: 4,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.investorCard,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 32.w,
                      vertical: (officers ? 12.5 : 12).w,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Email Invite link',
                          style: AppTextStyles.text(
                            14,
                            weight: FontWeight.w600,
                            height: 17 / 14,
                          ),
                        ),
                        SizedBox(height: 5.w),
                        Text(
                          officers
                              ? 'Manually add an office bearer by entering their email\naddress.'
                              : 'Manually add a new trustee by entering their email\naddress.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.text(
                            12,
                            color: AppColors.muted,
                            height: 14 / 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          for (final key in ['members', 'allocation'])
            if (store.errors[key] != null) InlineError(store.errors[key]),
        ],
      );
    },
  );

  Widget _heading(String text, {double gap = 12}) => Padding(
    padding: EdgeInsets.only(bottom: gap.w),
    child: Text(text, style: AppTextStyles.text(14, weight: FontWeight.w500)),
  );
  int _allocation(KycMember member) =>
      int.tryParse(store.draft!.values['allocation:${member.id}'] ?? '') ??
      member.shareBasisPoints;
  Widget _member(
    BuildContext context,
    KycMember member, {
    bool allocation = false,
    bool tall = false,
    bool beneficialOwner = false,
  }) {
    final complete = member.identityVerified && member.addressVerified;
    final actionNeeded = !complete && member.identityVerified;
    final status = complete
        ? 'Verified'
        : actionNeeded
        ? 'Action needed'
        : member.inviteSent
        ? 'In review'
        : 'Pending';
    final tone = complete
        ? AppColors.mintText
        : actionNeeded
        ? AppColors.error
        : AppColors.warning;
    final description = beneficialOwner && member.details?.isDirector == true
        ? 'Same person as director'
        : allocation
        ? member.role == KycMemberRole.beneficiary
              ? member.relationship
              : member.details?.isDirector == true
              ? 'Director · ${member.details?.shareClass ?? 'Ordinary'}'
              : member.role.label
        : complete
        ? 'ID & Address complete'
        : member.identityVerified
        ? 'ID verified, address missing'
        : member.inviteSent
        ? 'Invite sent – Awaiting upload'
        : 'ID and address required';
    final name = Text(
      '${member.name}${store.selectedStep == 'trustees' ? '  (Trustee)' : ''}',
      style: AppTextStyles.text(14, weight: FontWeight.w600),
    );
    final badge = Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.w),
      decoration: BoxDecoration(
        color: complete
            ? AppColors.mint
            : actionNeeded
            ? AppColors.errorSurface
            : AppColors.warningSurface,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Text(status, style: AppTextStyles.text(12, color: tone)),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: 14.w),
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: () => _actions(context, member),
          borderRadius: BorderRadius.circular(10.r),
          child: InvestorSurface(
            radius: 10,
            border: AppColors.border,
            padding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: tall ? 7.w : 11.w,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 21.w,
                  backgroundColor: AppColors.mint,
                  child: Text(
                    '${member.firstName.characters.firstOrNull ?? member.email.characters.firstOrNull ?? ''}${member.lastName.characters.firstOrNull ?? ''}'
                        .toUpperCase(),
                    style: AppTextStyles.text(
                      16,
                      weight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tall)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: name),
                            SizedBox(width: 8.w),
                            badge,
                          ],
                        )
                      else
                        name,
                      SizedBox(height: 6.w),
                      if (tall) ...[
                        Text(
                          beneficialOwner
                              ? '${kycShareLabel(_allocation(member))} holdings'
                              : store.selectedStep == 'directors'
                              ? '${member.details?.position.isNotEmpty == true ? '${member.details!.position} · ' : ''}Director'
                              : member.role.label,
                          style: AppTextStyles.text(14, color: AppColors.muted),
                        ),
                        SizedBox(height: 6.w),
                      ],
                      Text(
                        description,
                        style: AppTextStyles.text(14, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                if (!tall) ...[
                  SizedBox(width: 8.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (allocation)
                        Text(
                          kycShareLabel(_allocation(member)),
                          style: AppTextStyles.text(
                            14,
                            weight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      if (member.role != KycMemberRole.beneficiary) ...[
                        if (allocation) SizedBox(height: 2.w),
                        badge,
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _invite(BuildContext context) async {
    final roles = store.step!.memberRoles;
    var role = roles.first;
    if (roles.length > 1) {
      final selected = await showModalBottomSheet<KycMemberRole>(
        context: context,
        useSafeArea: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Invite office bearer', style: AppTextStyles.section),
                SizedBox(height: 16.w),
                for (final role in roles)
                  ListTile(
                    title: Text(role.label, style: AppTextStyles.label),
                    onTap: () => Navigator.pop(context, role),
                  ),
              ],
            ),
          ),
        ),
      );
      if (!context.mounted || selected == null) return;
      role = selected;
    }
    await _open(context, role, KycMemberSection.invite);
  }

  Future<void> _actions(BuildContext context, KycMember member) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(member.name, style: AppTextStyles.section),
              SizedBox(height: 16.w),
              for (final entry in {
                'details': store.editable ? 'Edit Details' : 'View Details',
                if (store.editable &&
                    [
                      KycMemberRole.beneficiary,
                      KycMemberRole.shareholder,
                    ].contains(member.role))
                  'allocation': 'Update allocation',
                if (store.editable && member.role != KycMemberRole.beneficiary)
                  'invite': 'Send Invite',
                if (store.editable) 'remove': 'Remove member',
              }.entries)
                ListTile(
                  title: Text(entry.value, style: AppTextStyles.label),
                  onTap: () => Navigator.pop(context, entry.key),
                ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    final section = KycMemberSection.tryParse(action);
    if (section != null) {
      await _open(context, member.role, section, member: member);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove member?'),
        content: const Text(
          'This member will be removed from the application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (!context.mounted || confirmed != true) return;
    final success = store.deleteMember(member.id);
    if (!success) {
      showFeedback(
        context,
        store.error ?? 'Unable to update this member.',
        error: true,
      );
    }
  }
}
