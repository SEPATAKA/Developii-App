import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';

class AuthSocialButton extends StatelessWidget {
  const AuthSocialButton({
    super.key,
    required this.provider,
    required this.icon,
    required this.onPressed,
  });
  final String provider;
  final String icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: Size(double.infinity, 48.w.clamp(48, 62)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.fromLTRB(12.w, 12.w, 28.w, 12.w),
        backgroundColor: AppColors.disabled,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(500.w),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(icon, size: 20),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              'Sign In with $provider',
              textAlign: TextAlign.center,
              style: AppTextStyles.text(
                14,
                weight: FontWeight.w500,
                color: AppColors.black,
                height: 17 / 14,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
