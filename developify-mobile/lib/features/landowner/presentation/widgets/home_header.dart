import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/utils/money.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/widgets/app_chrome.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/features/landowner/presentation/widgets/balance_summary.dart';
import 'package:developify_mobile/features/landowner/presentation/stores/home_store.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.store,
    required this.displayName,
    required this.onProfile,
    required this.onMessages,
    required this.onNotifications,
    required this.onExperience,
  });

  final HomeStore store;
  final String displayName;
  final VoidCallback onProfile;
  final VoidCallback onMessages;
  final VoidCallback onNotifications;
  final VoidCallback onExperience;

  @override
  Widget build(BuildContext context) => MeshBackground(
    child: Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 14.w,
        bottom: 30.w,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 15.w, right: 106.w),
                child: Row(
                  children: [
                    Semantics(
                      button: true,
                      label: 'Open profile',
                      child: InkWell(
                        onTap: onProfile,
                        child: ClipOval(
                          child: Image.asset(
                            AppAssets.avatar,
                            width: 40.w,
                            height: 40.w,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good Morning!',
                            style: AppTextStyles.text(
                              12,
                              color: AppColors.lime,
                              height: 18 / 12,
                            ).copyWith(letterSpacing: -.48.sp),
                          ),
                          SizedBox(height: 5.w),
                          Text(
                            displayName,
                            style: AppTextStyles.text(
                              14,
                              weight: FontWeight.w600,
                              color: AppColors.white,
                              height: 16 / 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 44.w,
                top: -1.w,
                child: AppIconButton(
                  asset: AppAssets.headerChat,
                  label: 'Messages',
                  onPressed: onMessages,
                ),
              ),
              Positioned(
                right: 11.w,
                top: -1.w,
                child: AppIconButton(
                  asset: AppAssets.headerNotification,
                  label: 'Notifications',
                  onPressed: onNotifications,
                ),
              ),
            ],
          ),
          SizedBox(height: 44.w),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Observer(
                  builder: (_) => Padding(
                    padding: EdgeInsets.zero,
                    child: BalanceSummary(
                      label: 'Total Earnings to date',
                      trailingSpace: 44,
                      visible: store.balanceVisible,
                      onVisibilityChanged: store.toggleBalance,
                      amount: Money.rand(store.data?.earnedCents ?? 0),
                      payout: (store.data?.nextPayoutCents ?? 0) <= 0
                          ? null
                          : Money.amount(
                              MonetaryAmount(
                                store.data!.nextPayoutCents,
                                Currency.zar,
                              ),
                              decimals: false,
                            ),
                      payoutTiming: 'in 19 days',
                    ),
                  ),
                ),
                Positioned(
                  right: -1.w,
                  top: MediaQuery.textScalerOf(context).scale(14.sp) > 14.sp
                      ? 0
                      : 19.w,
                  child: AppIconButton(
                    asset: AppAssets.headerExperience,
                    label: 'Switch experience',
                    onPressed: onExperience,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 25.w),
          Padding(
            padding: EdgeInsets.only(left: 12.w, right: 15.w),
            child: Observer(
              builder: (_) => Row(
                children: [
                  for (final (index, value) in [
                    ('${store.data?.propertyCount ?? 0}', 'Properties'),
                    ('${store.data?.approvedCount ?? 0}', 'Approved'),
                    (
                      store.balanceVisible
                          ? Money.compact(
                              MonetaryAmount(
                                store.data?.earnedCents ?? 0,
                                Currency.zar,
                              ),
                              lowercaseSuffix: true,
                            )
                          : '****',
                      'Earned',
                    ),
                  ].indexed) ...[
                    if (index > 0) SizedBox(width: 6.w),
                    Expanded(
                      child: Container(
                        key: ValueKey('home-stat-$index'),
                        constraints: BoxConstraints(minHeight: 64.w),
                        padding: EdgeInsets.only(
                          top: (index == 1 ? 16.418 : 15).w,
                          bottom: (index == 1 ? 14.582 : 16).w,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.glass,
                          borderRadius: BorderRadius.circular(15.w),
                        ),
                        child: Column(
                          children: [
                            Text(
                              value.$1,
                              style: AppTextStyles.text(
                                15.453,
                                weight: FontWeight.w600,
                                color: AppColors.primary,
                                height: 19 / 15.453,
                              ),
                            ),
                            Text(
                              value.$2,
                              style: AppTextStyles.text(
                                12,
                                color: AppColors.white,
                                height: 14 / 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
