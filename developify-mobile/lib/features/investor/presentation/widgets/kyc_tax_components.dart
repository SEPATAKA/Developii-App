import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_tax.dart';
import 'package:developify_mobile/features/investor/presentation/stores/kyc_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_selection_card.dart';

class KycTaxNotice extends StatelessWidget {
  const KycTaxNotice({super.key, required this.text, this.pep = false});
  final String text;
  final bool pep;
  @override
  Widget build(BuildContext context) => InvestorSurface(
    color: pep ? AppColors.warningSurface : AppColors.bluePale,
    border: pep ? AppColors.investorPepBorder : AppColors.investorTaxBorder,
    radius: 14,
    padding: EdgeInsets.fromLTRB(
      (pep ? 16 : 15).w,
      (pep ? 13 : 10).w,
      15.w,
      (pep ? 13 : 10).w,
    ),
    child: Text.rich(
      TextSpan(
        children: pep && text.contains('Enhanced Due Diligence')
            ? [
                TextSpan(text: text.split('Enhanced Due Diligence').first),
                const TextSpan(
                  text: 'Enhanced Due Diligence',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: text.split('Enhanced Due Diligence').last),
              ]
            : [TextSpan(text: text)],
      ),
      style: AppTextStyles.text(
        12,
        height: 17 / 12,
        color: pep ? AppColors.investorPepText : AppColors.black,
      ),
    ),
  );
}

class KycTaxDeclarations extends StatelessWidget {
  const KycTaxDeclarations({super.key, required this.store});
  final KycStore store;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Sanctions Check',
        style: AppTextStyles.text(14, weight: FontWeight.w500),
      ),
      SizedBox(height: 12.w),
      for (final (index, field) in KycTaxPlan.declarations.indexed) ...[
        if (index > 0) SizedBox(height: 12.w),
        KycSelectionCard(
          declaration: true,
          label: field.label,
          selected: store.draft!.values[field.key] == 'true',
          onTap: store.busy || !store.editable
              ? null
              : () => store.edit(
                  field.key,
                  store.draft!.values[field.key] == 'true' ? 'false' : 'true',
                ),
        ),
        if (store.errors[field.key] case final error?) InlineError(error),
      ],
    ],
  );
}

class KycTaxChoice extends StatelessWidget {
  const KycTaxChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.radio = false,
    this.centered = false,
  });
  final String label;
  final String? subtitle;
  final bool selected;
  final bool radio;
  final bool centered;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    enabled: onTap != null,
    child: Material(
      color: selected
          ? AppColors.mint
          : radio || subtitle != null
          ? AppColors.investorCard
          : AppColors.border,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular((subtitle == null ? 14 : 10).r),
        side: BorderSide(
          color: selected
              ? AppColors.primary
              : subtitle == null
              ? AppColors.borderStrong
              : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular((subtitle == null ? 14 : 10).r),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                (subtitle == null
                        ? 50.w
                        : radio
                        ? 74.w
                        : 92.w)
                    .clamp(50, double.infinity),
          ),
          child: Padding(
            padding: centered && subtitle != null
                ? EdgeInsets.fromLTRB(12.w, 24.w, 12.w, 14.w)
                : EdgeInsets.symmetric(
                    horizontal: (radio ? 6 : 12).w,
                    vertical: 16.w,
                  ),
            child: Row(
              crossAxisAlignment: centered && subtitle != null
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                if (radio) ...[
                  AppIcon(
                    selected
                        ? AppAssets.radioSelected
                        : AppAssets.radioUnselected,
                    size: 32,
                  ),
                  SizedBox(width: 16.w),
                ],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: centered
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        textAlign: centered
                            ? TextAlign.center
                            : TextAlign.start,
                        style: AppTextStyles.text(
                          14,
                          weight: subtitle == null
                              ? FontWeight.w500
                              : FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: radio ? 7.w : 8.w),
                        Text(
                          subtitle!,
                          textAlign: centered
                              ? TextAlign.center
                              : TextAlign.start,
                          style: AppTextStyles.text(
                            radio ? 14 : 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ],
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

class KycTaxFieldRow extends StatelessWidget {
  const KycTaxFieldRow({super.key, required this.children, this.gap = 18});
  final List<Widget> children;
  final double gap;
  @override
  Widget build(BuildContext context) {
    final stacked = MediaQuery.textScalerOf(context).scale(14) > 18;
    return stacked
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, child) in children.indexed) ...[
                if (index > 0) SizedBox(height: 16.w),
                child,
              ],
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (index, child) in children.indexed) ...[
                if (index > 0) SizedBox(width: gap.w),
                Expanded(child: child),
              ],
            ],
          );
  }
}
