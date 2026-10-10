import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/stores/wallet_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_transaction_row.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key, required this.store});
  final WalletStore store;
  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) {
      final data = store.data;
      if (data == null) {
        return SafeArea(
          child: store.status == LoadStatus.error
              ? ErrorView(
                  message: store.error ?? 'Unable to load wallet.',
                  onRetry: store.load,
                )
              : const LoadingView(),
        );
      }
      return RefreshIndicator(
        onRefresh: store.load,
        child: ListView(
          key: const PageStorageKey('investor-wallet-scroll'),
          padding: EdgeInsets.zero,
          children: [
            Observer(
              builder: (_) => InvestorBalanceHeader(
                title: 'Available Balance',
                logoRowOffset: 9,
                logoSymbolGap: 10.2109,
                amount: data.balance(Currency.zar),
                visible: store.balanceVisible,
                onToggle: store.toggleBalance,
                height: 396,
                asset: AppAssets.investorWalletMesh,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(28.w, 7.w, 43.w, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _WalletAction(
                          label: 'Add money',
                          asset: AppAssets.investorAdd,
                          onTap: () =>
                              context.pushNamed(InvestorRoutes.addMoney),
                        ),
                      ),
                      SizedBox(width: 22.w),
                      Expanded(
                        child: _WalletAction(
                          label: 'Withdraw',
                          asset: AppAssets.investorWithdraw,
                          up: true,
                          onTap: () =>
                              context.pushNamed(InvestorRoutes.withdraw),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 25.w, 12.w, 15.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Linked Accounts',
                    style: AppTextStyles.text(16, weight: FontWeight.w600),
                  ),
                  SizedBox(height: 14.w),
                  InvestorMenuRow(
                    icon: AppAssets.investorBank,
                    title: 'Accounts',
                    titleSize: 16,
                    subtitleSize: 14,
                    subtitleWeight: FontWeight.w500,
                    subtitleColor: AppColors.iconMuted,
                    trailing: const AppIcon(
                      AppAssets.investorNext,
                      color: AppColors.primary,
                    ),
                    subtitle: data.paymentMethods.isEmpty
                        ? 'No linked accounts'
                        : data.paymentMethods
                              .map(
                                (method) =>
                                    '${method.name} • ${method.lastFour}',
                              )
                              .join(', '),
                    onTap: () =>
                        context.pushNamed(InvestorRoutes.paymentMethods),
                  ),
                  SizedBox(height: 12.w),
                  InvestorSectionHeading(
                    'Recent Activity',
                    action: 'See all',
                    titleWeight: FontWeight.w600,
                    actionSize: 16,
                    actionWeight: FontWeight.w600,
                    actionColor: AppColors.primary,
                    onAction: () =>
                        context.pushNamed(InvestorRoutes.transactions),
                  ),
                  if (data.transactions.isEmpty)
                    const InvestorEmptyState(
                      title: 'No transactions yet',
                      message: 'Your wallet activity will appear here.',
                    )
                  else
                    InvestorSurface(
                      padding: EdgeInsets.zero,
                      border: AppColors.border,
                      child: Column(
                        children: [
                          for (final (index, transaction)
                              in data.transactions.take(4).indexed) ...[
                            if (index > 0)
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12.w),
                                child: const Divider(
                                  height: 1,
                                  color: AppColors.border,
                                ),
                              ),
                            InvestorTransactionRow(
                              transaction: transaction,
                              mintSuccess: true,
                              onTap: () => context.pushNamed(
                                InvestorRoutes.transaction,
                                pathParameters: {'id': transaction.id},
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  if (store.error != null) InlineError(store.error),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _WalletAction extends StatelessWidget {
  const _WalletAction({
    required this.label,
    required this.asset,
    required this.onTap,
    this.up = false,
  });
  final String label;
  final String asset;
  final VoidCallback onTap;
  final bool up;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40.r),
      child: Column(
        children: [
          Container(
            height: 64.r,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.glass,
              borderRadius: BorderRadius.circular(40.r),
            ),
            child: Center(
              child: RotatedBox(
                quarterTurns: up ? 2 : 0,
                child: AppIcon(asset),
              ),
            ),
          ),
          SizedBox(height: 7.w),
          Text(label, style: AppTextStyles.text(13, color: AppColors.white)),
        ],
      ),
    ),
  );
}
