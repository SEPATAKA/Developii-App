import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/app/router/route_names.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_chrome.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/feedback.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/notifications/domain/notification_repository.dart';
import 'package:developify_mobile/features/notifications/presentation/notifications_store.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.store,
    this.notificationId,
  });
  final NotificationsStore store;
  final String? notificationId;
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    await widget.store.load();
    final id = widget.notificationId;
    if (mounted &&
        id != null &&
        widget.store.items.any((item) => item.id == id && item.unread)) {
      await widget.store.markRead(id);
    }
  }

  @override
  void dispose() {
    widget.store.dispose();
    super.dispose();
  }

  Future<void> _open(AppNotification item) async {
    await widget.store.markRead(item.id);
    if (!mounted) return;
    await context.pushNamed(
      Routes.notification,
      pathParameters: {'id': item.id},
    );
    if (mounted) await widget.store.load();
  }

  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) {
      final store = widget.store;
      final empty = store.status == LoadStatus.empty;
      return Scaffold(
        appBar: AppPageAppBar(
          title: 'Notifications',
          leadingInset: empty ? 14 : 16,
          topInset: empty ? 17 : 13,
          titleCenterOffset: empty ? -6.5 : 7.5,
        ),
        body: SafeArea(top: false, child: _content(store)),
      );
    },
  );
  Widget _content(NotificationsStore store) {
    if (store.status == LoadStatus.loading ||
        store.status == LoadStatus.initial) {
      return const LoadingView();
    }
    if (store.status == LoadStatus.error) {
      return ErrorView(message: store.error!, onRetry: _load);
    }
    if (widget.notificationId != null) {
      final matches = store.items.where(
        (item) => item.id == widget.notificationId,
      );
      if (matches.isEmpty) {
        return const Center(
          child: EmptyView(
            title: 'Notification unavailable',
            message: 'This notification could not be found.',
          ),
        );
      }
      return NotificationDetail(item: matches.first);
    }
    if (store.status == LoadStatus.empty) {
      return SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(31.w, 85.w, 49.w, 24.w),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                Container(
                  width: 96.w,
                  height: 96.w,
                  decoration: const BoxDecoration(
                    color: AppColors.mint,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: AppIcon(AppAssets.notificationCaughtUp, size: 40),
                  ),
                ),
                SizedBox(height: 22.w),
                Text(
                  "You're all caught up",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.text(
                    25,
                    weight: FontWeight.w700,
                    color: AppColors.gray900,
                    height: 30 / 25,
                  ),
                ),
                SizedBox(height: 12.w),
                Text(
                  "No new notifications. We'll let you know\nwhen something happens.",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.text(
                    14,
                    weight: FontWeight.w500,
                    color: AppColors.muted,
                    height: 17 / 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final unread = store.items.where((n) => n.unread).toList();
    final earlier = store.items.where((n) => !n.unread).toList();
    return RefreshIndicator(
      onRefresh: store.load,
      child: ListView(
        padding: EdgeInsets.fromLTRB(12.w, 19.w, 12.w, 24.w),
        children: [
          InlineError(store.error),
          for (final (index, section) in [
            ('NEW', unread),
            ('EARLIER', earlier),
          ].indexed)
            if (section.$2.isNotEmpty) ...[
              if (index > 0 && unread.isNotEmpty) SizedBox(height: 24.w),
              Text(
                section.$1,
                style: AppTextStyles.text(
                  12,
                  weight: FontWeight.w600,
                  color: AppColors.muted,
                  height: 16 / 12,
                ).copyWith(letterSpacing: .6.w),
              ),
              SizedBox(height: 8.w),
              for (final (row, item) in section.$2.indexed) ...[
                if (row > 0) SizedBox(height: (index == 0 ? 13 : 16).w),
                NotificationRow(item: item, onTap: () => _open(item)),
              ],
            ],
        ],
      ),
    );
  }
}

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: 40.w,
    height: 40.w,
    decoration: BoxDecoration(
      color: AppColors.mint,
      borderRadius: BorderRadius.circular(12.w),
    ),
    child: const Center(child: AppIcon(AppAssets.notificationBell)),
  );
}

