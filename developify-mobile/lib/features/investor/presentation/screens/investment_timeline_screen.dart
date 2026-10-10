import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/utils/money.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/stores/project_detail_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investment_timeline.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_project_summary.dart';

class InvestmentTimelineScreen extends StatelessWidget {
  const InvestmentTimelineScreen({
    super.key,
    required this.store,
    required this.id,
  });

  final InvestorProjectDetailStore store;
  final String id;

  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) {
      final holding = store.investment;
      final project = store.project;
      if (holding == null || project == null) {
        return InvestorPage(
          title: 'Investment',
          child: store.status == LoadStatus.error
              ? ErrorView(
                  message: store.error ?? 'This investment could not be found.',
                  onRetry: () => store.loadInvestment(id),
                )
              : const LoadingView(),
        );
      }
      return InvestorPage(
        title: '${holding.projectName} Investment',
        titleOverflow: TextOverflow.ellipsis,
        headerLeadingInset: 20.5,
        footerBottomInset: 12,
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (holding.status != InvestorInvestmentStatus.underfunded) ...[
              AppButton(
                label: 'Invest More',
                onPressed: () => context.pushNamed(
                  InvestorRoutes.invest,
                  pathParameters: {'id': project.id},
                ),
              ),
              SizedBox(height: 12.w),
            ],
            AppButton(
              label: 'View Project',
              style: AppButtonStyle.secondary,
              onPressed: () => context.pushNamed(
                InvestorRoutes.project,
                pathParameters: {'id': project.id},
              ),
            ),
          ],
        ),
        child: ListView(
          key: PageStorageKey('investment-timeline-$id'),
          padding: EdgeInsets.only(
            top:
                (holding.milestoneStage == InvestmentMilestoneStage.planned
                        ? 14
                        : 16)
                    .w,
            bottom: 20.w,
          ),
          children: [
            InvestorProjectSummary(
              name: holding.projectName,
              location: holding.location,
              image: holding.imageAsset,
              statistics: [
                (
                  'Invested',
                  Money.amount(holding.amount, decimals: false),
                  null,
                ),
                (
                  'Earned',
                  '+${Money.amount(holding.earned)}',
                  AppColors.primary,
                ),
                (
                  'Progress',
                  '${(holding.progressBasisPoints / 100).round()}%',
                  null,
                ),
              ],
            ),
            SizedBox(height: 34.w),
            Text(
              'Timeline',
              style: AppTextStyles.text(
                16,
                weight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            SizedBox(height: 18.w),
            InvestmentTimeline(investment: holding),
          ],
        ),
      );
    },
  );
}
