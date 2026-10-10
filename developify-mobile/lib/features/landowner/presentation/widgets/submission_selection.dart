import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';

class SubmissionCheckbox extends StatelessWidget {
  const SubmissionCheckbox({super.key, required this.selected});
  final bool selected;
  @override
  Widget build(BuildContext context) => Container(
    width: 20.w,
    height: 20.w,
    decoration: BoxDecoration(
      color: selected ? AppColors.primary : AppColors.white,
      borderRadius: BorderRadius.circular(4.w),
      border: selected
          ? null
          : Border.all(color: AppColors.neutral300, width: 2.w),
    ),
    child: selected
        ? const OverflowBox(
            minWidth: 24,
            maxWidth: 24,
            minHeight: 24,
            maxHeight: 24,
            child: AppIcon(AppAssets.submissionCheck),
          )
        : null,
  );
}

class SubmissionDealChoice extends StatelessWidget {
  const SubmissionDealChoice({
    super.key,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.w),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.w),
        child: Padding(
          padding: EdgeInsets.fromLTRB(19.w, 16.w, 15.w, 13.w),
          child: Row(
            children: [
              SubmissionCheckbox(selected: selected),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.text(
                        14,
                        weight: FontWeight.w600,
                        color: AppColors.text,
                        height: 17 / 14,
                      ),
                    ),
                    SizedBox(height: 7.w),
                    Text(
                      description,
                      style: AppTextStyles.text(
                        14,
                        color: AppColors.muted,
                        height: 17 / 14,
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
  );
}

class SubmissionValuationSwitch extends StatelessWidget {
  const SubmissionValuationSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Semantics(
    toggled: value,
    label: 'Valuation Report',
    child: InkResponse(
      onTap: () => onChanged(!value),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Container(
            width: 36.w,
            height: 20.w,
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: value ? AppColors.primary : AppColors.neutral300,
              borderRadius: BorderRadius.circular(999.w),
            ),
            child: Align(
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 16.w,
                height: 16.w,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