class NotificationRow extends StatelessWidget {
  const NotificationRow({super.key, required this.item, required this.onTap});
  final AppNotification item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: item.unread ? AppColors.mint : AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular((item.unread ? 18 : 20).w),
      side: item.unread
          ? BorderSide.none
          : const BorderSide(color: AppColors.border),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.w),
      child: Stack(
        children: [
          Positioned(left: 12.w, top: 16.w, child: const NotificationBell()),
          Padding(
            padding: EdgeInsets.fromLTRB(
              60.w,
              (item.unread ? 20 : 18.5).w,
              16.w,
              (item.unread ? 17 : 18.5).w,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: AppTextStyles.text(
                          14,
                          weight: FontWeight.w600,
                          color: item.unread
                              ? AppColors.mintText
                              : AppColors.gray900,
                          height: 17 / 14,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      item.time,
                      style: AppTextStyles.text(
                        12,
                        weight: FontWeight.w500,
                        color: item.unread
                            ? AppColors.primary
                            : AppColors.muted,
                        height: 14 / 12,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.w),
                Text(
                  item.body,
                  style: AppTextStyles.text(
                    12,
                    weight: FontWeight.w500,
                    color: item.unread ? AppColors.primary : AppColors.muted,
                    height: 14 / 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class NotificationDetail extends StatelessWidget {
  const NotificationDetail({super.key, required this.item});
  final AppNotification item;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(14.w, 27.w, 10.w, 30.w),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 2.w),
          child: SizedBox(
            width: 310.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const NotificationBell(),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: AppTextStyles.text(
                              16,
                              weight: FontWeight.w600,
                              color: AppColors.gray900,
                              height: 19 / 16,
                            ),
                          ),
                          SizedBox(height: 7.w),
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: 'Today • 09 :41 •  '),
                                TextSpan(
                                  text: 'Property Team',
                                  style: AppTextStyles.text(
                                    14,
                                    weight: FontWeight.w600,
                                    color: AppColors.primary,
                                    height: 17 / 14,
                                  ),
                                ),
                              ],
                            ),
                            style: AppTextStyles.text(
                              14,
                              weight: FontWeight.w500,
                              color: AppColors.iconMuted,
                              height: 17 / 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 17.w),
                Text(
                  item.kind == NotificationKind.approved
                      ? 'Great news, Themba. Sea Point Sunset Rd passed viability review and is now open for investor funding. The listing went live this morning at 09:00.'
                      : item.body,
                  style: AppTextStyles.text(
                    12,
                    weight: FontWeight.w500,
                    color: AppColors.muted,
                    height: 16 / 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (item.kind == NotificationKind.approved) ...[
          SizedBox(height: 21.w),
          const FundingPanel(),
        ],
        SizedBox(height: 27.w),
        Text(
          'Next Step',
          style: AppTextStyles.text(
            16,
            weight: FontWeight.w700,
            color: AppColors.black,
            height: 19 / 16,
          ),
        ),
        SizedBox(height: 13.w),
        if (item.kind == NotificationKind.approved) ...[
          NotificationNextCard(
            title: 'Track funding progress',
            subtitle: 'Live updates as investors join',
            onTap: () => context.pushNamed(
              Routes.property,
              pathParameters: {'id': item.propertyId ?? 'sea-point'},
            ),
          ),
          SizedBox(height: 20.w),
          NotificationNextCard(
            title: 'Read the development agreement',
            subtitle: 'Live updates as investors join',
            tallTitle: true,
            onTap: () => showFeedback(
              context,
              "Your agreement will appear here once it's ready.",
            ),
          ),
          SizedBox(height: 18.w),
        ],
        NotificationNextCard(
          title: 'Message the property team',
          subtitle: 'Avg reply 12min',
          message: true,
          onTap: () => context.pushNamed(Routes.chat),
        ),
      ],
    ),
  );
}

class NotificationNextCard extends StatelessWidget {
  const NotificationNextCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.tallTitle = false,
    this.message = false,
  });
  final String title, subtitle;
  final VoidCallback onTap;
  final bool tallTitle, message;
  @override
  Widget build(BuildContext context) {
    final enlarged = MediaQuery.textScalerOf(context).scale(14) > 14;
    final titleText = Text(
      title,
      style: AppTextStyles.text(
        14,
        weight: FontWeight.w500,
        color: AppColors.gray900,
        height: 17 / 14,
      ).copyWith(letterSpacing: -.28.w),
    );
    final subText = Text(
      subtitle,
      style: AppTextStyles.text(
        14,
        weight: FontWeight.w500,
        color: AppColors.iconMuted,
        height: 17 / 14,
      ).copyWith(letterSpacing: -.28.w),
    );
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11.w),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11.w),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 68.w),
          child: Padding(
            padding: EdgeInsets.fromLTRB(11.w, 13.w, 14.w, 13.w),
            child: Row(
              children: [
                const NotificationBell(),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (enlarged)
                        titleText
                      else
                        SizedBox(
                          height: (tallTitle ? 26 : 17).w,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: titleText,
                          ),
                        ),
                      SizedBox(height: (message ? 6 : 4).w),
                      if (enlarged)
                        subText
                      else
                        SizedBox(
                          height: 12.w,
                          child: OverflowBox(
                            alignment: Alignment.centerLeft,
                            minHeight: 17.w,
                            maxHeight: 17.w,
                            child: subText,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: 10.w),
                const AppIcon(AppAssets.notificationNext),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FundingPanel extends StatelessWidget {
  const FundingPanel({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 11.w),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(16.w),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Funding so far',
          style: AppTextStyles.text(
            14,
            weight: FontWeight.w600,
            color: AppColors.deepInk,
            height: 16 / 14,
          ),
        ),
        SizedBox(height: 12.w),
        LayoutBuilder(
          builder: (_, constraints) => ClipRRect(
            borderRadius: BorderRadius.circular(3.w),
            child: LinearProgressIndicator(
              value: 200.w / constraints.maxWidth,
              minHeight: 6.w,
              color: AppColors.primary,
              backgroundColor: AppColors.coolGraySurfaceStrong,
              stopIndicatorRadius: 0,
              trackGap: 0,
            ),
          ),
        ),
        SizedBox(height: 12.w),
        Row(
          children: [
            Text(
              '65% funded',
              style: AppTextStyles.text(
                12,
                weight: FontWeight.w600,
                color: AppColors.primary,
                height: 14 / 12,
              ),
            ),
            SizedBox(width: 5.w),
            Container(
              width: 3.327.w,
              height: 3.327.w,
              decoration: const BoxDecoration(
                color: AppColors.gray300,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 5.w),
            Expanded(
              child: Text(
                'R1.56M  of R 2.4M',
                style: AppTextStyles.text(
                  12,
                  weight: FontWeight.w600,
                  color: AppColors.primary,
                  height: 14 / 12,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: 16.673.w),
              child: Text(
                'R 60k / quarter',
                style: AppTextStyles.text(
                  12,
                  weight: FontWeight.w700,
                  color: AppColors.primary,
                  height: 14 / 12,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
