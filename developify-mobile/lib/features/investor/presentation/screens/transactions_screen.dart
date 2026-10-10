import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/stores/transactions_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/transaction_details.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/transaction_list.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key, required this.store, this.id});
  final TransactionsStore store;
  final String? id;

  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) {
      final ready =
          store.status == LoadStatus.success ||
          store.status == LoadStatus.empty;
      final transaction = ready && id != null
          ? store.data?.transactions.where((item) => item.id == id).firstOrNull
          : null;
      return InvestorPage(
        title: id == null ? 'Transactions' : 'Transactions Details',
        headerLeadingInset: id == null ? 15 : 16,
        headerTopInset: 13,
        footerBottomInset: 7,
        bodyPadding: id == null
            ? null
            : EdgeInsets.only(left: 14.w, right: 8.w),
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.goNamed(InvestorRoutes.wallet);
          }
        },
        bottom: transaction == null
            ? null
            : Transform.translate(
                offset: Offset(2.w, 0),
                child: AppButton(
                  label: 'Download Receipt',
                  onPressed: () =>
                      TransactionDetails.previewReceipt(context, transaction),
                ),
              ),
        child: switch (store.status) {
          LoadStatus.initial || LoadStatus.loading => const LoadingView(),
          LoadStatus.error => ErrorView(
            message: store.error ?? 'Unable to load transactions.',
            onRetry: store.load,
          ),
          _ when id != null && transaction == null => ErrorView(
            message: 'This transaction could not be found.',
            onRetry: () => context.goNamed(InvestorRoutes.transactions),
          ),
          _ when transaction != null => TransactionDetails(
            transaction: transaction,
          ),
          _ => TransactionList(
            transactions: store.transactions,
            filter: store.filter,
            onFilter: store.setFilter,
            onRefresh: store.load,
          ),
        },
      );
    },
  );
}
