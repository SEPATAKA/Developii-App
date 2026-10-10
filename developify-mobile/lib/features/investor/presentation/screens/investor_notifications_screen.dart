import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/utils/money.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investor_notifications_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_project_summary.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

class InvestorNotificationsScreen extends StatelessWidget {
  const InvestorNotificationsScreen({
    super.key,
    required this.store,
    required this.entity,
    this.id,
  });
  final InvestorNotificationsStore store;
  final EntityType Function() entity;
  final String? id;

  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) {
      final item = id == null
          ? null
          : store.data?.notifications
                .where((item) => item.id == id)
                .firstOrNull;
      return InvestorPage(
        title: id == null ? 'Notifications' : item?.title ?? 'Notification',
        headerLeadingInset: 16,
        headerTopInset: 12,
        titleCenterOffset: id == null && store.notifications.isNotEmpty
            ? 7.5
            : 0,
        bottom: item == null
            ? null
            : AppButton(
                label: switch (item.destination) {
                  InvestorDestination.investment => 'View Investment',
                  InvestorDestination.project => 'View Project',
                  InvestorDestination.wallet => 'View Wallet',
                  InvestorDestination.verification => 'Verify Identity',
                  InvestorDestination.transaction => 'View Transaction',
                },
                onPressed: () => _openTarget(context, item),
              ),
        child: _body(context, item),
      );
    },
  );

  Widget _body(BuildContext context, InvestorNotification? item) {
    if (store.status == LoadStatus.initial ||
        (store.status == LoadStatus.loading && store.data == null)) {
      return const LoadingView();
    }
    if (store.status == LoadStatus.error) {
      return ErrorView(
        message: store.error ?? 'Unable to load notifications.',
        onRetry: store.load,
      );
    }
    if (id != null) {
      if (item == null) {
        return ErrorView(
          message: 'This notification could not be found.',
          onRetry: () => context.goNamed(InvestorRoutes.notifications),
        );
      }
      final milestone = item.fundingMilestone;
      return ListView(
        padding: EdgeInsets.only(top: 14.w, bottom: 24.w),
        children: [
          if (milestone != null) ...[
            InvestorProjectSummary(
              name: milestone.projectName,
              location: milestone.location,
              image: milestone.imageAsset,
              badge: 'Target reached',
              progress: 10000,
              fundingStatistics: true,
              statistics: [
                ('Raised', Money.compact(milestone.raised), null),
                (
                  'Investors',
                  milestone.investors.toString().replaceAllMapped(
                    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                    (match) => '${match[1]},',
                  ),
                  null,
                ),
                ('Closed in', '${milestone.daysToClose} days', null),
              ],
            ),
            SizedBox(height: 28.w),
            Text(
              'What Happens next',
              style: AppTextStyles.text(
                16,
                weight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            SizedBox(height: 13.w),
            for (final step in milestone.nextSteps) ...[
              InvestorSurface(
                radius: 11,
                border: AppColors.border,
                padding: EdgeInsets.symmetric(
                  horizontal: 19.w,
                  vertical: 12.5.w,
                ),
                child: Row(
                  children: [
                    const AppIcon(AppAssets.investorMilestoneCheck, size: 29),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        step,
                        style: AppTextStyles.text(
                          14,
                          height: 26 / 14,
                          letterSpacing: -.28,
                          color: AppColors.gray900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 19.w),
            ],
          ] else ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: AppIcon(AppAssets.investorNotificationBell, size: 40),
            ),
            SizedBox(height: 24.w),
            Text(item.title, style: AppTextStyles.title),
            SizedBox(height: 16.w),
            Text(item.message, style: AppTextStyles.body),
          ],
        ],
      );
    }
    final items = store.notifications;
    final unread = items.where((item) => !item.read).toList();
    final read = items.where((item) => item.read).toList();
    return RefreshIndicator(
      onRefresh: store.load,
      child: ListView(
        key: const PageStorageKey('investor-notifications-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(top: 36.w, bottom: 24.w),
        children: [
          _NotificationFilters(
            selected: store.filter,
            onSelected: store.setFilter,
          ),
          if (items.isEmpty) ...[
            SizedBox(height: 77.w),
            Center(
              child: Container(
                width: 96.w,
                height: 96.w,
                decoration: const BoxDecoration(
                  color: AppColors.mint,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: AppIcon(
                    AppAssets.investorNotificationsEmpty,
                    size: 40,
                  ),
                ),
              ),
            ),
            SizedBox(height: 24.w),
            Text(
              "You're all caught up",
              textAlign: TextAlign.center,
              style: AppTextStyles.text(
                25,
                weight: FontWeight.w700,
                color: AppColors.gray900,
              ),
            ),
            SizedBox(height: 12.w),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 48.w),
              child: Text(
                "No new notifications. We'll let you know when something happens.",
                textAlign: TextAlign.center,
                style: AppTextStyles.text(14, color: AppColors.muted),
              ),
            ),
          ] else ...[
            if (unread.isNotEmpty) ...[
              SizedBox(height: 25.w),
              _heading('NEW', 1.56),
              SizedBox(height: 8.w),
              ..._rows(context, unread, 13),
            ],
            if (read.isNotEmpty) ...[
              SizedBox(height: unread.isEmpty ? 25.w : 10.w),
              _heading('EARLIER', .91),
              SizedBox(height: 15.w),
              ..._rows(context, read, 16),
            ],
          ],
          if (store.error != null) InlineError(store.error),
        ],
      ),
    );
  }

  Widget _heading(String title, double spacing) => Text(
    title,
    style: AppTextStyles.text(
      13,
      weight: FontWeight.w700,
      letterSpacing: spacing,
      color: AppColors.muted,
    ),
  );

  Iterable<Widget> _rows(
    BuildContext context,
    List<InvestorNotification> items,
    double gap,
  ) sync* {
    for (final item in items) {
      yield _NotificationRow(
        item: item,
        onTap: () async {
          if (item.read || await store.markRead(item.id)) {
            if (context.mounted) {
              await context.pushNamed(
                InvestorRoutes.notification,
                pathParameters: {'id': item.id},
              );
            }
          }
        },
      );
      yield SizedBox(height: gap.w);
    }
  }

  void _openTarget(BuildContext context, InvestorNotification notification) {
    final target = notification.targetId;
    switch (notification.destination) {
      case InvestorDestination.wallet:
        context.goNamed(InvestorRoutes.wallet);
      case InvestorDestination.verification:
        context.pushNamed(
          InvestorRoutes.kyc,
          pathParameters: {'entity': entity().name, 'step': 'overview'},
        );
      case InvestorDestination.project:
        if (target != null) {
          context.pushNamed(
            InvestorRoutes.project,
            pathParameters: {'id': target},
          );
        }
      case InvestorDestination.investment:
        if (target != null) {
          context.pushNamed(
            InvestorRoutes.investmentTimeline,
            pathParameters: {'id': target},
          );
        }
      case InvestorDestination.transaction:
        if (target != null) {
          context.pushNamed(
            InvestorRoutes.transaction,
            pathParameters: {'id': target},
          );
        }
    }
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.item, required this.onTap});
  final InvestorNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: item.read ? 'Read notification' : 'Unread notification',
    child: Material(
      color: item.read ? AppColors.investorCard : AppColors.mint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.r),
        side: BorderSide(color: item.read ? AppColors.border : AppColors.mint),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 72.w),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.w),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: const Center(
                    child: AppIcon(AppAssets.investorNotificationBell),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: AppTextStyles.text(
                                14,
                                weight: FontWeight.w700,
                                color: item.read
                                    ? AppColors.gray900
                                    : AppColors.mintText,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            item.timeLabel,
                            style: AppTextStyles.text(
                              12,
                              weight: item.read
                                  ? FontWeight.w500
                                  : FontWeight.w600,
                              color: item.read
                                  ? AppColors.muted
                                  : AppColors.primary,
                            ),
                          ),
                          SizedBox(width: 4.w),
                        ],
                      ),
                      SizedBox(height: 4.w),
                      Text(
                        item.message,
                        style: AppTextStyles.text(
                          12,
                          color: item.read
                              ? AppColors.muted
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _NotificationFilters extends StatelessWidget {
  const _NotificationFilters({
    required this.selected,
    required this.onSelected,
  });
  final InvestorNotificationFilter? selected;
  final ValueChanged<InvestorNotificationFilter?> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final (filter, label, width) in const [
          (null, 'All', 84.0),
          (InvestorNotificationFilter.walletTopUp, 'Wallet Top up', 113.0),
          (InvestorNotificationFilter.investments, 'Investments', 96.0),
          (InvestorNotificationFilter.updates, 'Updates', 106.0),
        ])
          Padding(
            padding: EdgeInsets.only(left: 4.w, right: 8.w),
            child: Semantics(
              selected: selected == filter,
              child: TextButton(
                onPressed: () => onSelected(filter),
                style: TextButton.styleFrom(
                  minimumSize: Size(width.w, 44),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Container(
                  constraints: BoxConstraints(minWidth: width.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 4.w,
                  ),
                  decoration: BoxDecoration(
                    color: selected == filter
                        ? AppColors.primary
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(32.r),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.text(
                      14,
                      height: 26 / 14,
                      color: selected == filter
                          ? AppColors.white
                          : AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
