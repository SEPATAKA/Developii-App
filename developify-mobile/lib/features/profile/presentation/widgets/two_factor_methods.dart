import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';

class TwoFactorMethods extends StatelessWidget {
  const TwoFactorMethods({
    super.key,
    required this.onSms,
    required this.onAuthenticator,
    this.simulated = false,
  });
  final VoidCallback onSms;
  final VoidCallback onAuthenticator;
  final bool simulated;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 352.w,
        child: Text(
          '2Factor Authentication',
          style: AppTextStyles.text(
            29.495958,
            weight: FontWeight.w700,
            height: 35 / 29.495958,
          ),
        ),
      ),
      SizedBox(height: 8.w),
      SizedBox(
        width: 352.w,
        child: Text(
          'Two- Factor Authentication requires a verification code sent to your phone or generated via authenticator app.',
          style: AppTextStyles.text(
            16.09143,
            color: AppColors.muted,
            height: 19 / 16.09143,
          ),
        ),
      ),
      SizedBox(height: 18.w),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 17.w, vertical: 20.w),
        decoration: BoxDecoration(
          color: AppColors.slate50,
          border: Border.all(color: AppColors.slate100),
          borderRadius: BorderRadius.circular(8.w),
        ),
        child: Column(
          children: [
            _method(
              'SMS Authentication',
              simulated
                  ? 'Try SMS verification with a test phone number.'
                  : 'We’ll send a code via sms when you sign in',
              AppAssets.securitySms,
              onSms,
            ),
            SizedBox(height: 29.w),
            _method(
              'Authenticator App',
              simulated
                  ? 'Try a sample QR code without linking a live account.'
                  : 'Scan this QR code using your app to link your account.',
              AppAssets.securityAuthenticator,
              onAuthenticator,
            ),
          ],
        ),
      ),
    ],
  );
  Widget _method(
    String title,
    String description,
    String icon,
    VoidCallback onTap,
  ) => InkWell(
    onTap: onTap,
    child: Row(
      children: [
        AppIcon(icon),
        SizedBox(width: 19.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.text(
                  16,
                  weight: FontWeight.w600,
                  color: AppColors.black,
                  height: 19 / 16,
                ),
              ),
              SizedBox(height: 3.w),
              Text(
                description,
                style: AppTextStyles.text(
                  14,
                  color: AppColors.slate500,
                  height: 17 / 14,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 21.w),
        const AppIcon(AppAssets.securityMethodChevron, size: 24.49123),
      ],
    ),
  );
}
