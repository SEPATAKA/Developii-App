import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/dashed_border.dart';

class PayoutProofControl extends StatelessWidget {
  const PayoutProofControl({
    super.key,
    required this.attached,
    required this.onAttach,
    required this.onRemove,
  });
  final bool attached;
  final VoidCallback onAttach;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Proof of Account',
        style: AppTextStyles.text(
          14,
          weight: FontWeight.w500,
          color: AppColors.text,
          height: 22 / 14,
        ),
      ),
      SizedBox(height: 10.w),
      LayoutBuilder(
        builder: (context, constraints) => OverflowBox(
          fit: OverflowBoxFit.deferToChild,
          alignment: Alignment.topLeft,
          minWidth: constraints.maxWidth + 2.w,
          maxWidth: constraints.maxWidth + 2.w,
          child: attached ? _file() : _upload(),
        ),
      ),
    ],
  );

  Widget _file() => Container(
    key: const ValueKey('payout-proof-attached'),
    constraints: BoxConstraints(minHeight: 73.w),
    padding: EdgeInsets.fromLTRB(13.w, 15.w, 15.w, 15.w),
    decoration: BoxDecoration(
      color: AppColors.white,
      border: Border.all(color: AppColors.neutralSeparator),
      borderRadius: BorderRadius.circular(12.w),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppIcon(AppAssets.payoutPdf, size: 40),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bank account letter',
                style: AppTextStyles.text(
                  14,
                  weight: FontWeight.w500,
                  height: 20 / 14,
                ),
              ),
              SizedBox(height: 4.w),
              Row(
                children: [
                  Text(
                    '120 Kb',
                    style: AppTextStyles.text(
                      14,
                      color: AppColors.mutedSlate,
                      height: 17 / 14,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Container(
                    width: 4.w,
                    height: 4.w,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.mutedSlate,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  const AppIcon(AppAssets.payoutFileComplete, size: 16),
                  SizedBox(width: 4.w),
                  Text(
                    'Completed',
                    style: AppTextStyles.text(12, height: 16 / 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        SizedBox(
          width: 24.w,
          height: 24.w,
          child: OverflowBox(
            maxWidth: 44,
            maxHeight: 44,
            child: Semantics(
              label: 'Remove bank account letter',
              button: true,
              child: InkResponse(
                onTap: onRemove,
                child: const SizedBox.square(
                  dimension: 44,
                  child: Center(
                    child: AppIcon(AppAssets.payoutDelete, size: 24),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _upload() => Semantics(
    label: 'Upload bank confirmation letter',
    button: true,
    child: Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12.w),
      child: InkWell(
        key: const ValueKey('payout-proof-upload'),
        borderRadius: BorderRadius.circular(12.w),
        onTap: onAttach,
        child: CustomPaint(
          painter: DashedBorderPainter(
            color: AppColors.borderStrong,
            radius: 12.w,
            strokeWidth: 1,
            dashLength: 4.w,
            gapLength: 4.w,
          ),
          child: Container(
            constraints: BoxConstraints(minHeight: 168.w),
            padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 40.5.w),
            child: Column(
              children: [
                const AppIcon(AppAssets.payoutUpload),
                SizedBox(height: 24.w),
                Text(
                  'Upload bank confirmation letter',
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
                  'Stamped , issued in the last 3 months',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.text(
                    12,
                    color: AppColors.muted,
                    height: 14 / 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
