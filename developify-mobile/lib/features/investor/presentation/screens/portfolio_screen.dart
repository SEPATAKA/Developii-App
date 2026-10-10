import 'package:developify_mobile/features/investor/presentation/widgets/investor_property_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/utils/money.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/stores/portfolio_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/portfolio_analytics_view.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({
    super.key,
    required this.store,
    this.analytics = false,
    this.listFilter,
  });
  final PortfolioStore store;
  final bool analytics;
  final InvestorInvestmentStatus? listFilter;
  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) {
      final store = widget.store;
      final data = store.data;
      if (data == null) {
        return SafeArea(
          child: store.status == LoadStatus.error
              ? ErrorView(
                  message: store.error ?? 'Unable to load portfolio.',
                  onRetry: store.load,
                )
              : const LoadingView(),
        );
      }
      if (widget.listFilter != null) {
        final filter = widget.listFilter!;
        final investments = data.investments
            .where((item) => item.status == filter)
            .toList();
        return InvestorPage(
          title: switch (filter) {
            InvestorInvestmentStatus.active => 'Active Investment',
            InvestorInvestmentStatus.completed => 'Completed Projects',
            InvestorInvestmentStatus.underfunded => 'Underfunded',
          },
          child: ListView(
            padding: EdgeInsets.only(top: 17.w, bottom: 24.w),
            children: [
              if (filter == InvestorInvestmentStatus.underfunded) ...[
                InvestorSurface(
                  color: AppColors.warningSurface,
                  border: AppColors.investorVerificationBorder,
                  padding: EdgeInsets.all(14.w),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: 52.w),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppIcon(
                          AppAssets.payoutWarning,
                          size: 19,
                          color: AppColors.investorVerificationText,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Projects that didn’t reach their funding target. Refunds are simulated; no money is moved to your bank or wallet.',
                            style: AppTextStyles.text(
                              14,
                              color: AppColors.investorVerificationText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 18.w),
              ],
              if (investments.isEmpty)
                InvestorEmptyState(
                  title: 'No ${filter.name} investments',
                  message: 'Your investments will appear here.',
                ),
              for (final investment in investments) ...[
                _InvestmentRow(
                  investment: investment,
                  showReturned: true,
                  onTap: () => _openInvestment(investment),
                ),
                SizedBox(height: 14.w),
              ],
            ],
          ),
        );
      }
      final analytics = store.analytics!;
      final total = analytics.capital;
      final earned = analytics.projectedReturns;
      if (widget.analytics) {
        return PortfolioAnalyticsView(
          data: analytics,
          period: store.period,
          onPeriod: store.setPeriod,
        );
      }
      final investments = store.investments;
      return RefreshIndicator(
        onRefresh: store.load,
        child: ListView(
          key: const PageStorageKey('investor-portfolio-scroll'),
          padding: EdgeInsets.zero,
          children: [
            InvestorBalanceHeader(
              title: 'Invested Capital',
              logoTextSize: 21.4667,
              logoSymbolSize: 20,
              logoRowOffset: 11,
              amount: total,
              visible: store.balanceVisible,
              onToggle: store.toggleBalance,
              height: 396,
              asset: AppAssets.investorWalletMesh,
              change:
                  '${Money.amount(earned, showPositiveSign: true)} projected returns',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InvestorIconButton(
                    asset: AppAssets.investorAnalytics,
                    size: 29,
                    label: 'Portfolio analytics',
                    onPressed: () =>
                        context.pushNamed(InvestorRoutes.analytics),
                  ),
                  InvestorIconButton(
                    asset: AppAssets.investorAllocationChart,
                    size: 29,
                    label: 'Project allocation',
                    onPressed: () =>
                        context.pushNamed(InvestorRoutes.analytics),
                  ),
                ],
              ),
              child: Row(
                children: [
                  for (final (index, item) in [
                    (
                      'Active',
                      '${data.investments.where((item) => item.status == InvestorInvestmentStatus.active).length}',
                    ),
                    (
                      'Completed',
                      '${data.investments.where((item) => item.status == InvestorInvestmentStatus.completed).length}',
                    ),
                    (
                      'Avg ROI',
                      total.minorUnits == 0
                          ? '0%'
                          : '${(earned.minorUnits / total.minorUnits * 100).toStringAsFixed(1)}%',
                    ),
                  ].indexed) ...[
                    if (index > 0) SizedBox(width: 12.w),
                    Expanded(
                      child: InkWell(
                        onTap: index == 2
                            ? () => context.pushNamed(InvestorRoutes.analytics)
                            : () => _openList(
                                index == 0
                                    ? InvestorInvestmentStatus.active
                                    : InvestorInvestmentStatus.completed,
                              ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 11.34.w,
                            horizontal: 8.w,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.glass,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Column(
                            children: [
                              Text(
                                item.$1,
                                style: AppTextStyles.text(
                                  14,
                                  height: 27 / 14,
                                  color: AppColors.white,
                                ),
                              ),
                              Text(
                                item.$2,
                                style: AppTextStyles.text(
                                  16,
                                  height: 27 / 16,
                                  weight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 16.w, 10.w, 12.w),
              child: Column(
                children: [
                  if (store.error != null) ...[
                    InlineError(store.error),
                    TextButton(
                      onPressed: store.load,
                      child: const Text('Retry'),
                    ),
                  ],
                  InvestorChoiceChips<InvestorInvestmentStatus>(
                    options: const [
                      (InvestorInvestmentStatus.active, 'Active'),
                      (InvestorInvestmentStatus.completed, 'Completed'),
                      (InvestorInvestmentStatus.underfunded, 'Underfunded'),
                    ],
                    selected: store.filter,
                    onSelected: store.setFilter,
                  ),
                  SizedBox(height: 15.w),
                  InvestorSectionHeading(
                    'Recent Activity',
                    action: 'See all',
                    titleWeight: FontWeight.w600,
                    actionSize: 16,
                    actionWeight: FontWeight.w600,
                    actionColor: AppColors.primary,
                    onAction: () => _openList(store.filter),
                  ),
                  SizedBox(height: 6.w),
                  if (investments.isEmpty)
                    InvestorEmptyState(
                      title: 'No ${store.filter.name} investments',
                      message: 'Your investments will appear here.',
                      action: 'Explore projects',
                      onAction: () => context.goNamed(InvestorRoutes.explore),
                    )
                  else
                    for (final investment in investments) ...[
                      _InvestmentRow(
                        investment: investment,
                        onTap: () => context.pushNamed(
                          InvestorRoutes.investment,
                          pathParameters: {'id': investment.id},
                        ),
                      ),
                      SizedBox(height: 14.w),
                    ],
                ],
              ),
            ),
          ],
        ),
      );
    },
  );

  void _openList(InvestorInvestmentStatus filter) => context.pushNamed(
    InvestorRoutes.portfolioList,
    pathParameters: {'status': filter.name},
  );
  void _openInvestment(InvestorInvestment investment) => context.pushNamed(
    InvestorRoutes.investment,
    pathParameters: {'id': investment.id},
  );
}

class _InvestmentRow extends StatelessWidget {
  const _InvestmentRow({
    required this.investment,
    required this.onTap,
    this.showReturned = false,
  });
  final InvestorInvestment investment;
  final VoidCallback onTap;
  final bool showReturned;

  @override
  Widget build(BuildContext context) {
    final failed = investment.status == InvestorInvestmentStatus.underfunded;
    final completed = investment.status == InvestorInvestmentStatus.completed;
    final value = failed
        ? investment.amount
        : completed && showReturned
        ? investment.projectedPayout
        : investment.earned;
    return Material(
      color: AppColors.investorCard,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: InvestorSurface(
          padding: EdgeInsets.all(7.w),
          border: AppColors.border,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  (investment.thumbnailAsset ==
                              AppAssets.projectSaffronResidenceThumbnail
                          ? 8.3870964
                          : 12)
                      .r,
                ),
                child: InvestorPropertyImage(
                  investment.thumbnailAsset ?? investment.imageAsset,
                  width: 78.w,
                  height: 76.w,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            investment.projectName,
                            style: AppTextStyles.text(
                              13.9832,
                              weight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          failed
                              ? 'To refund'
                              : completed && showReturned
                              ? 'Returned'
                              : 'Earned',
                          style: AppTextStyles.text(14, color: AppColors.muted),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.w),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: failed
                                      ? 'Closed at ${investment.progressBasisPoints ~/ 100}%'
                                      : 'Invested ${Money.amount(investment.amount, decimals: false)}',
                                ),
                                TextSpan(
                                  text: ' • ',
                                  style: AppTextStyles.text(
                                    12.24,
                                    color: AppColors.primary,
                                  ),
                                ),
                                TextSpan(
                                  text: failed
                                      ? 'Refunding pending'
                                      : '${investment.durationMonths} months',
                                ),
                              ],
                            ),
                            style: AppTextStyles.text(
                              12.24,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          Money.amount(
                            value,
                            showPositiveSign:
                                !failed && !(completed && showReturned),
                          ),
                          style: AppTextStyles.text(
                            14.857,
                            weight: FontWeight.w700,
                            color: failed
                                ? AppColors.errorVivid
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: completed || failed ? 7.w : 10.w),
                    if (completed || failed)
                      Container(
                        constraints: BoxConstraints(
                          minWidth: failed ? 80.w : 0,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 9.w,
                          vertical: 4.w,
                        ),
                        decoration: BoxDecoration(
                          color: failed ? AppColors.errorTint : AppColors.mint,
                          border: Border.all(
                            color: failed
                                ? AppColors.errorSurface
                                : AppColors.mintBorder,
                          ),
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                        child: Text(
                          failed ? 'Failed' : 'Completed',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.text(
                            12,
                            weight: FontWeight.w500,
                            color: failed
                                ? AppColors.errorVivid
                                : AppColors.primary,
                          ),
                        ),
                      )
                    else
                      FractionallySizedBox(
                        widthFactor: .733,
                        child: InvestorProgress(investment.progressBasisPoints),
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
}
