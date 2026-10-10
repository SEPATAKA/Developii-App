import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/utils/date_format.dart';
import 'package:developify_mobile/core/utils/money.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';

class InvestmentTimeline extends StatelessWidget {
  const InvestmentTimeline({super.key, required this.investment});
  final InvestorInvestment investment;

  @override
  Widget build(BuildContext context) {
    if (investment.status == InvestorInvestmentStatus.underfunded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Funding target not reached', style: AppTextStyles.title),
          SizedBox(height: 12.w),
          Text(
            'No development or distribution milestones are recorded for this investment. Any refund is simulated.',
            style: AppTextStyles.body,
          ),
          SizedBox(height: 16.w),
          Text(
            'Contribution recorded ${_date(investment.createdAt)}',
            style: AppTextStyles.caption,
          ),
        ],
      );
    }
    final start = investment.createdAt;
    final payout = investment.status == InvestorInvestmentStatus.completed;
    final stage = investment.milestoneStage;
    final distribution = investment.distribution;
    final milestones = [
      ('Investment Confirmed', 'Funds allocated to escrow', start),
      (
        'Foundation Poured',
        stage.index >= InvestmentMilestoneStage.foundation.index
            ? 'Milestone reached'
            : 'Planned milestone',
        start.add(const Duration(days: 30)),
      ),
      (
        investment.payoutEveryMonths == 1
            ? 'Monthly Distribution'
            : 'Quarterly Distribution',
        investment.payoutEveryMonths == 1
            ? '${Money.amount(distribution)} estimate; income begins after project conditions are met'
            : '${Money.amount(distribution)} ${payout ? 'credited' : 'expected'}',
        investment.payoutEveryMonths == 1
            ? null
            : start.add(const Duration(days: 90)),
      ),
      (
        'Maturity Payout',
        payout
            ? 'Funds credited to wallet'
            : '${Money.amount(investment.payoutEveryMonths == 1 ? investment.amount : investment.projectedPayout)} projected payout',
        investment.maturityAt,
      ),
    ];
    return Column(
      children: [
        for (final (index, milestone) in milestones.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 24.w,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 18.w,
                        child: index == 0
                            ? null
                            : Padding(
                                padding: EdgeInsets.only(bottom: 4.w),
                                child: Container(
                                  width: 2.w,
                                  color: AppColors.slate200,
                                ),
                              ),
                      ),
                      Semantics(
                        label:
                            stage == InvestmentMilestoneStage.matured ||
                                index < stage.index
                            ? '${milestone.$1} completed'
                            : '${milestone.$1} pending',
                        child: AppIcon(
                          stage == InvestmentMilestoneStage.matured ||
                                  index < stage.index
                              ? AppAssets.investorTimelineCompleted
                              : AppAssets.investorTimelineCheck,
                          size: 24,
                        ),
                      ),
                      if (index != milestones.length - 1)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 4.w),
                            child: Container(
                              width: 2.w,
                              color: AppColors.slate200,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 27.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            milestone.$3 == null
                                ? 'Commencement to be confirmed'
                                : _date(milestone.$3!),
                            style: AppTextStyles.text(
                              12,
                              color: AppColors.description,
                              height: 4 / 3,
                            ),
                          ),
                        ),
                        SizedBox(height: 2.w),
                        Text(
                          milestone.$1,
                          style: AppTextStyles.text(
                            14,
                            weight: FontWeight.w500,
                            color: AppColors.gray900,
                          ),
                        ),
                        SizedBox(height: 4.w),
                        Text(
                          milestone.$2,
                          style: AppTextStyles.text(
                            14,
                            color: AppColors.muted,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
              ],
            ),
          ),
      ],
    );
  }

  String _date(DateTime date) {
    final local = date.toLocal();
    return '${AppDateFormat.longDate(local)} ${AppDateFormat.time12(local)}';
  }
}
