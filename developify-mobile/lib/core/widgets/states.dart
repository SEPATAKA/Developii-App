import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(semanticsLabel: 'Loading', strokeWidth: 2),
  );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: EdgeInsets.all(24.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIcon(
            AppAssets.profileMenuAbout,
            size: 44,
            color: AppColors.error,
          ),
          SizedBox(height: 16.h),
          Text(message, textAlign: TextAlign.center, style: AppTextStyles.body),
          SizedBox(height: 24.h),
          AppButton(label: 'Try again', onPressed: onRetry),
        ],
      ),
    ),
  );
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.title,
    required this.message,
    this.icon = AppAssets.navPropertiesActive,
    this.action,
  });
  final String title;
  final String message;
  final String icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 32.h),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: const BoxDecoration(
            color: AppColors.mint,
            shape: BoxShape.circle,
          ),
          child: AppIcon(icon, size: 44, color: AppColors.primary),
        ),
        SizedBox(height: 25.h),
        Text(title, textAlign: TextAlign.center, style: AppTextStyles.title),
        SizedBox(height: 12.h),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.text(14, color: AppColors.muted, height: 1.4),
        ),
        if (action != null) ...[SizedBox(height: 24.h), action!],
      ],
    ),
  );
}

class InlineError extends StatelessWidget {
  const InlineError(this.message, {super.key});
  final String? message;
  @override
  Widget build(BuildContext context) => message == null
      ? const SizedBox.shrink()
      : Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Semantics(
            liveRegion: true,
            child: Text(
              message!,
              style: AppTextStyles.text(13, color: AppColors.error),
            ),
          ),
        );
}
