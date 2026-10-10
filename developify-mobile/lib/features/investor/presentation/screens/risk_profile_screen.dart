import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_plan.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investor_profile_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';

class RiskProfileScreen extends StatelessWidget {
  const RiskProfileScreen({super.key, required this.store});
  final InvestorProfileStore store;
  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) {
      final draft = store.verification;
      return InvestorPage(
        title: 'Risk Profile',
        child: store.status == LoadStatus.error
            ? ErrorView(
                message: store.error ?? 'Unable to load your profile.',
                onRetry: store.load,
              )
            : draft == null
            ? const LoadingView()
            : ListView(
                children: [
                  SizedBox(height: 27.w),
                  Text(
                    KycPlans.entityName(store.entity),
                    style: AppTextStyles.title,
                  ),
                  SizedBox(height: 12.w),
                  Text(
                    'Your source of funds and declarations for this investor profile.',
                    style: AppTextStyles.body,
                  ),
                  SizedBox(height: 24.w),
                  for (final step in KycPlans.steps(store.entity).where(
                    (step) => step.id == 'funds' || step.id == 'tax',
                  )) ...[
                    Text(step.title, style: AppTextStyles.section),
                    SizedBox(height: 14.w),
                    InvestorSurface(
                      child: Column(
                        children: [
                          for (final field in step.fields.where(
                            (field) => field.visible(draft.values),
                          ))
                            InvestorDetailRow(
                              field.label.isEmpty
                                  ? 'Primary source'
                                  : field.label,
                              switch (draft.values[field.key]) {
                                null || '' => 'Not provided',
                                'true' => 'Yes',
                                'false' => 'No',
                                final value => value.replaceAll('|', ', '),
                              },
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.w),
                  ],
                  AppButton(
                    label: 'View verification',
                    onPressed: () => context.pushNamed(
                      InvestorRoutes.kyc,
                      pathParameters: {
                        'entity': store.entity.name,
                        'step': 'overview',
                      },
                    ),
                  ),
                  SizedBox(height: 24.w),
                ],
              ),
      );
    },
  );
}
