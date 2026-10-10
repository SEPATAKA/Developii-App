import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/stores/explore_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';

class CalculatorProjectScreen extends StatelessWidget {
  const CalculatorProjectScreen({super.key, required this.store});
  final ExploreStore store;

  @override
  Widget build(BuildContext context) => InvestorPage(
    title: 'Select a project',
    child: Observer(
      builder: (_) {
        if (store.status == LoadStatus.initial ||
            store.status == LoadStatus.loading) {
          return const LoadingView();
        }
        if (store.status == LoadStatus.error) {
          return ErrorView(
            message: store.error ?? 'Unable to load projects.',
            onRetry: store.load,
          );
        }
        if (store.projects.isEmpty) {
          return const InvestorEmptyState(
            title: 'No projects available',
            message: 'Please check again later.',
          );
        }
        return ListView(
          padding: EdgeInsets.symmetric(vertical: 16.w),
          children: [
            Text(
              'Choose a project to calculate your estimated return.',
              style: AppTextStyles.body,
            ),
            SizedBox(height: 16.w),
            for (final project in store.projects) ...[
              InvestorProjectCard(
                key: ValueKey('calculator-project-${project.id}'),
                project: project,
                onOpen: () {
                  if (project.canInvest) {
                    context.pushNamed(
                      InvestorRoutes.calculator,
                      pathParameters: {'id': project.id},
                    );
                  }
                },
              ),
              if (!project.canInvest)
                Text(
                  project.investmentUnavailableReason!,
                  style: AppTextStyles.caption,
                ),
              SizedBox(height: 16.w),
            ],
          ],
        );
      },
    ),
  );
}
