import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/features/landowner/domain/property.dart';

class PropertyCard extends StatelessWidget {
  const PropertyCard({
    super.key,
    required this.property,
    required this.onTap,
    this.dashboard = false,
  });
  final bool dashboard;
  final Property property;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (color, surface) = switch (property.status) {
      PropertyStatus.live =>
        dashboard
            ? (AppColors.blue, AppColors.blueSurface)
            : (AppColors.primary, AppColors.mintBorder),
      PropertyStatus.draft => (AppColors.muted, AppColors.borderStrong),
      PropertyStatus.underReview => (
        AppColors.propertyReview,
        AppColors.propertyWarmShadow,
      ),
      PropertyStatus.offerReady => (AppColors.blue, AppColors.blueSurface),
      PropertyStatus.paused => (AppColors.error, AppColors.errorSurface),
    };
    final funding =
        property.status == PropertyStatus.live ||
        property.status == PropertyStatus.underReview;
    final track = switch (property.status) {
      PropertyStatus.live =>
        dashboard
            ? AppColors.blue.withValues(alpha: .2)
            : AppColors.coolGraySurfaceStrong,
      PropertyStatus.offerReady => AppColors.blue.withValues(alpha: .2),
      PropertyStatus.underReview => color.withValues(alpha: .5),
      _ => surface,
    };
    final detailStyle = AppTextStyles.text(
      12,
      weight: FontWeight.w600,
      color: property.status == PropertyStatus.paused
          ? AppColors.errorVivid
          : color,
      height: 14 / 12,
    );
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(16.w),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.w),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          property.name,
                          style: AppTextStyles.text(
                            14,
                            weight: FontWeight.w600,
                            height: 16 / 14,
                          ),
                        ),
                        SizedBox(height: 5.w),
                        Text(
                          '${property.town}, Capacity · ${property.size}',
                          style: AppTextStyles.text(
                            12,
                            weight: FontWeight.w500,
                            color: AppColors.muted,
                            height: 14 / 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 9.w,
                      vertical: 5.w,
                    ),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(999.w),
                    ),
                    child: Text(
                      property.status.label,
                      style: AppTextStyles.text(
                        10,
                        weight: FontWeight.w600,
                        color: switch (property.status) {
                          PropertyStatus.live when !dashboard =>
                            AppColors.mintText,
                          PropertyStatus.underReview =>
                            AppColors.propertyReviewText,
                          _ => color,
                        },
                        height: 12 / 10,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.w),
              ClipRRect(
                borderRadius: BorderRadius.circular(3.w),
                child: ColoredBox(
                  color: track,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: 200 / 349,
                      child: SizedBox(
                        key: ValueKey('property-progress-${property.id}'),
                        height: 6.w,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3.w),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.w),
              LayoutBuilder(
                builder: (context, constraints) {
                  final scale = constraints.maxWidth / 349;
                  final trailingLeft = switch (property.status) {
                    PropertyStatus.live => 255.327377 * scale,
                    PropertyStatus.underReview => 278.327377 * scale,
                    PropertyStatus.offerReady => 260 * scale,
                    PropertyStatus.draft => 305 * scale,
                    PropertyStatus.paused => 265 * scale,
                  };
                  final detail = funding
                      ? Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 5.w,
                          children: [
                            Text(
                              '${property.fundingPercent}% funded',
                              style: detailStyle,
                            ),
                            Container(
                              width: 3.327381.w,
                              height: 3.327381.w,
                              decoration: const BoxDecoration(
                                color: AppColors.gray300,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text('R1.56M  of R 2.4M', style: detailStyle),
                          ],
                        )
                      : Text(switch (property.status) {
                          PropertyStatus.draft =>
                            'Step ${property.draftStep} of 9 ',
                          PropertyStatus.offerReady =>
                            'Sales, lease or revenue shares',
                          _ => '2 items need updating',
                        }, style: detailStyle);
                  final action = Text(
                    switch (property.status) {
                      PropertyStatus.live => 'R 60k / quarter',
                      PropertyStatus.underReview => 'ETA 5-8 days',
                      PropertyStatus.draft => 'Finish It',
                      PropertyStatus.offerReady => 'Decision needed',
                      PropertyStatus.paused => 'Action required',
                    },
                    style: detailStyle.copyWith(
                      fontWeight: funding ? FontWeight.w700 : FontWeight.w600,
                    ),
                  );
                  if (MediaQuery.textScalerOf(context).scale(12) > 12) {
                    return Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 8.w,
                      runSpacing: 8.w,
                      children: [detail, action],
                    );
                  }
                  return SizedBox(
                    width: constraints.maxWidth,
                    child: Stack(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            right: constraints.maxWidth - trailingLeft + 5.w,
                          ),
                          child: detail,
                        ),
                        Positioned(left: trailingLeft, top: 0, child: action),
                      ],
                    ),
                  );
                },
              ),
              if (!funding) ...[
                SizedBox(height: 12.w),
                Text(
                  switch (property.status) {
                    PropertyStatus.draft => 'Auto - saved 2 hours ago',
                    PropertyStatus.offerReady => 'Offer expires in 18days',
                    _ => 'Paused 6 days ago',
                  },
                  style: AppTextStyles.text(
                    12,
                    weight: property.status == PropertyStatus.offerReady
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: property.status == PropertyStatus.offerReady
                        ? color
                        : AppColors.muted,
                    height: 14 / 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title, style: AppTextStyles.section)),
      if (action != null)
        InkWell(
          onTap: onAction,
          child: Padding(
            padding: EdgeInsets.only(right: 1.w),
            child: Text(
              action!,
              style: AppTextStyles.text(
                14,
                weight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
    ],
  );
}
