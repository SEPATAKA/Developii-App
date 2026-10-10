import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_chrome.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/feedback.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_plan.dart';
import 'package:developify_mobile/features/investor/presentation/stores/kyc_store.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_checklist_content.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

class KycChecklistView extends StatelessWidget {
  const KycChecklistView({
    super.key,
    required this.store,
    required this.onBack,
    required this.onSaveAndExit,
  });
  final KycStore store;
  final VoidCallback onBack;
  final VoidCallback onSaveAndExit;

  @override
  Widget build(BuildContext context) {
    final natural = store.entity == EntityType.individual;
    final total = store.steps.length + (natural ? 1 : 0);
    final complete = store.completed + (natural ? 1 : 0);
    final inset = natural
        ? 10.0
        : store.entity == EntityType.trust
        ? 20.0
        : 13.0;
    return Scaffold(
      body: CustomScrollView(
        key: PageStorageKey('kyc-checklist-${store.entity.name}'),
        slivers: [
          SliverToBoxAdapter(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.darkTeal,
                image: DecorationImage(
                  image: AssetImage(AppAssets.investorKycMesh),
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppPageAppBar(
                      title: 'KYC Checklist',
                      appearance: AppHeaderAppearance.dark,
                      backAsset: AppAssets.investorReviewBack,
                      backAssetSize: 33,
                      leadingInset: natural ? 24 : 20,
                      topInset: 10,
                      titleCenterOffset: natural ? 6.75 : 0,
                      onBack: onBack,
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(inset.w, 15.w, 10.w, 32.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Entity type',
                            style: AppTextStyles.text(
                              16,
                              weight: FontWeight.w500,
                              color: AppColors.mint,
                            ),
                          ),
                          SizedBox(height: 10.w),
                          Padding(
                            padding: EdgeInsets.only(left: 9.w),
                            child: Text(
                              '${KycChecklistContent.number(store.entity)}. ${KycPlans.entityName(store.entity)}',
                              style: AppTextStyles.text(
                                24,
                                weight: FontWeight.w600,
                                color: AppColors.mint,
                              ),
                            ),
                          ),
                          SizedBox(height: 10.w),
                          if (store.entity == EntityType.stokvel)
                            SizedBox(
                              height: MediaQuery.textScalerOf(
                                context,
                              ).scale(19.sp),
                            )
                          else
                            Text(
                              switch (store.entity) {
                                EntityType.individual =>
                                  'Individual Investor checklist',
                                EntityType.trust => 'Testamentary trust',
                                EntityType.company =>
                                  'Property Ltd, SPV, or holding company',
                                EntityType.stokvel => '',
                              },
                              style: AppTextStyles.text(
                                16,
                                color: AppColors.mintBorder,
                              ),
                            ),
                          SizedBox(
                            height:
                                (natural || store.entity == EntityType.trust
                                        ? 37
                                        : 36)
                                    .w,
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                              left:
                                  (natural || store.entity == EntityType.trust
                                          ? 2
                                          : 0)
                                      .w,
                            ),
                            child: SizedBox(
                              width: 361.w,
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '$complete of $total requirements complete',
                                          style: AppTextStyles.text(
                                            14,
                                            weight: FontWeight.w500,
                                            color: AppColors.kycProgressText,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${(complete * 100 / total).round()}%',
                                        style: AppTextStyles.text(
                                          14,
                                          weight: FontWeight.w500,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 9.w),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(5.r),
                                    child: LinearProgressIndicator(
                                      value: (complete / total).clamp(0, 1),
                                      semanticsLabel:
                                          'Verification requirements complete, $complete of $total',
                                      minHeight: 6.w,
                                      color: AppColors.white,
                                      backgroundColor: AppColors.glass,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(top: 17.w),
            sliver: SliverList.list(
              children:
                  [
                        InvestorSurface(
                          color: AppColors.emerald50,
                          border: AppColors.emerald100,
                          radius: 14,
                          padding: EdgeInsets.all(14.w),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: (natural ? 38 : 0).w,
                            ),
                            child: Text(
                              KycChecklistContent.introduction(store.entity),
                              style: AppTextStyles.text(
                                13,
                                weight: FontWeight.w500,
                                color: AppColors.emerald900,
                                height: 14 / 13,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height:
                              (natural || store.entity == EntityType.stokvel
                                      ? 20
                                      : 15)
                                  .w,
                        ),
                        for (final (index, item) in KycChecklistContent.items(
                          store.entity,
                        ).indexed) ...[
                          _ChecklistRow(
                            title: item.title,
                            subtitle: item.subtitle,
                            natural: natural,
                            approved:
                                natural &&
                                store.draft!.status ==
                                    VerificationStatus.verified,
                            minHeight: KycChecklistContent.rowHeight(
                              store.entity,
                              index,
                            ),
                            textGap: KycChecklistContent.textGap(
                              store.entity,
                              item.step,
                            ),
                            accessoryOffset:
                                store.entity == EntityType.trust &&
                                    item.step == 'authority'
                                ? -8
                                : 0,
                            titleWidth:
                                store.entity == EntityType.stokvel &&
                                    item.step == 'officers'
                                ? 217
                                : null,
                            subtitleWidth:
                                store.entity == EntityType.company &&
                                    item.step == 'shareholders'
                                ? 212
                                : null,
                            complete:
                                item.step == 'contact' ||
                                store.draft!.completedSteps.contains(item.step),
                            verified:
                                item.step == 'contact' ||
                                store.draft!.verifiedSteps.contains(item.step),
                            onTap: () {
                              if (item.step == 'contact') {
                                showFeedback(
                                  context,
                                  'Mobile and email verification are simulated in this session.',
                                );
                              } else {
                                store.selectStep(item.step);
                              }
                            },
                          ),
                          SizedBox(height: 12.w),
                        ],
                        SizedBox(
                          height:
                              (natural || store.entity == EntityType.trust
                                      ? 5
                                      : 0)
                                  .w,
                        ),
                        InvestorSurface(
                          color: natural
                              ? AppColors.warningSurface
                              : AppColors.skyTint,
                          border: natural
                              ? AppColors.kycWarningBorder
                              : AppColors.skyBorder,
                          radius: 14,
                          padding: EdgeInsets.symmetric(
                            horizontal: 13.w,
                            vertical: 12.w,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: (natural ? 35 : 39).w,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (store.entity == EntityType.trust) ...[
                                  Text(
                                    'Tip',
                                    style: AppTextStyles.text(
                                      12,
                                      weight: FontWeight.w700,
                                      height: 17 / 12,
                                    ),
                                  ),
                                  SizedBox(height: 5.w),
                                ],
                                Text(
                                  KycChecklistContent.reminder(
                                    store.entity,
                                    verified:
                                        store.draft!.status ==
                                        VerificationStatus.verified,
                                  ),
                                  style: AppTextStyles.text(
                                    12,
                                    color: natural
                                        ? AppColors.investorVerificationText
                                        : AppColors.text,
                                    height: 17 / 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20.w),
                      ]
                      .map(
                        (child) => Padding(
                          padding: EdgeInsets.only(
                            left:
                                (natural && child is _ChecklistRow ? 10 : 12).w,
                            right:
                                (natural
                                        ? child is _ChecklistRow
                                              ? 14
                                              : 12
                                        : 17)
                                    .w,
                          ),
                          child: child,
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12.w, 12.w, 12.w, 6.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InlineError(store.error),
              AppButton(
                label: store.draft!.status == VerificationStatus.verified
                    ? 'Back Home'
                    : 'Continue',
                onPressed: store.busy
                    ? null
                    : store.draft!.status == VerificationStatus.verified
                    ? () => context.goNamed(InvestorRoutes.home)
                    : () {
                        final remaining = store.steps.where(
                          (step) =>
                              !store.draft!.completedSteps.contains(step.id),
                        );
                        store.selectStep(
                          !store.editable || remaining.isEmpty
                              ? 'review'
                              : remaining.first.id,
                        );
                      },
              ),
              if (natural && store.editable) ...[
                SizedBox(height: 10.w),
                AppButton(
                  label: 'Save and exit',
                  style: AppButtonStyle.secondary,
                  onPressed: store.busy ? null : onSaveAndExit,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.title,
    required this.subtitle,
    required this.natural,
    required this.approved,
    required this.minHeight,
    required this.textGap,
    required this.complete,
    required this.verified,
    required this.onTap,
    this.titleWidth,
    this.subtitleWidth,
    this.accessoryOffset = 0,
  });
  final String title;
  final String subtitle;
  final bool natural;
  final bool approved;
  final double minHeight;
  final double textGap;
  final bool complete;
  final bool verified;
  final VoidCallback onTap;
  final double? titleWidth;
  final double? subtitleWidth;
  final double accessoryOffset;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    checked: complete,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: InvestorSurface(
        radius: 10,
        border: AppColors.border,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight.w),
          child: Padding(
            padding: EdgeInsets.fromLTRB(11.w, 6.w, 0, 6.w),
            child: Row(
              children: [
                Transform.translate(
                  offset: Offset(0, accessoryOffset.w),
                  child: SizedBox.square(
                    dimension: 20.w,
                    child: complete
                        ? OverflowBox(
                            minWidth: 32.w,
                            maxWidth: 32.w,
                            minHeight: 32.w,
                            maxHeight: 32.w,
                            child: const AppIcon(
                              AppAssets.investorCheckboxChecked,
                              size: 32,
                            ),
                          )
                        : const AppIcon(
                            AppAssets.investorCheckboxUnchecked,
                            size: 20,
                          ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: titleWidth?.w,
                        child: Text(
                          title,
                          style: AppTextStyles.text(
                            14,
                            weight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      SizedBox(height: textGap.w),
                      SizedBox(
                        width: subtitleWidth?.w,
                        child: Text(
                          subtitle,
                          style: AppTextStyles.text(
                            14,
                            color: natural ? AppColors.text : AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 14.w),
                Transform.translate(
                  offset: Offset(0, accessoryOffset.w),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: (verified ? 8 : 7).w,
                      vertical: (verified ? 4 : 3).w,
                    ),
                    decoration: BoxDecoration(
                      color: verified
                          ? approved
                                ? AppColors.mintBorder
                                : AppColors.successSurface
                          : AppColors.pendingBadgeSurface,
                      borderRadius: BorderRadius.circular(20.r),
                      border: verified
                          ? null
                          : Border.all(color: AppColors.pendingBadgeBorder),
                    ),
                    child: Text(
                      verified ? 'Verified' : 'Pending',
                      style: AppTextStyles.text(
                        12,
                        color: verified
                            ? approved
                                  ? AppColors.primary
                                  : AppColors.successBadgeText
                            : AppColors.warning,
                        height: 16 / 12,
                        letterSpacing: .12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
