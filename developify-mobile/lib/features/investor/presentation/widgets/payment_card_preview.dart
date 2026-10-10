import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';

class PaymentCardPreview extends StatelessWidget {
  const PaymentCardPreview({
    super.key,
    required this.method,
    this.compact = false,
  });

  final InvestorPaymentMethod method;
  final bool compact;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '${method.name} ending ${method.lastFour}, ${method.holder}, '
        'expires ${method.expiry}${method.isDefault ? ', default card' : ''}',
    excludeSemantics: true,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(19.6206.r),
      child: ColoredBox(
        color: AppColors.investorLink,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 79.w,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: SvgPicture.asset(
                      AppAssets.investorCardPattern,
                      fit: BoxFit.fill,
                    ),
                  ),
                  Positioned(
                    left: 26.1602.w,
                    top: 26.1609.w,
                    child: SvgPicture.asset(
                      AppAssets.investorCardContactless,
                      width: 58.323.w,
                      height: 32.701.w,
                    ),
                  ),
                  Positioned(
                    right: 33.w,
                    top: 23.9807.w,
                    child: method.name == 'Visa'
                        ? SvgPicture.asset(
                            AppAssets.investorCardVisa,
                            width: 77.764.w,
                            height: 43.6013.w,
                          )
                        : Text(
                            method.name,
                            style: AppTextStyles.text(
                              20,
                              weight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                26.w,
                (compact ? 14 : 30).w,
                18.w,
                (compact ? 17 : 29).w,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var index = 0; index < 12; index++) ...[
                        Container(
                          width: 4.w,
                          height: 4.w,
                          decoration: const BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: (index == 11 ? 8 : 7.6).w),
                      ],
                      Text(
                        method.lastFour,
                        style: AppTextStyles.text(
                          17.4405,
                          weight: FontWeight.w500,
                          height: 28 / 17.4405,
                          color: AppColors.white,
                          letterSpacing: -.34881,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: (compact ? 11 : 36).w),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          method.holder,
                          style: AppTextStyles.text(
                            14,
                            height: 16 / 14,
                            color: AppColors.white.withValues(alpha: .8),
                            letterSpacing: .56,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Exp ${method.expiry}',
                        style: AppTextStyles.text(
                          13.0804,
                          height: 16 / 13.0804,
                          color: AppColors.white,
                          letterSpacing: .5232,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
