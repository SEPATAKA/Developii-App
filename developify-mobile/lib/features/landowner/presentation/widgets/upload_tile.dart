import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/dashed_border.dart';

enum UploadTileLayout { document, optional, identity, trustees }

class UploadTile extends StatelessWidget {
  const UploadTile({
    super.key,
    required this.onTap,
    this.title = 'Tap to upload',
    this.subtitle = '',
    this.fileName,
    this.onRemove,
    this.layout = UploadTileLayout.document,
    this.error,
    this.attachedTitle,
  });
  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final String? fileName;
  final String? attachedTitle;
  final VoidCallback? onRemove;
  final UploadTileLayout layout;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final attached = fileName != null;
    final document = layout == UploadTileLayout.document;
    final trustees = layout == UploadTileLayout.trustees;
    final identity = layout == UploadTileLayout.identity;
    final vertical = document
        ? 16.0
        : trustees
        ? 17.0
        : identity
        ? 16.0
        : attached
        ? 19.0
        : 23.0;
    final left = document && attached
        ? 14.0
        : trustees && attached
        ? 11.0
        : 19.0;
    final minHeight = document
        ? (attached ? 73.0 : 107.0)
        : trustees
        ? (attached ? 90.0 : 100.0)
        : identity
        ? 74.0
        : attached
        ? 79.0
        : 92.0;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.w),
      side: document && attached
          ? BorderSide(color: AppColors.borderStrong, width: 1.w)
          : BorderSide.none,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: document && attached ? AppColors.white : AppColors.surface,
          shape: shape,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12.w),
            child: CustomPaint(
              painter: document && attached
                  ? null
                  : DashedBorderPainter(
                      color: error == null
                          ? AppColors.borderStrong
                          : AppColors.error,
                      radius: 12.w,
                      strokeWidth: 1.w,
                      dashLength: 4.w,
                      gapLength: 4.w,
                    ),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(minHeight: minHeight.w),
                padding: document && !attached
                    ? EdgeInsets.symmetric(horizontal: 32.w, vertical: 11.w)
                    : EdgeInsets.fromLTRB(
                        left.w,
                        vertical.w,
                        19.w,
                        (identity
                                ? 12
                                : trustees
                                ? 14
                                : vertical)
                            .w,
                      ),
                child: document && !attached
                    ? Column(
                        children: [
                          const AppIcon(AppAssets.submissionUpload),
                          SizedBox(height: 8.w),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.text(
                              14,
                              weight: FontWeight.w500,
                              color: AppColors.gray900,
                              height: 17 / 14,
                            ),
                          ),
                          SizedBox(height: 8.w),
                          Text(
                            'Ensure your file is in , PDF, PNG, JPG with a maximum\nfile size of 5MB.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.text(
                              12,
                              color: AppColors.muted,
                              height: 14 / 12,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              top: attached && !document ? 3.w : 0,
                            ),
                            child: attached
                                ? AppIcon(
                                    AppAssets.payoutPdf,
                                    size: document
                                        ? 40
                                        : trustees
                                        ? 31
                                        : 35,
                                  )
                                : Container(
                                    width: 36.w,
                                    height: 36.w,
                                    decoration: BoxDecoration(
                                      color: AppColors.mint,
                                      borderRadius: BorderRadius.circular(12.w),
                                    ),
                                    child: const Center(
                                      child: AppIcon(
                                        AppAssets.submissionDocument,
                                      ),
                                    ),
                                  ),
                          ),
                          SizedBox(
                            width:
                                (document
                                        ? 12
                                        : trustees && attached
                                        ? 9
                                        : attached
                                        ? 17
                                        : identity || trustees
                                        ? 17
                                        : 10)
                                    .w,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  attached
                                      ? (attachedTitle ??
                                            (document ? fileName! : title))
                                      : title,
                                  style: AppTextStyles.text(
                                    14,
                                    weight: document
                                        ? FontWeight.w400
                                        : FontWeight.w500,
                                    color: AppColors.gray900,
                                    height: (document ? 20 : 17) / 14,
                                  ),
                                ),
                                if (subtitle.isNotEmpty) ...[
                                  SizedBox(height: 4.w),
                                  Text(
                                    subtitle,
                                    style: AppTextStyles.text(
                                      14,
                                      color: AppColors.muted,
                                      height: 17 / 14,
                                    ),
                                  ),
                                ],
                                SizedBox(
                                  height: (document || trustees ? 4 : 7).w,
                                ),
                                if (attached)
                                  const AttachmentStatus()
                                else
                                  Container(
                                    width: 62.w,
                                    height: 22.w,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(
                                        999.w,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Upload',
                                      style: AppTextStyles.text(
                                        11,
                                        weight: FontWeight.w600,
                                        color: AppColors.white,
                                        height: 13 / 11,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (attached && onRemove != null) ...[
                            SizedBox(width: 4.w),
                            SizedBox(
                              width: 24.w,
                              height: 24.w,
                              child: OverflowBox(
                                minWidth: 44,
                                maxWidth: 44,
                                minHeight: 44,
                                maxHeight: 44,
                                child: Semantics(
                                  button: true,
                                  label: 'Remove $title',
                                  child: InkResponse(
                                    onTap: onRemove,
                                    radius: 22,
                                    child: SizedBox.square(
                                      dimension: 44,
                                      child: const Center(
                                        child: AppIcon(
                                          AppAssets.submissionDelete,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: EdgeInsets.only(top: 6.w),
            child: Text(
              error!,
              style: AppTextStyles.text(12, color: AppColors.error),
            ),
          ),
      ],
    );
  }
}

class AttachmentStatus extends StatelessWidget {
  const AttachmentStatus({super.key});
  @override
  Widget build(BuildContext context) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 4.w,
    children: [
      Text(
        '0 Kb of 120 Kb',
        style: AppTextStyles.text(
          14,
          color: AppColors.mutedSlate,
          height: 17 / 14,
        ),
      ),
      Container(
        width: 2.w,
        height: 2.w,
        margin: EdgeInsets.symmetric(horizontal: 1.w),
        decoration: const BoxDecoration(
          color: AppColors.mutedSlate,
          shape: BoxShape.circle,
        ),
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIcon(AppAssets.submissionComplete, size: 16),
          SizedBox(width: 4.w),
          Text('Completed', style: AppTextStyles.text(12, height: 16 / 12)),
        ],
      ),
    ],
  );
}

class DashedPhotoTile extends StatelessWidget {
  const DashedPhotoTile({
    super.key,
    required this.onTap,
    this.label,
    this.onRemove,
    this.asset,
  });
  final VoidCallback onTap;
  final String? label;
  final VoidCallback? onRemove;
  final String? asset;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label ?? 'Add site photos',
    onLongPress: onRemove,
    child: InkWell(
      onTap: onTap,
      onLongPress: onRemove,
      borderRadius: BorderRadius.circular(10.4.w),
      child: asset != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10.4.w),
              child: Image.asset(
                asset!,
                fit: BoxFit.cover,
                width: 78.w,
                height: 78.w,
                cacheWidth: 312,
                excludeFromSemantics: true,
              ),
            )
          : CustomPaint(
              foregroundPainter: DashedBorderPainter(
                color: AppColors.primary,
                radius: 10.4.w,
                strokeWidth: 1.95.w,
                dashLength: 8.w,
                gapLength: 6.w,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(10.4.w),
                ),
                child: const Center(
                  child: AppIcon(AppAssets.submissionPhotoAdd, size: 31.2),
                ),
              ),
            ),
    ),
  );
}

class SubmissionTips extends StatelessWidget {
  const SubmissionTips({super.key, required this.title, required this.bullets});
  final String title;
  final List<String> bullets;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.w),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border, width: 1.w),
      borderRadius: BorderRadius.circular(14.w),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.text(
            12,
            weight: FontWeight.w600,
            color: AppColors.gray900,
            height: 17 / 12,
          ),
        ),
        SizedBox(height: 11.w),
        for (var i = 0; i < bullets.length; i++) ...[
          if (i > 0) SizedBox(height: 7.w),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 18.w,
                height: 17.w,
                child: Center(
                  child: Container(
                    width: 2.w,
                    height: 2.w,
                    decoration: const BoxDecoration(
                      color: AppColors.gray900,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  bullets[i],
                  style: AppTextStyles.text(
                    12,
                    weight: FontWeight.w500,
                    color: AppColors.gray900,
                    height: 17 / 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}
