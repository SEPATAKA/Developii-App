import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/utils/date_format.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';

Future<String?> showKycInviteSentSheet(
  BuildContext context, {
  required KycInviteReceipt receipt,
  required String recipient,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  barrierColor: AppColors.modalScrim,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(8.w)),
  ),
  builder: (context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(12.w, 0, 17.w, 3.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 99.w,
            child: Stack(
              children: [
                Positioned(
                  right: 0,
                  top: 32.3.w,
                  child: InvestorIconButton(
                    asset: AppAssets.investorModalClose,
                    size: 32.26,
                    label: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
          const AppIcon(AppAssets.investorTransferSuccess, size: 88),
          SizedBox(height: 20.w),
          Text(
            'Invite Sent!',
            style: AppTextStyles.text(
              29.32836,
              weight: FontWeight.w700,
              height: 35 / 29.32836,
            ),
          ),
          SizedBox(height: 6.w),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 23.w),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'A sample invitation for $recipient is saved for ',
                  ),
                  TextSpan(
                    text: receipt.email,
                    style: AppTextStyles.text(16, weight: FontWeight.w600),
                  ),
                  if (receipt.phone != null) ...[
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: receipt.phone,
                      style: AppTextStyles.text(16, weight: FontWeight.w600),
                    ),
                  ],
                  const TextSpan(text: '.'),
                ],
              ),
              textAlign: TextAlign.center,
              style: AppTextStyles.text(
                16,
                color: AppColors.muted,
                height: 19 / 16,
              ),
            ),
          ),
          SizedBox(height: 35.w),
          InvestorSurface(
            color: AppColors.surface,
            radius: 12,
            border: AppColors.border,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 0),
            child: Column(
              children: [
                for (final (label, value) in [
                  ('Reference', receipt.reference),
                  (
                    'Sent',
                    '${AppDateFormat.dayFirstDate(receipt.sentAt)}; ${AppDateFormat.time12(receipt.sentAt)}',
                  ),
                  (
                    'Demo link expires',
                    AppDateFormat.dayFirstDate(receipt.expiresAt),
                  ),
                ])
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: 40.w),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.w),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: AppTextStyles.text(
                                14,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Flexible(
                            flex: 2,
                            child: Text(
                              value,
                              textAlign: TextAlign.right,
                              style: AppTextStyles.text(
                                14,
                                weight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 18.w),
          InvestorSurface(
            color: AppColors.mint,
            radius: 12,
            border: AppColors.mintBorder,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.w),
            child: Text(
              'Invitations are simulated in this session. No email or text message has been sent.',
              style: AppTextStyles.text(14),
            ),
          ),
          SizedBox(height: 28.w),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            child: Column(
              children: [
                AppButton(
                  label: 'Track all invites',
                  onPressed: () => Navigator.pop(context, 'track'),
                ),
                SizedBox(height: 10.w),
                AppButton(
                  label: 'Back to resolution',
                  style: AppButtonStyle.secondary,
                  onPressed: () => Navigator.pop(context, 'resolution'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);
