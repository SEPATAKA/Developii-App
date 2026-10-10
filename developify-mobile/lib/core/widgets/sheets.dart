import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';

Future<T?> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required Map<T, String> choices,
  T? selected,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) => SafeArea(
    top: false,
    child: Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTextStyles.title)),
              AppIconButton(
                asset: AppAssets.sheetClose,
                label: 'Close',
                color: AppColors.muted,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .6,
            ),
            child: ListView(
              shrinkWrap: true,
              children: choices.entries
                  .map(
                    (entry) => ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 4.w),
                      title: Text(
                        entry.value,
                        style: AppTextStyles.text(16, weight: FontWeight.w500),
                      ),
                      trailing: SizedBox.square(
                        dimension: 22.r,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: entry.key == selected
                                  ? AppColors.primary
                                  : AppColors.borderStrong,
                              width: entry.key == selected ? 6 : 1,
                            ),
                          ),
                        ),
                      ),
                      onTap: () => Navigator.pop(context, entry.key),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    ),
  ),
);

Future<void> showSuccessSheet(
  BuildContext context, {
  required String title,
  required String message,
  String button = 'Continue',
  VoidCallback? onContinue,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: AppIconButton(
                asset: AppAssets.sheetClose,
                label: 'Close',
                color: AppColors.muted,
                onPressed: () => Navigator.pop(sheetContext),
              ),
            ),
            SizedBox(height: 8.h),
            const AppIcon(AppAssets.securitySuccess, size: 100),
            SizedBox(height: 32.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.title,
            ),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            SizedBox(height: 40.h),
            AppButton(
              label: button,
              onPressed: () => Navigator.pop(sheetContext),
            ),
          ],
        ),
      ),
    ),
  );
  if (context.mounted) onContinue?.call();
}

Future<bool> confirmExit(BuildContext context) async =>
    await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Leave without saving?', style: AppTextStyles.title),
              SizedBox(height: 12.h),
              Text(
                'Your unsaved changes will be lost.',
                style: AppTextStyles.body,
              ),
              SizedBox(height: 24.h),
              AppButton(
                label: 'Keep editing',
                onPressed: () => Navigator.pop(context, false),
              ),
              SizedBox(height: 12.h),
              AppButton(
                label: 'Leave',
                style: AppButtonStyle.secondary,
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ),
      ),
    ) ??
    false;
