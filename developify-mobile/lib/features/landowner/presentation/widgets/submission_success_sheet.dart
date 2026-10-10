import 'package:flutter/material.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';

class SubmissionSuccessSheet extends StatelessWidget {
  const SubmissionSuccessSheet({
    super.key,
    required this.propertyName,
    required this.reference,
    required this.onTrack,
    required this.onDashboard,
    required this.onClose,
  });
  final String propertyName;
  final String reference;
  final VoidCallback onTrack;
  final VoidCallback onDashboard;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
    ),
    constraints: BoxConstraints(
      maxHeight:
          MediaQuery.sizeOf(context).height - MediaQuery.paddingOf(context).top,
    ),
    child: SingleChildScrollView(
      child: Stack(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 562),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 78, 24, 0),
                    child: Column(
                      children: [
                        const AppIcon(AppAssets.submissionSuccess, size: 88),
                        const SizedBox(height: 20),
                        Text(
                          'Submitted!',
                          style: AppTextStyles.text(
                            28,
                            weight: FontWeight.w700,
                            height: 34 / 28,
                          ),
                        ),
                        const SizedBox(height: 5.865673),
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: 'Our team will review '),
                              TextSpan(
                                text: propertyName,
                                style: const TextStyle(
                                  color: AppColors.gray900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(text: ' within '),
                              const TextSpan(
                                text: '5 – 10 business days.',
                                style: TextStyle(
                                  color: AppColors.gray900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(
                                text:
                                    " We'll message you here with questions or a decision.",
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.text(
                            16,
                            color: AppColors.muted,
                            height: 19 / 16,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Reference',
                                  style: AppTextStyles.text(
                                    14,
                                    weight: FontWeight.w500,
                                    color: AppColors.muted,
                                    height: 16 / 14,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  reference,
                                  textAlign: TextAlign.right,
                                  style: AppTextStyles.text(
                                    14,
                                    weight: FontWeight.w700,
                                    color: AppColors.gray900,
                                    height: 16 / 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 17, 46),
                    child: Column(
                      children: [
                        AppButton(
                          label: 'Track this  submission',
                          onPressed: onTrack,
                        ),
                        const SizedBox(height: 15),
                        AppButton(
                          label: 'Back to dahsboard',
                          style: AppButtonStyle.secondary,
                          onPressed: onDashboard,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 38.1269 - (44 - 32.261192) / 2,
            right: 22.50745 - (44 - 32.261192) / 2,
            child: Semantics(
              button: true,
              label: 'Close submission confirmation',
              child: InkResponse(
                onTap: onClose,
                child: const SizedBox.square(
                  dimension: 44,
                  child: Center(
                    child: AppIcon(
                      AppAssets.payoutSuccessClose,
                      size: 32.261192,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
