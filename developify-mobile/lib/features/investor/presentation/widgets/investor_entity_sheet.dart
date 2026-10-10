import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

Future<({EntityType entity, bool nonResident})?> showInvestorEntitySheet(
  BuildContext context, {
  EntityType? initial = EntityType.individual,
  bool nonResident = false,
}) => showModalBottomSheet<({EntityType entity, bool nonResident})>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  useSafeArea: true,
  barrierColor: AppColors.blackAlpha168,
  backgroundColor: AppColors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(8.w),
      topRight: Radius.circular(5.w),
    ),
  ),
  builder: (_) => _InvestorEntitySheet(
    initial: initial,
    nonResident: nonResident,
  ),
);

class _InvestorEntitySheet extends StatefulWidget {
  const _InvestorEntitySheet({
    required this.initial,
    required this.nonResident,
  });
  final EntityType? initial;
  final bool nonResident;
  @override
  State<_InvestorEntitySheet> createState() => _InvestorEntitySheetState();
}

class _InvestorEntitySheetState extends State<_InvestorEntitySheet> {
  late EntityType? selected = widget.nonResident ? null : widget.initial;
  late bool nonResident = widget.nonResident;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      height: math.min(789.w, constraints.maxHeight),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(
              height: math.max(
                88.w,
                MediaQuery.textScalerOf(context).scale(30.sp) + 45.w,
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 16.w,
                    top: 38.262.w,
                    right: 60.w,
                    child: Text(
                      'Select entity type',
                      style: AppTextStyles.text(
                        25,
                        weight: FontWeight.w700,
                        color: AppColors.black,
                        height: 30 / 25,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 14.w,
                    top: 30.w,
                    child: Semantics(
                      button: true,
                      label: 'Close',
                      child: InkResponse(
                        onTap: () => Navigator.pop(context),
                        child: SizedBox.square(
                          dimension: 44,
                          child: const Center(
                            child: AppIcon(
                              AppAssets.recoverySuccessClose,
                              size: 35,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                children: [
                  for (final entry in const [
                    (
                      EntityType.individual,
                      'Natural Person',
                      'Most common',
                      '7 documents · ~6 min',
                      'For investors using personal funds. Verification is simulated in this demo.',
                      AppColors.primary,
                      AppColors.mintHighlight,
                      104.0,
                      (left: 13.31, top: 10.04, height: 81.314, gap: 12.436),
                    ),
                    (
                      EntityType.trust,
                      'Trust',
                      'Custom',
                      '6 documents · ~25 min',
                      'Trust Deed + Letters of Authority + trustee KYC.',
                      AppColors.violetBright,
                      AppColors.violetBrightAlpha13,
                      94.7073,
                      (left: 14.61, top: 12.44, height: 68.878, gap: 16.52),
                    ),
                    (
                      EntityType.company,
                      'Company / SPV',
                      'Corporate',
                      '6 documents · ~10 min',
                      'CIPC, MOI, Share register and more',
                      AppColors.blueStrong,
                      AppColors.bluePale,
                      93.7507,
                      (left: 11.75, top: 8.61, height: 73.661, gap: 13.868),
                    ),
                    (
                      EntityType.stokvel,
                      'Stokvel / Group',
                      'Pooled',
                      '6 documents · ~10 min',
                      'Constitution, resolutions and office bearer KYC.',
                      AppColors.navy,
                      AppColors.navyAlpha18,
                      93.7507,
                      (left: 14.31, top: 13.65, height: 73.661, gap: 15.194),
                    ),
                  ])
                    Padding(
                      padding: EdgeInsets.only(bottom: 14.35.w),
                      child: InvestorEntityChoice(
                        title: entry.$2,
                        badge: entry.$3,
                        subtitle: entry.$4,
                        description: entry.$5,
                        badgeColor: entry.$6,
                        badgeBackground: entry.$7,
                        minHeight: entry.$8,
                        contentLeft: entry.$9.left,
                        contentTop: entry.$9.top,
                        contentMinHeight: entry.$9.height,
                        badgeGap: entry.$9.gap,
                        subtitleSize: entry.$1 == EntityType.company
                            ? 13.392953
                            : 12,
                        selected: selected == entry.$1,
                        onTap: () => setState(() {
                          selected = entry.$1;
                          nonResident = false;
                        }),
                      ),
                    ),
                  InvestorEntityChoice(
                    title: 'Non-Resident / Diaspora',
                    badge: 'Overlay',
                    subtitle: 'Adds ~10 min · combines with any base entity',
                    description: 'Additional identity and residence documents.',
                    badgeColor: AppColors.diasporaBadge,
                    badgeBackground: AppColors.diasporaBadgeBackground,
                    minHeight: 109.0569,
                    contentLeft: 14.61,
                    contentTop: 8.61,
                    contentMinHeight: 89.661,
                    badgeGap: 13.194,
                    subtitleWidth: 209.504,
                    radioTop: 21.33,
                    selected: nonResident,
                    toggle: true,
                    onTap: () => setState(() {
                      nonResident = !nonResident;
                      if (nonResident) selected = null;
                    }),
                  ),
                  SizedBox(height: 20.w),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.w, 8.w, 17.w),
              child: AppButton(
                label: 'Use this entity',
                onPressed: selected == null && !nonResident
                    ? null
                    : () => Navigator.pop(context, (
                        entity: selected ?? EntityType.individual,
                        nonResident: nonResident,
                      )),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class InvestorEntityChoice extends StatelessWidget {
  const InvestorEntityChoice({
    super.key,
    required this.title,
    required this.badge,
    required this.subtitle,
    required this.description,
    required this.badgeColor,
    required this.badgeBackground,
    required this.minHeight,
    required this.selected,
    required this.onTap,
    this.toggle = false,
    this.fullPage = false,
    this.contentLeft = 13.04,
    this.contentTop = 9.5664,
    this.contentMinHeight = 0,
    this.badgeGap = 18,
    this.subtitleSize = 12,
    this.subtitleWidth,
    this.radioTop,
  });
  final String title;
  final String badge;
  final String subtitle;
  final String description;
  final Color badgeColor;
  final Color badgeBackground;
  final double minHeight;
  final bool selected;
  final VoidCallback onTap;
  final bool toggle;
  final bool fullPage;
  final double contentLeft;
  final double contentTop;
  final double contentMinHeight;
  final double badgeGap;
  final double subtitleSize;
  final double? subtitleWidth;
  final double? radioTop;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: toggle ? null : selected,
    toggled: toggle ? selected : null,
    button: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9.5664.w),
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight.w),
        alignment: fullPage ? null : Alignment.topLeft,
        padding: EdgeInsets.fromLTRB(
          contentLeft.w,
          contentTop.w,
          4.17.w,
          (fullPage || contentMinHeight == 0
                  ? 9.5664
                  : math.max(0, minHeight - contentTop - contentMinHeight - 2))
              .w,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(
            color: fullPage && selected ? AppColors.primary : AppColors.border,
            width: .95664.w,
          ),
          borderRadius: BorderRadius.circular(9.5664.w),
        ),
        child: Row(
          crossAxisAlignment: radioTop == null
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: (radioTop ?? 0).w),
              child: AppIcon(
                selected
                    ? AppAssets.investorEntityRadioSelected
                    : AppAssets.investorEntityRadioUnselected,
                size: selected ? 32 : 31,
              ),
            ),
            SizedBox(width: 7.304.w),
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: contentMinHeight.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: badgeGap.w,
                      runSpacing: 6.w,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.text(
                            fullPage ? 14 : 13.39295,
                            weight: FontWeight.w600,
                            height: fullPage ? 1.2 : 16 / 13.39295,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.92.w,
                            vertical: 4.48.w,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBackground,
                            borderRadius: BorderRadius.circular(478.w),
                          ),
                          child: Text(
                            badge,
                            style: AppTextStyles.text(
                              fullPage ? 12 : 11.479675,
                              weight: FontWeight.w700,
                              color: badgeColor,
                              height: fullPage ? 14 / 12 : 14 / 11.479675,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.7.w),
                    SizedBox(
                      width: subtitleWidth?.w,
                      child: Text(
                        subtitle,
                        style: AppTextStyles.text(
                          fullPage ? 14 : subtitleSize,
                          weight: FontWeight.w500,
                          color: AppColors.primary,
                          height: 1.2,
                        ),
                      ),
                    ),
                    SizedBox(height: 6.7.w),
                    Text(
                      description,
                      style: AppTextStyles.text(
                        fullPage ? 14 : 12,
                        color: AppColors.text,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
