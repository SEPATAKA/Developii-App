import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/app/router/route_names.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/utils/money.dart';
import 'package:developify_mobile/core/widgets/app_chrome.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/landowner/domain/property.dart';
import 'package:developify_mobile/features/landowner/presentation/stores/earnings_store.dart';
import 'package:developify_mobile/features/landowner/presentation/widgets/balance_summary.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key, required this.store});
  final EarningsStore store;
  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final _scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    unawaited(widget.store.load());
  }

  @override
  void dispose() {
    _scroll.dispose();
    widget.store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      body: RefreshIndicator(
        onRefresh: widget.store.load,
        child: SingleChildScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MeshBackground(
                asset: AppAssets.earningsMesh,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppPageAppBar(
                      title: 'Earnings',
                      titleCenterOffset: -2,
                      appearance: AppHeaderAppearance.dark,
                      onBack: () => context.goNamed(Routes.home),
                    ),
                    SizedBox(height: 21.w),
                    Padding(
                      padding: EdgeInsets.only(left: 16.w, right: 27.w),
                      child: Observer(
                        builder: (_) => BalanceSummary(
                          label: 'Total Earnings to date',
                          visible: widget.store.balanceVisible,
                          onVisibilityChanged: widget.store.toggleBalance,
                          amount: Money.rand(
                            widget.store.data?.totalCents ?? 0,
                          ),
                          payout: (widget.store.data?.nextPayoutCents ?? 0) <= 0
                              ? null
                              : Money.rand(
                                  widget.store.data!.nextPayoutCents,
                                  decimals: false,
                                ),
                          payoutTiming: 'in 19 days',
                        ),
                      ),
                    ),
                    SizedBox(height: 62.w),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(12.w, 21.w, 12.w, 33.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Linked Accounts',
                      style: AppTextStyles.text(
                        16,
                        weight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    SizedBox(height: 13.w),
                    LinkedPayoutAccount(
                      onTap: () => context.pushNamed(Routes.payout),
                    ),
                    SizedBox(height: 21.w),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Recent Activity',
                            style: AppTextStyles.text(
                              16,
                              weight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            if (_scroll.hasClients) {
                              unawaited(
                                _scroll.animateTo(
                                  _scroll.position.maxScrollExtent,
                                  duration: AppDurations.motion(
                                    context,
                                    AppDurations.page,
                                  ),
                                  curve: Curves.easeOut,
                                ),
                              );
                            }
                          },
                          child: Text(
                            'See all',
                            style: AppTextStyles.text(
                              16,
                              weight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 13.w),
                    Observer(
                      builder: (_) {
                        if (widget.store.status == LoadStatus.loading ||
                            widget.store.status == LoadStatus.initial) {
                          return const LoadingView();
                        }
                        if (widget.store.status == LoadStatus.error) {
                          return ErrorView(
                            message: widget.store.error!,
                            onRetry: widget.store.load,
                          );
                        }
                        final payouts = widget.store.data?.payouts ?? [];
                        if (payouts.isEmpty) {
                          return const EmptyView(
                            title: 'No earnings yet',
                            message:
                                'Your distributions will appear here when your property starts earning.',
                            icon: AppAssets.navEarningsActive,
                          );
                        }
                        return EarningsActivity(payouts: payouts);
                      },
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

class LinkedPayoutAccount extends StatelessWidget {
  const LinkedPayoutAccount({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.w),
      side: const BorderSide(color: AppColors.border),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.w),
      child: Padding(
        padding: EdgeInsets.fromLTRB(15.w, 16.w, 17.w, 16.w),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: const BoxDecoration(
                color: AppColors.mint,
                shape: BoxShape.circle,
              ),
              child: const Center(child: AppIcon(AppAssets.earningsBank)),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accounts',
                    style: AppTextStyles.text(
                      16,
                      weight: FontWeight.w600,
                      color: AppColors.body,
                    ),
                  ),
                  SizedBox(height: 4.w),
                  Wrap(
                    spacing: 6.w,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Payout account',
                        style: AppTextStyles.text(
                          14,
                          weight: FontWeight.w500,
                          color: AppColors.text,
                        ),
                      ),
                      const _AccountSeparator(),
                      Text(
                        'Access Bank',
                        style: AppTextStyles.text(
                          14,
                          weight: FontWeight.w500,
                          color: AppColors.text,
                        ),
                      ),
                      const _AccountSeparator(),
                      Text(
                        '0119',
                        style: AppTextStyles.text(
                          14,
                          weight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 23.w),
            Padding(
              padding: EdgeInsets.only(top: 4.w),
              child: const AppIcon(AppAssets.earningsChevron),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AccountSeparator extends StatelessWidget {
  const _AccountSeparator();
  @override
  Widget build(BuildContext context) => Container(
    width: 4.w,
    height: 4.w,
    decoration: const BoxDecoration(
      color: AppColors.gray300,
      shape: BoxShape.circle,
    ),
  );
}

class EarningsActivity extends StatelessWidget {
  const EarningsActivity({super.key, required this.payouts});
  final List<Payout> payouts;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.w),
      side: const BorderSide(color: AppColors.border),
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 15.w),
      child: Column(
        children: [
          for (final (index, payout) in payouts.indexed) ...[
            if (index > 0) ...[
              SizedBox(height: (index == 1 ? 14 : 17).w),
              const Divider(height: 0, thickness: 1, color: AppColors.border),
              SizedBox(height: 17.w),
            ],
            Row(
              children: [
                const AppIcon(AppAssets.earningsPayoutBadge, size: 44),
                SizedBox(width: 11.w),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              payout.propertyName,
                              style: AppTextStyles.text(
                                14,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            Money.rand(payout.amountCents, decimals: false),
                            style: AppTextStyles.text(
                              16,
                              weight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.w),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              payout.period,
                              style: AppTextStyles.text(
                                14,
                                weight: FontWeight.w500,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(right: 2.w),
                            child: Text(
                              payout.date,
                              style: AppTextStyles.text(
                                14,
                                weight: FontWeight.w500,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}
