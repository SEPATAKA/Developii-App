import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/utils/money.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';

class WithdrawalReview extends StatelessWidget {
  const WithdrawalReview({
    super.key,
    required this.amount,
    required this.fee,
    required this.received,
    required this.method,
  });
  final MonetaryAmount amount;
  final MonetaryAmount fee;
  final MonetaryAmount received;
  final InvestorPaymentMethod? method;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      InvestorSurface(
        radius: 11,
        border: AppColors.border,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 18.w),
        child: Column(
          children: [
            Text(
              'You’ll receive',
              style: AppTextStyles.text(
                14,
                color: AppColors.muted,
                weight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 10.w),
            Text(
              Money.amount(received),
              textAlign: TextAlign.center,
              style: AppTextStyles.text(
                36,
                weight: FontWeight.w700,
                letterSpacing: -.72,
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 21.w),
      InvestorSurface(
        radius: 8,
        border: AppColors.border,
        padding: EdgeInsets.fromLTRB(12.w, 18.w, 12.w, 1.w),
        child: Column(
          children: [
            _DetailRow(
              'Amount',
              Money.amount(amount, decimals: amount.minorUnits % 100 != 0),
            ),
            _DetailRow('Processing fee', Money.amount(fee)),
            _DetailRow(
              'Recipient’s Name',
              method?.holder ?? 'No recipient selected',
            ),
            _DetailRow('Recipient’s Bank', method?.name ?? 'No bank selected'),
            _DetailRow(
              'Recipient’s Account Number',
              method == null
                  ? 'No account selected'
                  : '**** ${method!.lastFour}',
            ),
            const _DetailRow('ETA', 'Instant (demo)'),
          ],
        ),
      ),
      SizedBox(height: 21.w),
      InvestorSurface(
        color: AppColors.warningSurface,
        border: AppColors.investorPepBorder,
        radius: 14,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 17.w),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 46.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppIcon(AppAssets.payoutWarning, size: 18),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'This is a demo withdrawal. No money is sent to a bank.',
                  style: AppTextStyles.text(
                    14,
                    color: AppColors.amber900,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 6.w),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.text(
              14,
              height: 26 / 14,
              letterSpacing: -.28,
              weight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.text(
              16,
              height: 26 / 16,
              letterSpacing: -.32,
              weight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
