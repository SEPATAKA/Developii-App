import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/utils/date_format.dart';
import 'package:developify_mobile/core/utils/money.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/transaction_status_badge.dart';

class InvestorTransactionRow extends StatelessWidget {
  const InvestorTransactionRow({
    super.key,
    required this.transaction,
    required this.onTap,
    this.mintSuccess = false,
  });
  final InvestorTransaction transaction;
  final VoidCallback onTap;
  final bool mintSuccess;

  @override
  Widget build(BuildContext context) {
    final outgoing = transaction.amount.minorUnits < 0;
    final time = AppDateFormat.time12(
      transaction.createdAt.toLocal(),
    ).toLowerCase();
    final description = switch (transaction.kind) {
      InvestorTransactionKind.investment => 'Investment',
      InvestorTransactionKind.topUp =>
        transaction.paymentMethod?.name ?? 'Wallet Top up',
      InvestorTransactionKind.withdrawal =>
        transaction.paymentMethod == null
            ? 'Bank account'
            : '**** ${transaction.paymentMethod!.lastFour}',
      InvestorTransactionKind.distribution => 'Distribution',
      InvestorTransactionKind.refund => 'Refund',
    };
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 17;
    final amount = Text(
      Money.amount(
        transaction.amount,
        showPositiveSign: true,
        spaceAfterSymbol: true,
      ),
      style: AppTextStyles.text(
        16,
        weight: FontWeight.w600,
        color: outgoing ? AppColors.error : AppColors.investorTransactionCredit,
      ),
    );
    final title = Text(
      transaction.title,
      style: AppTextStyles.text(
        14,
        weight: FontWeight.w600,
        color: AppColors.black,
      ),
    );
    return Semantics(
      button: true,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 15.w, horizontal: 12.w),
            child: Row(
              children: [
                AppIcon(
                  outgoing
                      ? AppAssets.investorTransactionDebit
                      : AppAssets.investorTransactionCredit,
                  size: 44,
                ),
                SizedBox(width: 11.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (largeText) ...[
                        title,
                        SizedBox(height: 6.w),
                        amount,
                      ] else
                        Row(
                          children: [
                            Expanded(child: title),
                            SizedBox(width: 8.w),
                            amount,
                          ],
                        ),
                      SizedBox(height: 8.w),
                      if (largeText) ...[
                        Text(
                          '$description · $time',
                          style: AppTextStyles.text(
                            14,
                            weight: FontWeight.w500,
                            color: AppColors.muted,
                          ),
                        ),
                        SizedBox(height: 8.w),
                        TransactionStatusBadge(
                          transaction.status,
                          mintSuccess: mintSuccess,
                        ),
                      ] else
                        Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6.w,
                                children: [
                                  Text(
                                    description,
                                    style: AppTextStyles.text(
                                      14,
                                      weight: FontWeight.w500,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                  ExcludeSemantics(
                                    child: Container(
                                      width: 4.w,
                                      height: 4.w,
                                      decoration: const BoxDecoration(
                                        color: AppColors
                                            .investorTransactionSeparator,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    time,
                                    style: AppTextStyles.text(
                                      14,
                                      weight: FontWeight.w500,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8.w),
                            TransactionStatusBadge(
                              transaction.status,
                              mintSuccess: mintSuccess,
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
      ),
    );
  }
}
