import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'package:developify_mobile/features/shared/presentation/experience_store.dart';

class ExperienceScreen extends StatefulWidget {
  const ExperienceScreen({
    super.key,
    required this.store,
    required this.onSwitch,
    this.current = Experience.landowner,
  });
  final ExperienceStore store;
  final ValueChanged<Experience> onSwitch;
  final Experience current;

  @override
  State<ExperienceScreen> createState() => _ExperienceScreenState();
}

class _ExperienceScreenState extends State<ExperienceScreen> {
  bool _showLandownerSplash = false;
  Experience get target => widget.current == Experience.landowner
      ? Experience.investor
      : Experience.landowner;

  void _switch() {
    widget.store.select(target);
    if (!widget.store.confirm()) return;
    if (target == Experience.landowner) {
      setState(() => _showLandownerSplash = true);
    } else {
      widget.onSwitch(target);
    }
  }

  @override
  Widget build(BuildContext context) => _showLandownerSplash
      ? SplashScreen(
          landownerPortal: true,
          onReady: () => widget.onSwitch(Experience.landowner),
        )
      : Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: AppColors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8.w),
              topRight: Radius.circular(5.w),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 36.w, 20.w, 58.739.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            'Switch',
                            style: AppTextStyles.text(
                              25,
                              weight: FontWeight.w700,
                              color: AppColors.black,
                              height: 30 / 25,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 32.261.w,
                          height: 32.261.w,
                          child: OverflowBox(
                            minWidth: 44,
                            maxWidth: 44,
                            minHeight: 44,
                            maxHeight: 44,
                            child: Semantics(
                              button: true,
                              label: 'Close switch',
                              child: InkResponse(
                                onTap: () => context.pop(),
                                child: const SizedBox.square(
                                  dimension: 44,
                                  child: Center(
                                    child: AppIcon(
                                      AppAssets.payoutSuccessClose,
                                      size: 32.261,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 39.w),
                    Material(
                      color: AppColors.mint,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.w),
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12.w),
                        onTap: _switch,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.w,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40.w,
                                height: 40.w,
                                decoration: const BoxDecoration(
                                  color: AppColors.mintBorder,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: AppIcon(
                                    target == Experience.investor
                                        ? AppAssets.experienceInvestor
                                        : AppAssets.experienceLandowner,
                                    size: 20,
                                  ),
                                ),
                              ),
                              SizedBox(width: 14.w),
                              Text(
                                target == Experience.investor
                                    ? 'Investor'
                                    : 'Landowner',
                                style: AppTextStyles.text(
                                  14,
                                  weight: FontWeight.w500,
                                  color: AppColors.text,
                                  height: 17 / 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
}
