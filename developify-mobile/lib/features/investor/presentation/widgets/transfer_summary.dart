import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/utils/money.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';

class TransferFees extends StatelessWidget {
  const TransferFees({
    super.key,
    required this.amount,
    required this.fee,
    required this.bankDeposit,
  });
  final MonetaryAmount amount;
  final MonetaryAmount fee;
  final bool bankDeposit;

  @override
  Widget build(BuildContext context) => _TransferPanel(
    children: [
      _TransferDetailRow(bankDeposit ? 'Fee' : 'Fee (1.5%)', Money.amount(fee)),
      _TransferDetailRow(
        'You’ll receive',
        Money.amount(amount, decimals: amount.minorUnits % 100 != 0),
        highlighted: true,
      ),
    ],
  );
}

class TransferReview extends StatelessWidget {
  const TransferReview({
    super.key,
    required this.amount,
    required this.fee,
    required this.method,
  });
  final MonetaryAmount amount;
  final MonetaryAmount fee;
  final InvestorPaymentMethod? method;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      InvestorSurface(
        radius: 12,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 22.w),
        child: Column(
          children: [
            Text(
              'You are adding',
              textAlign: TextAlign.center,
              style: AppTextStyles.text(
                14,
                color: AppColors.iconMuted,
                weight: FontWeight.w500,
              ),
            ),
            Text(
              Money.amount(amount, spaceAfterSymbol: true),
              textAlign: TextAlign.center,
              style: AppTextStyles.text(
                48,
                weight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            Text(
              'to your Developify wallet',
              textAlign: TextAlign.center,
              style: AppTextStyles.text(
                14,
                color: AppColors.iconMuted,
                weight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 10.w),
      _TransferPanel(
        children: [
          _TransferDetailRow(
            'Method',
            method == null
                ? 'No payment method'
                : '${method!.name} • ${method!.lastFour}',
            strong: true,
          ),
          _TransferDetailRow('Fee', Money.amount(fee)),
          _TransferDetailRow(
            'Total payment',
            Money.amount(amount + fee),
            highlighted: true,
          ),
        ],
      ),
      SizedBox(height: 27.w),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppIcon(AppAssets.investorCardLock),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              method?.kind == PaymentMethodKind.bankAccount
                  ? 'This adds simulated funds to your demo wallet. No bank transfer is made.'
                  : 'This payment is simulated. Card details are not sent and the CVV is not retained.',
              style: AppTextStyles.text(
                14,
                weight: FontWeight.w400,
                color: AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class _TransferPanel extends StatelessWidget {
  const _TransferPanel({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => InvestorSurface(
    radius: 12,
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 11.5.w),
    child: Column(children: children),
  );
}

class _TransferDetailRow extends StatelessWidget {
  const _TransferDetailRow(
    this.label,
    this.value, {
    this.highlighted = false,
    this.strong = false,
  });
  final String label;
  final String value;
  final bool highlighted;
  final bool strong;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 8.5.w),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.text(
              16,
              color: AppColors.black,
              weight: FontWeight.w500,
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
              weight: highlighted || strong ? FontWeight.w600 : FontWeight.w500,
              color: highlighted ? AppColors.primary : AppColors.black,
            ),
          ),
        ),
      ],
    ),
  );
}
