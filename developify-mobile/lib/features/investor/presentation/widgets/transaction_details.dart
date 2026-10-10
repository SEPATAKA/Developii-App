import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/utils/date_format.dart';
import 'package:developify_mobile/core/utils/money.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/transaction_status_badge.dart';

class TransactionDetails extends StatelessWidget {
  const TransactionDetails({super.key, required this.transaction});
  final InvestorTransaction transaction;

  static String kindLabel(InvestorTransaction transaction) =>
      switch (transaction.kind) {
        InvestorTransactionKind.investment => 'Investment',
        InvestorTransactionKind.topUp => 'Wallet Top up',
        InvestorTransactionKind.withdrawal => 'Withdrawal',
        InvestorTransactionKind.distribution =>
          '${transaction.projectTerms?.name ?? transaction.title} Distribution',
        InvestorTransactionKind.refund => 'Refund',
      };

  static Future<void> previewReceipt(
    BuildContext context,
    InvestorTransaction transaction,
  ) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Receipt preview', style: AppTextStyles.section),
      scrollable: true,
      content: SelectableText(
        'Simulated receipt\n${kindLabel(transaction)}\n${Money.amount(transaction.amount, showPositiveSign: true, spaceAfterSymbol: true)}\n${TransactionStatusBadge.label(transaction.status)}\n${AppDateFormat.longDate(transaction.createdAt.toLocal())}, ${AppDateFormat.time12(transaction.createdAt.toLocal())}\n${transaction.reference}\n\nNo money was moved. No file is downloaded in this demo.',
        style: AppTextStyles.body,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final debit = transaction.amount.minorUnits < 0;
    final date = transaction.createdAt.toLocal();
    final method = transaction.paymentMethod;
    final project = transaction.projectTerms;
    final withdrawal = transaction.kind == InvestorTransactionKind.withdrawal;
    final bankTopUp =
        transaction.kind == InvestorTransactionKind.topUp &&
        method?.kind == PaymentMethodKind.bankAccount;
    return ListView(
      key: PageStorageKey('transaction-detail-${transaction.id}'),
      padding: EdgeInsets.only(top: 22.w, bottom: 24.w),
      children: [
        AppIcon(
          debit
              ? AppAssets.investorTransactionDebit
              : AppAssets.investorTransactionCredit,
          size: 44,
        ),
        SizedBox(height: 18.w),
        Text(
          kindLabel(transaction),
          textAlign: TextAlign.center,
          style: AppTextStyles.text(
            16,
            weight: FontWeight.w500,
            color: AppColors.gray900,
          ),
        ),
        SizedBox(height: 7.w),
        Text(
          Money.amount(
            transaction.amount,
            showPositiveSign: true,
            spaceAfterSymbol: true,
          ),
          textAlign: TextAlign.center,
          style: AppTextStyles.text(
            36,
            weight: FontWeight.w700,
            letterSpacing: .72,
            color: debit
                ? AppColors.error
                : AppColors.investorTransactionCredit,
          ),
        ),
        SizedBox(height: 7.w),
        Text(
          '${AppDateFormat.longDate(date)}; ${AppDateFormat.time12(date).toLowerCase()}',
          textAlign: TextAlign.center,
          style: AppTextStyles.text(
            16,
            weight: FontWeight.w500,
            height: 26 / 16,
            letterSpacing: -.32,
            color: AppColors.muted,
          ),
        ),
        SizedBox(height: 18.w),
        InvestorSurface(
          radius: 8,
          border: AppColors.border,
          padding: EdgeInsets.fromLTRB(
            12.w,
            18.w,
            12.w,
            (bankTopUp || withdrawal
                    ? 18
                    : transaction.kind == InvestorTransactionKind.distribution
                    ? 19
                    : 12)
                .w,
          ),
          child: Column(
            children: [
              _DetailRow('Transaction Type', debit ? 'Debit' : 'Credit'),
              if (project != null || transaction.projectId != null)
                _DetailRow('Project', project?.name ?? transaction.title),
              if (transaction.kind == InvestorTransactionKind.topUp) ...[
                if (bankTopUp) ...[
                  _DetailRow(
                    transaction.paymentMethodIsDestination
                        ? 'Destination bank'
                        : 'From',
                    method!.name,
                  ),
                  _DetailRow('Account number', '**** ${method.lastFour}'),
                  if (transaction.description.isNotEmpty)
                    _DetailRow('Remark', transaction.description),
                ] else
                  _DetailRow(
                    'Payment Method',
                    method == null
                        ? 'Linked payment method'
                        : '${method.name} - **** ${method.lastFour}',
                  ),
              ] else
                _DetailRow(withdrawal ? 'Source' : 'From', 'Wallet'),
              if (withdrawal) ...[
                const _DetailRow('Destination', 'Bank'),
                if (method != null) ...[
                  _DetailRow('Bank', method.name),
                  _DetailRow('Account Name', method.holder),
                  _DetailRow('Account Number', '**** ${method.lastFour}'),
                ],
              ],
              if (project != null) ...[
                _DetailRow(
                  project.payoutEveryMonths == 1
                      ? 'Monthly Payout'
                      : 'Quarterly Payout',
                  project.projection?.paymentRangeLabel ??
                      Money.amount(
                        project.distributionPayout,
                        spaceAfterSymbol: true,
                      ),
                ),
                _DetailRow('Term', '${project.durationMonths} Months'),
              ],
              if (transaction.fee.minorUnits > 0)
                _DetailRow('Fee', Money.amount(transaction.fee)),
              if (withdrawal && transaction.fee.minorUnits > 0)
                _DetailRow(
                  'Recipient receives',
                  Money.amount(
                    MonetaryAmount(
                          transaction.amount.minorUnits.abs(),
                          transaction.amount.currency,
                        ) -
                        transaction.fee,
                  ),
                ),
              _DetailRow(
                'Status',
                '',
                trailing: TransactionStatusBadge(transaction.status),
              ),
              _DetailRow('Reference ID', transaction.reference),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value, {this.trailing});
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 6.w),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: AppTextStyles.text(
              14,
              weight: FontWeight.w500,
              color: AppColors.muted,
              height: 26 / 14,
              letterSpacing: -.28,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          flex: 3,
          child: Align(
            alignment: Alignment.centerRight,
            child: trailing == null
                ? Text(
                    value,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.text(
                      16,
                      weight: FontWeight.w600,
                      color: AppColors.gray900,
                      height: 26 / 16,
                      letterSpacing: -.32,
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.symmetric(vertical: 1.w),
                    child: trailing,
                  ),
          ),
        ),
      ],
    ),
  );
}
