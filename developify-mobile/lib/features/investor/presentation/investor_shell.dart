import 'package:developify_mobile/core/widgets/adaptive_navigation_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';

class InvestorShell extends StatelessWidget {
  const InvestorShell({super.key, required this.shell});
  final StatefulNavigationShell shell;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: shell,
    bottomNavigationBar: DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(9.w, 4.w, 9.w, 2.w),
          child: AdaptiveNavigationRow(
            labels: const ['Home', 'Explore', 'Wallet', 'Portfolio', 'Profile'],
            children: [
              for (final (index, item) in const [
                (
                  'Home',
                  AppAssets.investorHomeActive,
                  AppAssets.investorHomeInactive,
                ),
                (
                  'Explore',
                  AppAssets.investorExploreActive,
                  AppAssets.investorExploreInactive,
                ),
                (
                  'Wallet',
                  AppAssets.investorWalletActive,
                  AppAssets.investorWalletInactive,
                ),
                (
                  'Portfolio',
                  AppAssets.investorPortfolioActive,
                  AppAssets.investorPortfolioInactive,
                ),
                (
                  'Profile',
                  AppAssets.investorProfileActive,
                  AppAssets.investorProfileInactive,
                ),
              ].indexed)
                Semantics(
                  button: true,
                  selected: index == shell.currentIndex,
                  label: item.$1,
                  child: InkWell(
                    onTap: () => shell.goBranch(index),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: 57.w),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppIcon(
                              index == shell.currentIndex ? item.$2 : item.$3,
                              size: 24,
                            ),
                            SizedBox(height: 4.w),
                            Text(
                              item.$1,
                              style: AppTextStyles.text(
                                12,
                                color: index == shell.currentIndex
                                    ? AppColors.primary
                                    : AppColors.iconMuted,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
