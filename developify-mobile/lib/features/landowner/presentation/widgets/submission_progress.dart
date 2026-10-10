import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';

class SubmissionProgress extends StatelessWidget {
  const SubmissionProgress({super.key, required this.step, this.height = 10});
  final int step;
  final double height;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) {
      final captionWidth = (step == 1 ? 23.0 : 25.0).w;
      final trackWidth = constraints.maxWidth - captionWidth - 8.w;
      final progress = step == 1 ? 35.814571 / 338 : step / 10;
      return Semantics(
        label: 'Submission progress',
        value: '${step * 10}%',
        child: SizedBox(
          key: const ValueKey('submission-progress'),
          height: height.w,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: ((height - 10) / 2).w,
                child: SizedBox(
                  key: const ValueKey('submission-progress-track'),
                  width: trackWidth,
                  height: 10.w,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999.w),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: progress),
                      duration: AppDurations.motion(
                        context,
                        AppDurations.state,
                      ),
                      builder: (_, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 10.w,
                        backgroundColor: AppColors.mint,
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999.w),
                        stopIndicatorRadius: 0,
                        trackGap: 0,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: trackWidth + 8.w,
                top: ((height - 16) / 2).w,
                child: ExcludeSemantics(
                  child: Text(
                    '${step * 10}%',
                    style: AppTextStyles.text(
                      12,
                      weight: FontWeight.w500,
                      color: AppColors.meshTeal,
                      height: 16 / 12,
                    ).copyWith(letterSpacing: -.2.w),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
