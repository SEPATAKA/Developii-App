import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';

class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    this.inactiveColor,
    this.activeColor = AppColors.primary,
  }) : _solid = false,
       showThumbIndicator = true;
  const AppSwitch.solid({
    super.key,
    required this.value,
    this.inactiveColor,
    this.activeColor = AppColors.primary,
    this.showThumbIndicator = false,
  }) : _solid = true;
  final bool value;
  final Color? inactiveColor;
  final Color activeColor;
  final bool showThumbIndicator;
  final bool _solid;

  @override
  Widget build(BuildContext context) {
    final color = value
        ? activeColor
        : inactiveColor ??
              (_solid
                  ? showThumbIndicator
                        ? AppColors.filterSwitchTrack
                        : AppColors.kycSwitchTrack
                  : AppColors.neutral300);
    final solidShadow = showThumbIndicator
        ? AppColors.filterSwitchShadow
        : AppColors.kycSwitchShadow;
    final duration = AppDurations.motion(context, AppDurations.state);
    return SizedBox(
      width: (_solid ? 36 : 32).w,
      height: 20.w,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: _solid ? 0 : 2.w,
            top: _solid ? 0 : 2.w,
            child: AnimatedContainer(
              duration: duration,
              width: (_solid ? 36 : 28).w,
              height: (_solid ? 20 : 16).w,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: duration,
            left: (_solid ? (value ? 18 : 2) : (value ? 16 : 4)).w,
            top: (_solid ? 2 : 4).w,
            child: Container(
              width: (_solid ? 16 : 12).w,
              height: (_solid ? 16 : 12).w,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: _solid
                    ? [
                        BoxShadow(
                          color: solidShadow.withValues(alpha: .06),
                          offset: Offset(0, 1.w),
                          blurRadius: 2.w,
                        ),
                        BoxShadow(
                          color: solidShadow.withValues(
                            alpha: showThumbIndicator ? .12 : .10,
                          ),
                          offset: Offset(0, 1.w),
                          blurRadius: 3.w,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: AppColors.shadowInk.withValues(alpha: .08),
                          offset: Offset(0, 2.w),
                          blurRadius: 4.w,
                        ),
                        BoxShadow(
                          color: AppColors.shadowCharcoal.withValues(
                            alpha: .06,
                          ),
                          offset: Offset(0, 4.w),
                          blurRadius: 8.w,
                        ),
                      ],
              ),
              child: !showThumbIndicator
                  ? null
                  : Center(
                      child: AnimatedContainer(
                        duration: duration,
                        width: (_solid ? 8 : 4).w,
                        height: (_solid ? 8 : 4).w,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
