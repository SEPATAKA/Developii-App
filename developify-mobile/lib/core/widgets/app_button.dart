import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';

enum AppButtonStyle { primary, secondary, outline, mintOutline, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.style = AppButtonStyle.primary,
    this.icon,
    this.iconSize = 18,
    this.iconGap = 10,
    this.disabledBackgroundColor,
    this.disabledForegroundColor,
    this.backgroundColor,
    this.foregroundColor,
    this.labelSize = 16,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final AppButtonStyle style;
  final String? icon;
  final double iconSize;
  final double iconGap;
  final Color? disabledBackgroundColor;
  final Color? disabledForegroundColor;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double labelSize;
  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final background = !enabled && !loading
        ? disabledBackgroundColor ?? AppColors.disabled
        : backgroundColor ??
              switch (style) {
                AppButtonStyle.primary => AppColors.primary,
                AppButtonStyle.danger => AppColors.error,
                AppButtonStyle.secondary => AppColors.secondaryButton,
                AppButtonStyle.mintOutline => AppColors.mint,
                _ => AppColors.surface,
              };
    final foreground = !enabled && !loading
        ? disabledForegroundColor ?? AppColors.placeholder
        : foregroundColor ??
              switch (style) {
                AppButtonStyle.primary ||
                AppButtonStyle.danger => AppColors.white,
                AppButtonStyle.outline => AppColors.text,
                AppButtonStyle.mintOutline => AppColors.mintText,
                _ => AppColors.primary,
              };
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: enabled
            ? () {
                FocusManager.instance.primaryFocus?.unfocus();
                onPressed!();
              }
            : null,
        style: TextButton.styleFrom(
          minimumSize: Size(double.infinity, 48.w.clamp(48, 62)),
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.w),
          backgroundColor: background,
          foregroundColor: foreground,
          disabledForegroundColor: foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.pill.r),
            side: style == AppButtonStyle.mintOutline
                ? const BorderSide(color: AppColors.primary)
                : style == AppButtonStyle.outline
                ? const BorderSide(color: AppColors.border)
                : BorderSide.none,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: AnimatedSwitcher(
          duration: AppDurations.motion(context, AppDurations.state),
          child: loading
              ? SizedBox.square(
                  dimension: 24.r,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                    semanticsLabel: 'Loading',
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      AppIcon(icon!, size: iconSize),
                      SizedBox(width: iconGap.w),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.text(
                          labelSize,
                          weight: FontWeight.w500,
                          color: foreground,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
