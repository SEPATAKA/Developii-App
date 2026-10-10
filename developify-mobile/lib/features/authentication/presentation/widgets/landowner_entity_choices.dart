import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

class LandownerEntityChoices extends StatelessWidget {
  const LandownerEntityChoices({
    super.key,
    this.selected,
    required this.onChanged,
  });
  final EntityType? selected;
  final ValueChanged<EntityType> onChanged;

  static const _choices = [
    (
      EntityType.individual,
      'Natural Person',
      'Most common',
      'You hold the title in your personal name',
      'Extra : ID copy only',
      96.0,
      AppColors.primary,
      AppColors.mintHighlight,
    ),
    (
      EntityType.trust,
      'Trust',
      'Custom',
      'Trust holds the title',
      'Extra: Trustees + Trustee resolution',
      69.0,
      AppColors.violetBright,
      AppColors.violetBrightAlpha13,
    ),
    (
      EntityType.company,
      'Company / SPV',
      'Corporate',
      'Company or SPV owns the property',
      'Extra :  Directors + company resolution',
      76.0,
      AppColors.blueStrong,
      AppColors.bluePale,
    ),
    (
      EntityType.stokvel,
      'Stokvel / Group',
      'Pooled',
      'Group jointly holds the property',
      'Extra : Committe + resolution + minutes',
      61.0,
      AppColors.navy,
      AppColors.navyAlpha18,
    ),
  ];

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final (index, choice) in _choices.indexed) ...[
        if (index > 0) SizedBox(height: 15.w),
        Semantics(
          inMutuallyExclusiveGroup: true,
          checked: selected == choice.$1,
          label: choice.$2,
          child: Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.w),
              side: const BorderSide(color: AppColors.border),
            ),
            child: InkWell(
              key: ValueKey('owner-entity-${choice.$1.name}'),
              onTap: () => onChanged(choice.$1),
              borderRadius: BorderRadius.circular(10.w),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  (index.isOdd ? 16 : 13).w,
                  (index < 2 ? 14 : 10).w,
                  13.w,
                  (index < 2 ? 13 : 11).w,
                ),
                child: Row(
                  children: [
                    AppIcon(
                      selected == choice.$1
                          ? AppAssets.radioSelected
                          : AppAssets.radioUnselected,
                      size: 32,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: (index < 2 ? 72 : 77).w,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 13.w,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  choice.$2,
                                  style: AppTextStyles.text(
                                    14,
                                    weight: FontWeight.w600,
                                    color: AppColors.text,
                                    height: 17 / 14,
                                  ),
                                ),
                                Container(
                                  width: choice.$6.w,
                                  constraints: BoxConstraints(minHeight: 24.w),
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                  ),
                                  decoration: BoxDecoration(
                                    color: choice.$8,
                                    borderRadius: BorderRadius.circular(500.w),
                                  ),
                                  child: Text(
                                    choice.$3,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.text(
                                      12,
                                      weight: FontWeight.w700,
                                      color: choice.$7,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 7.w),
                            Text(
                              choice.$4,
                              style: AppTextStyles.text(
                                14,
                                color: AppColors.muted,
                                height: 17 / 14,
                              ),
                            ),
                            SizedBox(height: 7.w),
                            Text(
                              choice.$5,
                              style: AppTextStyles.text(
                                14,
                                weight: FontWeight.w500,
                                color: AppColors.greenStrong,
                                height: 17 / 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ],
  );
}
