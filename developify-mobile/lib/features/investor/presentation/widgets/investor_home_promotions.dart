import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

enum InvestorHomePromotion { calculator, portfolio }

class InvestorHomePromotions extends StatelessWidget {
  const InvestorHomePromotions({
    super.key,
    this.promotion = InvestorHomePromotion.calculator,
  });
  final InvestorHomePromotion promotion;

  @override
  Widget build(BuildContext context) =>
      promotion == InvestorHomePromotion.calculator
      ? const _CalculatorPromotion()
      : const _PortfolioPromotion();
}

class _CalculatorPromotion extends StatelessWidget {
  const _CalculatorPromotion();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // Scale the accepted 370:92 composition once from its available width.
      // Only the two live text widgets use fixed visual scaling; surrounding
      // content retains system text scaling and the banner remains accessible.
      final unit = constraints.maxWidth / 370;
      return Semantics(
        button: true,
        label: 'Investment calculator',
        child: Material(
          color: AppColors.mint,
          borderRadius: BorderRadius.circular(14 * unit),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.pushNamed(InvestorRoutes.calculatorProjects),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: 92 * unit),
              child: Stack(
                alignment: Alignment.centerRight,
                children: [
                  Positioned(
                    right: 0,
                    width: 152 * unit,
                    height: 92 * unit,
                    child: ClipRect(
                      key: const ValueKey('promotion-artwork'),
                      child: OverflowBox(
                        alignment: Alignment.centerRight,
                        minWidth: 168 * unit,
                        maxWidth: 168 * unit,
                        child: SvgPicture.asset(
                          AppAssets.investorCalculator,
                          width: 168 * unit,
                          height: 92 * unit,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        21.0569 * unit,
                        16 * unit,
                        160 * unit,
                        18 * unit,
                      ),
                      child: Column(
                        key: const ValueKey('promotion-copy'),
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Try the investment calculator',
                            textScaler: TextScaler.noScaling,
                            style: AppTextStyles.text(
                              15.0588,
                              weight: FontWeight.w700,
                              color: AppColors.investorCalculatorText,
                            ).copyWith(fontSize: 15.0588 * unit),
                          ),
                          SizedBox(height: 7.5294 * unit),
                          Text(
                            'See projected return before\nyou commit',
                            textScaler: TextScaler.noScaling,
                            style: AppTextStyles.text(
                              13.17647,
                              color: AppColors.investorCalculatorBody,
                            ).copyWith(fontSize: 13.17647 * unit),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _PortfolioPromotion extends StatelessWidget {
  const _PortfolioPromotion();

  @override
  Widget build(BuildContext context) {
    final enlarged = MediaQuery.textScalerOf(context).scale(14.sp) > 14.sp;
    final artworkWidth = 116.w;
    return SizedBox(
      width: double.infinity,
      child: Semantics(
        button: true,
        label: 'Portfolio insights',
        child: Material(
          color: AppColors.mint,
          borderRadius: BorderRadius.circular(14.w),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.pushNamed(InvestorRoutes.analytics),
            child: Stack(
              children: [
                Positioned(
                  right: 0,
                  bottom: 0,
                  width: artworkWidth,
                  height: 92.w,
                  child: ClipRect(
                    key: const ValueKey('promotion-artwork'),
                    child: OverflowBox(
                      alignment: Alignment.centerRight,
                      minWidth: 116.w,
                      maxWidth: 116.w,
                      child: SvgPicture.asset(
                        AppAssets.investorPortfolioPromotion,
                        width: 116.w,
                        height: 92.w,
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    21.w,
                    12.w,
                    enlarged ? 21.w : artworkWidth + 8.w,
                    (enlarged ? 104 : 15).w,
                  ),
                  child: Column(
                    key: const ValueKey('promotion-copy'),
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unlock Your Investment Potential',
                        style: AppTextStyles.text(
                          13,
                          weight: FontWeight.w700,
                          color: AppColors.investorCalculatorText,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 4.w),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: (enlarged ? double.infinity : 225.w),
                        ),
                        child: Text(
                          'Measure the strength of your portfolio and discover how well your investments are positioned for growth.',
                          style: AppTextStyles.text(
                            11,
                            color: AppColors.investorCalculatorBody,
                            height: 1.2,
                          ),
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
}

class InvestorRecentActivityEmpty extends StatelessWidget {
  const InvestorRecentActivityEmpty({super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Image.asset(
        AppAssets.investorActivityEmpty,
        width: 232.w,
        height: 214.w,
        excludeFromSemantics: true,
      ),
      SizedBox(height: 23.w),
      Text(
        'Ready to grow?',
        textAlign: TextAlign.center,
        style: AppTextStyles.text(
          13.17647,
          weight: FontWeight.w700,
          color: AppColors.primary,
          height: 16 / 13.17647,
        ),
      ),
      SizedBox(height: 7.w),
      SizedBox(
        width: 262.w,
        child: Text(
          'Every portfolio starts with one decision. Make yours today.',
          textAlign: TextAlign.center,
          style: AppTextStyles.text(
            14,
            color: AppColors.iconMuted,
            height: 17 / 14,
          ),
        ),
      ),
    ],
  );
}
