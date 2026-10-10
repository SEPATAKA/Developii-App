import 'package:developify_mobile/core/utils/date_format.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_property_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/utils/money.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/app_chrome.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/project_developer_card.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/project_documents.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/project_section_tabs.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investment_timeline.dart';
import 'package:developify_mobile/features/investor/domain/investor_project.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/stores/project_detail_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';

class InvestorProjectScreen extends StatelessWidget {
  const InvestorProjectScreen({
    super.key,
    required this.store,
    required this.id,
    this.investment = false,
  });
  final InvestorProjectDetailStore store;
  final String id;
  final bool investment;
  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) {
      final project = store.project;
      if (project == null) {
        return InvestorPage(
          title: 'Project',
          child: store.status == LoadStatus.error
              ? ErrorView(
                  message: store.error ?? 'This project could not be found.',
                  onRetry: () =>
                      investment ? store.loadInvestment(id) : store.load(id),
                )
              : const LoadingView(),
        );
      }
      final safeTop = MediaQuery.paddingOf(context).top;
      final holding = store.investment;
      return Scaffold(
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: _actions(context, project),
          ),
        ),
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.light,
              child: SizedBox(
                height: 350.w + safeTop,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    InvestorPropertyImage(
                      project.heroAsset ?? project.imageAsset,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                    ),
                    Positioned(
                      left: 9.5.w,
                      top: safeTop + 12.5.w,
                      child: AppBackButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.goNamed(InvestorRoutes.explore);
                          }
                        },
                      ),
                    ),
                    Positioned(
                      right: 8.5.w,
                      top: safeTop + 12.5.w,
                      child: Observer(
                        builder: (_) => InvestorFavouriteButton(
                          outline: AppAssets.investorProjectHeartLarge,
                          diameter: 33,
                          iconSize: 18.8125,
                          label: store.favourite
                              ? 'Remove favourite'
                              : 'Save project',
                          selected: store.favourite,
                          onPressed: store.toggleFavourite,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 15.w,
                      right: 15.w,
                      bottom: 30.w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 13.w,
                              vertical: 5.w,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.investorResidential,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              project.fullyFunded
                                  ? 'Fully funded'
                                  : '${project.category.name[0].toUpperCase()}${project.category.name.substring(1)}',
                              style: AppTextStyles.text(
                                14,
                                weight: FontWeight.w600,
                                color: AppColors.lime,
                              ),
                            ),
                          ),
                          SizedBox(height: 22.w),
                          Text(
                            project.name,
                            style: AppTextStyles.text(
                              24,
                              weight: FontWeight.w700,
                              color: AppColors.mint,
                            ),
                          ),
                          SizedBox(height: 2.w),
                          Row(
                            children: [
                              const AppIcon(
                                AppAssets.investorProjectLocation,
                                size: 20,
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  '${project.city}, ${project.country}',
                                  style: AppTextStyles.text(
                                    16,
                                    color: AppColors.investorCard,
                                    weight: FontWeight.w500,
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
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(11.w, 13.w, 11.w, 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (holding?.status ==
                      InvestorInvestmentStatus.underfunded) ...[
                    InvestorSurface(
                      color: AppColors.warningSurface,
                      border: AppColors.investorVerificationBorder,
                      child: Text(
                        'This investment is underfunded. No return is projected. Refunds are simulated.',
                        style: AppTextStyles.text(
                          14,
                          color: AppColors.investorVerificationText,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.w),
                  ],
                  InvestorSurface(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 13.w,
                    ),
                    border: AppColors.border,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Funding progress',
                                style: AppTextStyles.text(
                                  14,
                                  weight: FontWeight.w600,
                                  color: AppColors.text,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 53.w,
                              child: Text(
                                '${project.fundedBasisPoints ~/ 100}%',
                                style: AppTextStyles.text(
                                  14.857142,
                                  height: 18 / 14.857142,
                                  weight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.w),
                        InvestorProgress(project.fundedBasisPoints),
                        SizedBox(height: 16.w),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final (index, item) in [
                              ('Target', Money.compact(project.target)),
                              (
                                'Estimated ROI',
                                '${project.annualReturnBasisPoints / 100}%',
                              ),
                              (
                                'Duration',
                                '${holding?.durationMonths ?? project.durationMonths} Mo',
                              ),
                            ].indexed) ...[
                              if (index > 0)
                                Container(
                                  width: 1.w,
                                  height: 42.w,
                                  color: AppColors.borderStrong,
                                ),
                              Expanded(
                                flex: [74, 142, 125][index],
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    top: index == 1 ? 0 : 1.w,
                                    right: index == 2 ? 7.w : 0,
                                  ),
                                  child: Align(
                                    alignment: index == 2
                                        ? Alignment.centerRight
                                        : index == 1
                                        ? Alignment.center
                                        : Alignment.centerLeft,
                                    child: SizedBox(
                                      width: index == 2 ? 90.w : null,
                                      child: Column(
                                        crossAxisAlignment: index == 0
                                            ? CrossAxisAlignment.start
                                            : CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            item.$1,
                                            style: AppTextStyles.text(
                                              14,
                                              color: AppColors.iconMuted,
                                            ),
                                          ),
                                          SizedBox(height: 5.w),
                                          Text(
                                            item.$2,
                                            style: AppTextStyles.text(
                                              16,
                                              weight: FontWeight.w700,
                                              color: AppColors.text,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 21.w),
                  Observer(
                    builder: (_) => ProjectSectionTabs(
                      includeDocuments: true,
                      selected: store.tab,
                      onSelected: (index) {
                        // 0 Overview, 3 Updates (holding timeline), 6 Documents stay in-page.
                        if (index == 0 ||
                            index == 6 ||
                            (holding != null && index == 3)) {
                          store.selectTab(index);
                          return;
                        }
                        context.pushNamed(
                          switch (index) {
                            1 => InvestorRoutes.projectDetails,
                            2 => InvestorRoutes.projectDeveloper,
                            3 => InvestorRoutes.projectUpdates,
                            4 => InvestorRoutes.projectLocation,
                            5 => InvestorRoutes.projectPlans,
                            _ => InvestorRoutes.projectUpdates,
                          },
                          pathParameters: {'id': project.id},
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 21.w),
                  if (store.tab == 6)
                    ProjectDocuments(
                      documents: project.content?.documents ?? const [],
                    )
                  else if (holding != null && store.tab == 3) ...[
                    Text('Development Timeline', style: AppTextStyles.section),
                    SizedBox(height: 20.w),
                    InvestmentTimeline(investment: holding),
                  ] else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About this Project',
                          style: AppTextStyles.section,
                        ),
                        SizedBox(height: 11.w),
                        Text(
                          project.description,
                          style: AppTextStyles.text(
                            14,
                            color: AppColors.muted,
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: 22.w),
                        Row(
                          children: [
                            Expanded(
                              child: _Fact(
                                'Minimum Invest',
                                Money.amount(
                                  project.minimumInvestment,
                                  decimals: false,
                                ),
                              ),
                            ),
                            SizedBox(width: 17.w),
                            Expanded(
                              child: _Fact(
                                'Investor',
                                '${project.investorCount}'.replaceAllMapped(
                                  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                                  (match) => '${match[1]},',
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 7.w),
                        Row(
                          children: [
                            Expanded(
                              child: _Fact(
                                'Raised',
                                project.raised == null
                                    ? 'Unavailable'
                                    : Money.compact(
                                        project.raised!,
                                        fractionDigits: 2,
                                      ),
                              ),
                            ),
                            SizedBox(width: 17.w),
                            Expanded(
                              child: _Fact(
                                'Closing Date',
                                project.closesAt == null
                                    ? 'Not announced'
                                    : AppDateFormat.dayMonth(project.closesAt!),
                              ),
                            ),
                          ],
                        ),
                        if (holding == null) ...[
                          SizedBox(height: 22.w),
                          Text('Highlights', style: AppTextStyles.section),
                          SizedBox(height: 13.w),
                          for (final title in [
                            'Government title verified',
                            'Pre - leased to hospitality operator',
                            'Monthly distributions',
                            'Insured Construction',
                          ])
                            Padding(
                              padding: EdgeInsets.only(bottom: 19.w),
                              child: InvestorSurface(
                                border: AppColors.border,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 21.w,
                                  vertical: 12.5.w,
                                ),
                                child: Row(
                                  children: [
                                    const AppIcon(
                                      AppAssets.investorMilestoneCheck,
                                      size: 29,
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: AppTextStyles.text(
                                          14,
                                          color: AppColors.text,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          SizedBox(height: 7.w),
                        ] else
                          SizedBox(height: 22.w),
                        Text('Developer', style: AppTextStyles.section),
                        SizedBox(height: 13.w),
                        if (project.content != null)
                          ProjectDeveloperCard(
                            profile: project.content!.developer,
                            onTap: () => context.pushNamed(
                              InvestorRoutes.projectDeveloper,
                              pathParameters: {'id': project.id},
                            ),
                          )
                        else
                          Text(project.developer, style: AppTextStyles.body),
                      ],
                    ),

                  if (store.error != null) InlineError(store.error),
                  SizedBox(height: MediaQuery.paddingOf(context).bottom),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _actions(BuildContext context, InvestorProject project) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (!project.canInvest)
        Padding(
          padding: EdgeInsets.only(bottom: 8.w),
          child: Text(
            project.investmentUnavailableReason!,
            style: AppTextStyles.caption,
          ),
        ),
      AppButton(
        label: 'Invest Now',
        onPressed: !project.canInvest
            ? null
            : () => context.pushNamed(
                InvestorRoutes.invest,
                pathParameters: {'id': project.id},
              ),
      ),
      SizedBox(height: 12.w),
      AppButton(
        label: 'Calculate',
        style: AppButtonStyle.secondary,
        onPressed: () => context.pushNamed(
          InvestorRoutes.calculator,
          pathParameters: {'id': project.id},
        ),
      ),
    ],
  );
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => InvestorSurface(
    border: AppColors.border,
    radius: 11,
    padding: EdgeInsets.symmetric(horizontal: 17.w, vertical: 11.w),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.text(
            14,
            weight: FontWeight.w500,
            color: AppColors.muted,
            height: 26 / 14,
            letterSpacing: -.28,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.text(
            16,
            weight: FontWeight.w600,
            height: 26 / 16,
            letterSpacing: -.32,
            color: AppColors.text,
          ),
        ),
      ],
    ),
  );
}
