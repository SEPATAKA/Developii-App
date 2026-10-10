import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/utils/date_format.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/domain/investor_project_content.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/stores/project_detail_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_property_image.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/project_developer_card.dart';

enum ProjectContentPage { details, developer, updates, update, location, plans }

class ProjectContentScreen extends StatelessWidget {
  const ProjectContentScreen({
    super.key,
    required this.store,
    required this.id,
    required this.page,
    this.updateId,
  });
  final InvestorProjectDetailStore store;
  final String id;
  final ProjectContentPage page;
  final String? updateId;

  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) {
      final content = store.project?.content;
      return InvestorPage(
        titleTopOffset: -3,
        titleCenterOffset: page == ProjectContentPage.update ? -5 : 0,
        title: switch (page) {
          ProjectContentPage.details => 'Project details',
          ProjectContentPage.developer => 'Developer’s Profile',
          ProjectContentPage.updates => 'Project Updates',
          ProjectContentPage.update => 'Update Details',
          ProjectContentPage.location => 'Location',
          ProjectContentPage.plans => 'Plans',
        },
        onBack: () => context.canPop()
            ? context.pop()
            : context.goNamed(
                InvestorRoutes.project,
                pathParameters: {'id': id},
              ),
        child:
            store.status == LoadStatus.loading ||
                store.status == LoadStatus.initial
            ? const LoadingView()
            : store.status == LoadStatus.error
            ? ErrorView(
                message: store.error ?? 'Unable to load project information.',
                onRetry: () => store.load(
                  id,
                  includeRelated: page == ProjectContentPage.developer,
                ),
              )
            : content == null
            ? const InvestorEmptyState(
                title: 'Project information unavailable',
                message:
                    'More information will appear here when it is available.',
              )
            : switch (page) {
                ProjectContentPage.details => _details(content),
                ProjectContentPage.developer => _developer(
                  context,
                  content.developer,
                ),
                ProjectContentPage.updates => _updates(
                  context,
                  content.updates,
                ),
                ProjectContentPage.update => _update(
                  content.updates
                      .where((item) => item.id == updateId)
                      .firstOrNull,
                ),
                ProjectContentPage.location => _location(
                  context,
                  content.location,
                ),
                ProjectContentPage.plans => _plans(content.plans),
              },
      );
    },
  );

  Widget _details(InvestorProjectContent content) => ListView(
    padding: EdgeInsets.only(top: 13.w, bottom: 24.w),
    children: [
      Text('Description', style: AppTextStyles.section),
      SizedBox(height: 11.w),
      Text(
        content.description,
        style: AppTextStyles.text(14, color: AppColors.muted),
      ),
      SizedBox(height: 26.w),
      Text('Key Facts', style: AppTextStyles.section),
      SizedBox(height: 14.w),
      InvestorSurface(
        radius: 8,
        border: AppColors.border,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 18.w),
        child: Column(
          children: [
            for (final entry in content.facts.entries)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 6.w),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: AppTextStyles.text(
                          14,
                          weight: FontWeight.w500,
                          color: AppColors.muted,
                          height: 26 / 14,
                          letterSpacing: -.28,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.value,
                        textAlign: TextAlign.right,
                        style: AppTextStyles.text(
                          16,
                          weight: FontWeight.w600,
                          color: AppColors.text,
                          height: 26 / 16,
                          letterSpacing: -.32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      SizedBox(height: 13.w),
      Text('Risks', style: AppTextStyles.section),
      SizedBox(height: 12.w),
      InvestorSurface(
        color: AppColors.warningSurface,
        border: AppColors.warningPale,
        radius: 14,
        padding: EdgeInsets.fromLTRB(14.w, 17.w, 16.w, 12.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppIcon(AppAssets.investorProjectRisk, size: 18),
            SizedBox(width: 9.w),
            Expanded(
              child: Text(
                'All property investments carry risk including delays, cost overruns, and partial loss of capital. Review the full risk disclosure before investing',
                style: AppTextStyles.text(
                  14,
                  weight: FontWeight.w500,
                  color: AppColors.amber800,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _developer(
    BuildContext context,
    InvestorDeveloperProfile profile,
  ) => ListView(
    padding: EdgeInsets.only(top: 7.w, bottom: 24.w),
    children: [
      ProjectDeveloperCard(profile: profile, verified: true),
      SizedBox(height: 17.w),
      Row(
        children: [
          for (final (index, label, value) in [
            (0, 'Projects', '${profile.completedProjects}'),
            (
              1,
              'Avg ROI',
              '${(profile.returnBasisPoints / 100).toStringAsFixed(1)}%',
            ),
            (2, 'On time', '${profile.onTimePercent}%'),
          ]) ...[
            if (index > 0) SizedBox(width: 18.w),
            Expanded(
              flex: switch (index) {
                0 => 103,
                1 => 120,
                _ => 110,
              },
              child: InvestorSurface(
                radius: 11,
                border: AppColors.border,
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 11.w),
                child: Column(
                  children: [
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.text(
                        14,
                        weight: FontWeight.w500,
                        height: 26 / 14,
                        letterSpacing: -.28,
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      value,
                      style: AppTextStyles.text(
                        16,
                        weight: FontWeight.w600,
                        height: 26 / 16,
                        letterSpacing: -.32,
                        color: index == 1 ? AppColors.primary : AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      SizedBox(height: 17.w),
      Text('About this Project', style: AppTextStyles.section),
      SizedBox(height: 11.w),
      Text(
        profile.description,
        style: AppTextStyles.text(14, color: AppColors.muted),
      ),
      SizedBox(height: 21.w),
      Text('Past Projects', style: AppTextStyles.section),
      SizedBox(height: 12.w),
      for (final projectId in profile.pastProjectIds)
        for (final project in store.relatedProjects.where(
          (item) => item.id == projectId,
        )) ...[
          InvestorProjectRow(
            project: project,
            onTap: () => context.pushNamed(
              InvestorRoutes.project,
              pathParameters: {'id': project.id},
            ),
          ),
          SizedBox(height: 13.w),
        ],
    ],
  );

  Widget _updates(BuildContext context, List<InvestorProjectUpdate> updates) =>
      ListView(
        padding: EdgeInsets.only(top: 24.w, bottom: 32.w),
        children: [
          if (updates.isEmpty)
            const InvestorEmptyState(
              title: 'No project updates yet',
              message: 'Updates will appear as the project progresses.',
            ),
          for (final update in updates) ...[
            Material(
              color: AppColors.investorCard,
              borderRadius: BorderRadius.circular(20.r),
              child: InkWell(
                borderRadius: BorderRadius.circular(20.r),
                onTap: () => context.pushNamed(
                  InvestorRoutes.projectUpdate,
                  pathParameters: {'id': id, 'updateId': update.id},
                ),
                child: InvestorSurface(
                  radius: 20,
                  border: AppColors.border,
                  padding: EdgeInsets.fromLTRB(4.w, 4.w, 5.w, 4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: InvestorPropertyImage(
                          update.imageAsset,
                          height: 149.w,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(9.w, 14.w, 8.w, 14.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppDateFormat.longDate(update.publishedAt),
                              style: AppTextStyles.text(
                                14,
                                weight: FontWeight.w500,
                                color: AppColors.body,
                              ),
                            ),
                            SizedBox(height: 8.w),
                            Text(
                              update.title,
                              style: AppTextStyles.text(
                                16,
                                weight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 10.w),
                            Text(
                              update.message,
                              style: AppTextStyles.text(
                                14,
                                weight: FontWeight.w500,
                                color: AppColors.muted,
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
            SizedBox(height: 24.w),
          ],
        ],
      );

  Widget _location(
    BuildContext context,
    InvestorProjectLocation? location,
  ) {
    if (location == null) {
      return const InvestorEmptyState(
        title: 'Location unavailable',
        message: 'The project location will appear here when it is available.',
      );
    }
    return ListView(
      padding: EdgeInsets.only(top: 13.w, bottom: 24.w),
      children: [
        Text('Map', style: AppTextStyles.section),
        SizedBox(height: 12.w),
        ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: InvestorPropertyImage(
            location.mapAsset,
            height: 180.w,
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(height: 26.w),
        Text('Address', style: AppTextStyles.section),
        SizedBox(height: 14.w),
        InvestorSurface(
          radius: 8,
          border: AppColors.border,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 18.w),
          child: Column(
            children: [
              for (final entry in {
                'Street': location.address,
                'City': location.city,
                'Region': location.region,
                'Country': location.country,
              }.entries)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: AppTextStyles.text(
                            14,
                            weight: FontWeight.w500,
                            color: AppColors.muted,
                            height: 26 / 14,
                            letterSpacing: -.28,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        flex: 2,
                        child: Text(
                          entry.value,
                          textAlign: TextAlign.right,
                          style: AppTextStyles.text(
                            16,
                            weight: FontWeight.w600,
                            color: AppColors.text,
                            height: 26 / 16,
                            letterSpacing: -.32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 26.w),
        Text('Location link', style: AppTextStyles.section),
        SizedBox(height: 12.w),
        Material(
          color: AppColors.investorCard,
          borderRadius: BorderRadius.circular(12.r),
          child: InkWell(
            borderRadius: BorderRadius.circular(12.r),
            onTap: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Location link', style: AppTextStyles.section),
                scrollable: true,
                content: Text(
                  '${location.linkLabel}\n\n${location.linkUrl}\n\nOpen this link in Maps to view the property location.',
                  style: AppTextStyles.body,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            child: InvestorSurface(
              radius: 12,
              border: AppColors.neutralSeparator,
              padding: EdgeInsets.fromLTRB(14.w, 16.w, 16.w, 16.w),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.linkLabel,
                          style: AppTextStyles.text(
                            14,
                            weight: FontWeight.w600,
                            height: 20 / 14,
                            letterSpacing: -.084,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 4.w),
                        Text(
                          location.linkUrl,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.text(
                            12,
                            weight: FontWeight.w500,
                            color: AppColors.muted,
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
      ],
    );
  }

  Widget _plans(List<InvestorProjectPlan> plans) => ListView(
    padding: EdgeInsets.only(top: 24.w, bottom: 32.w),
    children: [
      if (plans.isEmpty)
        const InvestorEmptyState(
          title: 'No plans yet',
          message: 'Room layouts will appear here when they are available.',
        ),
      for (final plan in plans) ...[
        InvestorSurface(
          radius: 20,
          border: AppColors.border,
          padding: EdgeInsets.fromLTRB(4.w, 4.w, 5.w, 4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: InvestorPropertyImage(
                  plan.imageAsset,
                  height: 149.w,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(9.w, 14.w, 8.w, 14.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: AppTextStyles.text(
                        16,
                        weight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 10.w),
                    Text(
                      plan.description,
                      style: AppTextStyles.text(
                        14,
                        weight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.w),
      ],
    ],
  );

  Widget _update(InvestorProjectUpdate? update) {
    if (update == null) {
      return const InvestorEmptyState(
        title: 'This project update could not be found.',
        message: 'Return to the project updates to choose an available update.',
      );
    }
    final days = <DateTime, List<InvestorProjectEvent>>{};
    for (final event in update.events) {
      final date = event.occurredAt;
      days
          .putIfAbsent(DateTime.utc(date.year, date.month, date.day), () => [])
          .add(event);
    }
    return ListView(
      padding: EdgeInsets.only(top: 23.w, bottom: 28.w),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(19.r),
          child: InvestorPropertyImage(
            update.imageAsset,
            height: 171.w,
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(height: 36.w),
        for (final (index, entry) in days.entries.indexed) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: Text(
              AppDateFormat.longDate(entry.key),
              style: AppTextStyles.text(
                16,
                weight: index == 0 ? FontWeight.w500 : FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: 17.w),
          for (final event in entry.value) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.zero,
                    child: Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  SizedBox(width: 9.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                event.title,
                                style: AppTextStyles.text(
                                  16,
                                  weight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              AppDateFormat.time12(
                                event.occurredAt,
                              ).toLowerCase(),
                              style: AppTextStyles.text(
                                14,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.w),
                        Text(
                          event.message,
                          style: AppTextStyles.text(
                            14,
                            weight: FontWeight.w500,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 37.w),
          ],
        ],
      ],
    );
  }
}
