import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/utils/date_format.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_transaction_row.dart';

class TransactionList extends StatelessWidget {
  const TransactionList({
    super.key,
    required this.transactions,
    required this.filter,
    required this.onFilter,
    required this.onRefresh,
  });
  final List<InvestorTransaction> transactions;
  final InvestorTransactionKind? filter;
  final ValueChanged<InvestorTransactionKind?> onFilter;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final groups = <DateTime, List<InvestorTransaction>>{};
    for (final transaction in transactions) {
      final local = transaction.createdAt.toLocal();
      final date = DateTime(local.year, local.month, local.day);
      groups.putIfAbsent(date, () => []).add(transaction);
    }
    final dates = groups.keys.toList();
    return Column(
      children: [
        SizedBox(height: 19.w),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (kind, label, width) in const [
                (null, 'All', 84.0),
                (InvestorTransactionKind.topUp, 'Wallet Top up', 113.0),
                (InvestorTransactionKind.investment, 'Investments', 96.0),
                (InvestorTransactionKind.withdrawal, 'Withdrawals', 106.0),
                (InvestorTransactionKind.distribution, 'Distributions', 115.0),
              ])
                Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: Semantics(
                    selected: filter == kind,
                    button: true,
                    child: TextButton(
                      onPressed: () => onFilter(kind),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(44, 44),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: width.w,
                          minHeight: 34.w,
                        ),
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 4.w,
                        ),
                        decoration: BoxDecoration(
                          color: filter == kind
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(32.r),
                        ),
                        child: Text(
                          label,
                          style: AppTextStyles.text(
                            14,
                            weight: FontWeight.w500,
                            height: 26 / 14,
                            letterSpacing: -.28,
                            color: filter == kind
                                ? AppColors.surface
                                : AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 30.w),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: transactions.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      InvestorEmptyState(
                        title: 'No transactions yet',
                        message:
                            'Transactions matching this filter will appear here.',
                      ),
                    ],
                  )
                : ListView.builder(
                    key: PageStorageKey(
                      'investor-transactions-${filter?.name ?? 'all'}',
                    ),
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(bottom: 24.w),
                    itemCount: dates.length,
                    itemBuilder: (context, index) {
                      final day = dates[index];
                      final items = groups[day]!;
                      return Padding(
                        padding: EdgeInsets.only(bottom: 22.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              AppDateFormat.relativeDayDate(
                                day,
                                now: DateTime.now(),
                              ),
                              style: AppTextStyles.text(
                                14,
                                weight: FontWeight.w500,
                                color: AppColors.text,
                              ),
                            ),
                            SizedBox(height: 15.w),
                            InvestorSurface(
                              radius: 12,
                              border: AppColors.border,
                              padding: EdgeInsets.zero,
                              child: Column(
                                children: [
                                  for (final (itemIndex, transaction)
                                      in items.indexed) ...[
                                    if (itemIndex > 0)
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12.w,
                                        ),
                                        child: const Divider(
                                          height: 1,
                                          thickness: 1,
                                          color: AppColors.border,
                                        ),
                                      ),
                                    InvestorTransactionRow(
                                      transaction: transaction,
                                      onTap: () => context.pushNamed(
                                        InvestorRoutes.transaction,
                                        pathParameters: {'id': transaction.id},
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
