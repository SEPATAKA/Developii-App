import 'package:developify_mobile/features/investor/domain/account_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/app/router/route_names.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/services/session_service.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/utils/money.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investor_home_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_home_promotions.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

class InvestorHomeScreen extends StatelessWidget {
  const InvestorHomeScreen({
    super.key,
    required this.store,
    required this.entity,
    required this.session,
  });
  final InvestorHomeStore store;
  final EntityType Function() entity;
  final SessionService session;
  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) {
      if (store.data == null) {
        return SafeArea(
          child: store.status == LoadStatus.error
              ? ErrorView(
                  message: store.error ?? 'Unable to load your account.',
                  onRetry: store.load,
                )
              : const LoadingView(),
        );
      }
      final data = store.data!;
      final portfolio = store.portfolio!;
      final featured = store.projects
          .where(
            (project) =>
                project.id == 'marula-heights' || project.id == 'azure-bay',
          )
          .toList();
      final recent = [
        if (data.investments.isNotEmpty)
          for (final id in [
            'saffron-towers',
            'lissana-villa',
            'saffron-hospitality',
          ])
            ...store.projects.where((project) => project.id == id),
      ];
      void open(String id) =>
          context.pushNamed(InvestorRoutes.project, pathParameters: {'id': id});
      final header = AnimatedBuilder(
        animation: session,
        builder: (_, _) {
          final userName = session.user?.name.trim() ?? '';
          return Observer(
            builder: (_) => InvestorBalanceHeader(
              title: userName.isEmpty
                  ? 'My Portfolio'
                  : userName,
              logoTextSize: 19.234,
              logoSymbolSize: 20,
              logoSymbolGap: 4,
              backgroundFilm: AppColors.investorHomeFilm,
              fractionColor: AppColors.investorBalanceFraction,
              showTrendIcon: true,
              amount: InvestorAccountSummary.from(data).overallBalance,
              visible: store.balanceVisible,
              onToggle: store.toggleBalance,
              change:
                  '${Money.amount(portfolio.projectedReturns, showPositiveSign: true)} projected returns',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InvestorIconButton(
                    asset: AppAssets.investorExperience,
                    label: 'Switch experience',
                    alignment: const Alignment(.5, .1345),
                    onPressed: () => context.pushNamed(Routes.experience),
                  ),
                  InvestorIconButton(
                    asset: AppAssets.investorBell,
                    label: 'Notifications',
                    alignment: const Alignment(-.3, .1345),
                    onPressed: () =>
                        context.pushNamed(InvestorRoutes.notifications),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) => Wrap(
                  alignment: WrapAlignment.spaceAround,
                  runSpacing: 16.w,
                  children: [
                    for (final item in [
                      (
                        'Add money',
                        AppAssets.investorAdd,
                        InvestorRoutes.addMoney,
                      ),
                      (
                        'Withdraw',
                        AppAssets.investorWithdraw,
                        InvestorRoutes.withdraw,
                      ),
                      (
                        'Invest',
                        AppAssets.investorInvest,
                        InvestorRoutes.explore,
                      ),
                      (
                        'Portfolio',
                        AppAssets.investorAllocation,
                        InvestorRoutes.portfolio,
                      ),
                    ])
                      SizedBox(
                        width:
                            constraints.maxWidth /
                            (MediaQuery.textScalerOf(context).scale(13.sp) >
                                    18.w
                                ? 2
                                : 4),
                        child: _HomeAction(
                          label: item.$1,
                          asset: item.$2,
                          onTap: () =>
                              item.$3 == InvestorRoutes.explore ||
                                  item.$3 == InvestorRoutes.portfolio
                              ? context.goNamed(item.$3)
                              : context.pushNamed(item.$3),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
      final content = <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(12.w, 24.w, 12.w, 0),
          child: Column(
            children: [
              if (store.error != null) ...[
                InlineError(store.error),
                TextButton(
                  onPressed: store.load,
                  child: const Text('Try again'),
                ),
              ],
              if (data.verification != VerificationStatus.verified) ...[
                _VerificationBanner(
                  title: switch (data.verification) {
                    VerificationStatus.pending => 'Verification in review',
                    VerificationStatus.correctionRequired =>
                      'Verification needs attention',
                    _ => 'Complete your verification',
                  },
                  onTap: () => context.pushNamed(
                    data.verification == VerificationStatus.incomplete
                        ? InvestorRoutes.kycIntro
                        : InvestorRoutes.kyc,
                    pathParameters:
                        data.verification == VerificationStatus.incomplete
                        ? const {}
                        : {'entity': entity().name, 'step': 'overview'},
                  ),
                ),
                SizedBox(height: 8.w),
              ],
              InvestorSectionHeading(
                'Featured projects',
                onAction: () => context.goNamed(InvestorRoutes.explore),
              ),
            ],
          ),
        ),
        if (featured.isEmpty)
          InvestorEmptyState(
            title: 'No projects yet',
            message: 'New projects will appear here when they are available.',
            action: 'Try again',
            onAction: store.load,
          )
        else if (MediaQuery.textScalerOf(context).scale(14) > 18)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Column(
              children: [
                for (final project in featured) ...[
                  InvestorProjectCard(
                    project: project,
                    featured: true,
                    onOpen: () => open(project.id),
                    favourite: store.favourites.contains(project.id),
                    onFavourite: () => store.toggleFavourite(project.id),
                  ),
                  SizedBox(height: 16.w),
                ],
              ],
            ),
          )
        else
          SizedBox(
            height:
                300.w +
                (MediaQuery.textScalerOf(context).scale(14) - 14).clamp(0, 50) *
                    4,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              itemCount: featured.length,
              separatorBuilder: (_, _) => SizedBox(width: 24.w),
              itemBuilder: (_, index) => SizedBox(
                width: 344.w,
                child: InvestorProjectCard(
                  project: featured[index],
                  featured: true,
                  onOpen: () => open(featured[index].id),
                  favourite: store.favourites.contains(featured[index].id),
                  onFavourite: () => store.toggleFavourite(featured[index].id),
                ),
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(12.w, 23.w, 12.w, 26.w),
          child: Column(
            children: [
              const InvestorHomePromotions(),
              SizedBox(height: 10.5.w),
              InvestorSectionHeading(
                'Recently active',
                onAction: () => context.goNamed(InvestorRoutes.explore),
              ),
              SizedBox(height: 12.w),
              if (recent.isEmpty) const InvestorRecentActivityEmpty(),
              for (final project in recent) ...[
                InvestorProjectRow(
                  project: project,
                  onTap: () => open(project.id),
                ),
                SizedBox(height: 14.w),
              ],
            ],
          ),
        ),
      ];
      return LayoutBuilder(
        builder: (context, constraints) {
          final textScaler = MediaQuery.textScalerOf(context);
          final enlargedText =
              textScaler.scale(40.sp) -
              40.sp +
              (textScaler.scale(14.sp) - 14.sp) * 5;
          final headerExtent =
              357.w + MediaQuery.paddingOf(context).top + enlargedText;
          final pinHeader =
              textScaler.scale(13.sp) <= 18.w &&
              constraints.maxHeight >= headerExtent + 160.w;
          final scroll = RefreshIndicator(
            onRefresh: store.load,
            child: ListView(
              key: const PageStorageKey('investor-home-scroll'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [if (!pinHeader) header, ...content],
            ),
          );
          return pinHeader
              ? Column(
                  children: [
                    header,
                    Expanded(child: scroll),
                  ],
                )
              : scroll;
        },
      );
    },
  );
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.label,
    required this.asset,
    required this.onTap,
  });
  final String label;
  final String asset;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64.r,
            height: 64.r,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.glass,
            ),
            child: Center(child: AppIcon(asset, size: 24)),
          ),
          SizedBox(height: 4.w),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.text(13, color: AppColors.white),
          ),
        ],
      ),
    ),
  );
}

class _VerificationBanner extends StatelessWidget {
  const _VerificationBanner({required this.title, required this.onTap});
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: SizedBox(
      width: 358.1765.w,
      child: Material(
        color: AppColors.warningSurface,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.r),
          child: InvestorSurface(
            color: AppColors.warningSurface,
            border: AppColors.investorVerificationBorder,
            radius: 14,
            padding: EdgeInsets.symmetric(horizontal: 17.w, vertical: 8.w),
            child: Row(
              children: [
                Container(
                  width: 43.294.w,
                  height: 43.294.w,
                  decoration: const BoxDecoration(
                    color: AppColors.warningPale,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: AppIcon(AppAssets.investorVerification, size: 24),
                  ),
                ),
                SizedBox(width: 17.88.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.text(
                          15.0588,
                          weight: FontWeight.w700,
                          color: AppColors.investorVerificationText,
                        ),
                      ),
                      SizedBox(height: 7.529.w),
                      Text(
                        'Kindly upgrade your account to access more features',
                        style: AppTextStyles.text(
                          13.17647,
                          color: AppColors.investorVerificationText,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 9.w),
                const AppIcon(AppAssets.investorNext, size: 24),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
