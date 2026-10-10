import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';

class TransactionStatusBadge extends StatelessWidget {
  const TransactionStatusBadge(
    this.status, {
    super.key,
    this.mintSuccess = false,
  });
  final InvestorTransactionStatus status;
  final bool mintSuccess;

  static String label(InvestorTransactionStatus status) => switch (status) {
    InvestorTransactionStatus.successful => 'Successful',
    InvestorTransactionStatus.pending => 'Pending',
    InvestorTransactionStatus.failed => 'Failed',
  };

  @override
  Widget build(BuildContext context) {
    final (background, border, foreground) = switch (status) {
      InvestorTransactionStatus.successful => (
        mintSuccess
            ? AppColors.mint
            : AppColors.investorTransactionSuccessSurface,
        mintSuccess
            ? AppColors.mintBadgeBorder
            : AppColors.investorTransactionSuccessBorder,
        mintSuccess ? AppColors.primary : AppColors.investorTransactionSuccess,
      ),
      InvestorTransactionStatus.pending => (
        AppColors.pendingBadgeSurface,
        AppColors.pendingBadgeBorder,
        AppColors.warning,
      ),
      InvestorTransactionStatus.failed => (
        AppColors.errorSurface,
        AppColors.actionRequiredBorder,
        AppColors.error,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border, width: .8293.w),
        borderRadius: BorderRadius.circular(414.6341.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 4.8.w),
        child: Text(
          label(status),
          style: AppTextStyles.text(
            12,
            weight: FontWeight.w500,
            color: foreground,
          ),
        ),
      ),
    );
  }
}
