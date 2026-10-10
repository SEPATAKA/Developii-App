import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';

class KycDocumentUploadTile extends StatelessWidget {
  const KycDocumentUploadTile({
    super.key,
    required this.title,
    required this.attempt,
    this.onRetry,
    this.onCancel,
  });
  final String title;
  final KycUploadAttempt attempt;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final failed = attempt.status == KycUploadStatus.failed;
    final target = title == 'Upload' ? 'document' : title;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      liveRegion: true,
      child: InvestorSurface(
        color: failed ? AppColors.surface : AppColors.white,
        border: failed ? AppColors.error : AppColors.borderStrong,
        radius: 12,
        padding: EdgeInsets.fromLTRB(14.w, 16.w, 6.w, failed ? 0 : 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIcon(
                  attempt.mimeType == 'application/pdf'
                      ? AppAssets.investorDocumentPdf
                      : AppAssets.investorUpload,
                  size: 40,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attempt.name.replaceFirst(
                          RegExp(r'\.(pdf|png|jpe?g)$', caseSensitive: false),
                          '',
                        ),
                        semanticsLabel: attempt.name,
                        style: AppTextStyles.text(14, weight: FontWeight.w500),
                      ),
                      SizedBox(height: 4.w),
                      Wrap(
                        spacing: 4.w,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '0 Kb of ${(attempt.bytes / 1024).ceil()} Kb ·',
                            style: AppTextStyles.text(
                              14,
                              color: AppColors.muted,
                            ),
                          ),
                          AppIcon(
                            failed
                                ? AppAssets.investorUploadFailed
                                : AppAssets.investorUploadSpinner,
                            size: 16,
                          ),
                          Tooltip(
                            message:
                                attempt.error ?? 'Document upload in progress',
                            child: Text(
                              failed ? 'Failed' : 'Uploading...',
                              semanticsLabel: failed
                                  ? 'Failed. ${attempt.error ?? 'Try again.'}'
                                  : 'Uploading',
                              style: AppTextStyles.text(
                                failed ? 14 : 12,
                                weight: failed
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (failed)
                        TextButton(
                          onPressed: onRetry,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.only(top: 8.w, bottom: 16.w),
                            alignment: Alignment.topLeft,
                            minimumSize: const Size(44, 44),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: AppColors.error,
                          ),
                          child: Text(
                            'Try Again',
                            style:
                                AppTextStyles.text(
                                  14,
                                  weight: FontWeight.w500,
                                  color: AppColors.error,
                                  height: 20 / 14,
                                ).copyWith(
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.error,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
                InvestorIconButton(
                  alignment: Alignment.topCenter,
                  asset: failed
                      ? AppAssets.investorUploadDelete
                      : AppAssets.investorUploadCancel,
                  size: 20,
                  label: failed
                      ? 'Remove failed $target upload'
                      : 'Cancel $target upload',
                  onPressed: onCancel,
                ),
              ],
            ),
            if (!failed) ...[
              SizedBox(height: 13.w),
              Padding(
                padding: EdgeInsets.only(right: 6.w),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5.r),
                  child: LinearProgressIndicator(
                    value: reducedMotion ? .1 : null,
                    minHeight: 6.w,
                    color: AppColors.primary,
                    backgroundColor: AppColors.borderStrong,
                    semanticsLabel: '$target upload in progress',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
