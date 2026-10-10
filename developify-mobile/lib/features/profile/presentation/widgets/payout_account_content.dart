import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/features/profile/domain/profile_repository.dart';
import 'package:developify_mobile/features/profile/presentation/widgets/payout_notice.dart';

class PayoutAccountContent extends StatelessWidget {
  const PayoutAccountContent({
    super.key,
    required this.account,
    required this.onAdd,
    required this.onHistory,
  });
  final PayoutAccount? account;
  final VoidCallback onAdd;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final payout = account;
    if (payout == null) {
      return ListView(
        padding: EdgeInsets.only(top: 258.w, bottom: 12.w),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 17.w),
            child: Column(
              children: [
                Text(
                  'No Payout Account Added Yet',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.text(
                    16,
                    weight: FontWeight.w600,
                    height: 19 / 16,
                  ),
                ),
                SizedBox(height: 12.w),
                Text(
                  "It looks like you haven't entered your bank information yet. Please provide your bank details to enable payment payouts",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.text(
                    16,
                    color: AppColors.muted,
                    height: 19 / 16,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 19.w),
          AppButton(
            label: 'Add Bank Account',
            style: AppButtonStyle.secondary,
            onPressed: onAdd,
          ),
        ],
      );
    }
    return ListView(
      padding: EdgeInsets.only(top: 19.w, bottom: 9.w),
      children: [
        Container(
          key: const ValueKey('payout-account-card'),
          constraints: BoxConstraints(minHeight: 140.w),
          padding: EdgeInsets.fromLTRB(18.w, 26.w, 15.w, 24.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19.62058.w),
            image: const DecorationImage(
              image: AssetImage(AppAssets.payoutPattern),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Verified payouts account',
                      style: AppTextStyles.text(
                        14,
                        weight: FontWeight.w500,
                        color: AppColors.surface,
                        height: 17 / 14,
                      ),
                    ),
                  ),
                  Text(
                    '**** **** ${payout.lastFour}',
                    style: AppTextStyles.text(
                      14,
                      weight: FontWeight.w500,
                      color: AppColors.surface,
                      height: 17 / 14,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18.w),
              Text(
                payout.bank,
                style: AppTextStyles.text(
                  24,
                  weight: FontWeight.w700,
                  color: AppColors.surface,
                  height: 29 / 24,
                ),
              ),
              SizedBox(height: 9.w),
              Row(
                children: [
                  Text(
                    '${payout.holder.substring(0, 1)}  ${payout.holder.split(' ').last}',
                    style: AppTextStyles.text(
                      14,
                      weight: FontWeight.w500,
                      color: AppColors.surface,
                      height: 17 / 14,
                    ),
                  ),
                  SizedBox(width: 9.w),
                  Container(
                    width: 4.w,
                    height: 4.w,
                    decoration: const BoxDecoration(
                      color: AppColors.iconMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 9.w),
                  Flexible(
                    child: Text(
                      'Branch - ${payout.branchCode}',
                      style: AppTextStyles.text(
                        14,
                        weight: FontWeight.w500,
                        color: AppColors.surface,
                        height: 17 / 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 16.w),
        Container(
          padding: EdgeInsets.fromLTRB(11.w, 20.w, 11.w, 19.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8.w),
          ),
          child: Column(
            children: [
              for (final item in [
                ('Account Holder', payout.holder),
                ('Account Type', payout.type),
                ('Verfied on', '12 Mar 2026'),
                ('Method', 'Online verification'),
                ('Used  for', 'All lease & sale payouts'),
              ]) ...[
                if (item.$1 != 'Account Holder') SizedBox(height: 12.w),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.$1,
                        style: AppTextStyles.text(
                          14,
                          weight: FontWeight.w500,
                          color: AppColors.muted,
                          height: 26 / 14,
                        ),
                      ),
                    ),
                    Flexible(
                      flex: 2,
                      child: Text(
                        item.$2,
                        textAlign: TextAlign.right,
                        style: AppTextStyles.text(
                          16,
                          weight: FontWeight.w600,
                          color: AppColors.gray900,
                          height: 26 / 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 16.w),
        const PayoutNotice(
          overview: true,
          message:
              'Changing your payout account triggers a 48-hour security hold and re-verification. Payouts scheduled inside that window are delayed, not cancelled.',
        ),
        SizedBox(height: 88.w),
        AppButton(label: 'Change payout account', onPressed: onAdd),
        SizedBox(height: 15.w),
        AppButton(
          label: 'View last payouts',
          style: AppButtonStyle.secondary,
          onPressed: onHistory,
        ),
      ],
    );
  }
}
