import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/presentation/stores/kyc_member_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';

String kycShareLabel(int basisPoints) =>
    '${(basisPoints / 100).toStringAsFixed(basisPoints % 100 == 0
        ? 0
        : basisPoints % 10 == 0
        ? 1
        : 2)}%';

class KycAllocationForm extends StatelessWidget {
  const KycAllocationForm({super.key, required this.store});
  final KycMemberStore store;
  @override
  Widget build(BuildContext context) {
    final shareholder = store.draft!.role == KycMemberRole.shareholder;
    final members = store.application!.members
        .where(
          (member) =>
              member.role == store.draft!.role &&
              (shareholder || member.id == store.draft!.id),
        )
        .toList();
    final issuedCounts = members
        .map((member) => member.details?.issuedShares ?? 0)
        .toSet();
    final shareClasses = members
        .map((member) => member.details?.shareClass.trim() ?? '')
        .toSet();
    final issuedSummary =
        issuedCounts.length == 1 &&
            issuedCounts.single > 0 &&
            shareClasses.length == 1 &&
            shareClasses.single.isNotEmpty
        ? '${issuedCounts.single.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')} ${shareClasses.single.toLowerCase()} shares · '
        : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          shareholder
              ? 'Update Share Register'
              : 'Enter the amount to allocate to this beneficiary.',
          style: AppTextStyles.text(16, color: AppColors.muted),
        ),
        SizedBox(height: (shareholder ? 10 : 16).w),
        InvestorSurface(
          radius: 10,
          border: AppColors.border,
          padding: EdgeInsets.fromLTRB(
            12.w,
            shareholder ? 24.w : 12.w,
            12.w,
            12.w,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, member) in members.indexed) ...[
                if (index > 0) SizedBox(height: (shareholder ? 10 : 12).w),
                Row(
                  crossAxisAlignment: shareholder
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    if (!shareholder) ...[
                      CircleAvatar(
                        radius: 21.w,
                        backgroundColor: AppColors.mint,
                        child: Text(
                          '${member.firstName.characters.firstOrNull ?? ''}${member.lastName.characters.firstOrNull ?? ''}',
                          style: AppTextStyles.text(
                            16,
                            weight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 6.w,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                member.name,
                                style: AppTextStyles.text(
                                  14,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              if (shareholder &&
                                  (store.allocations[member.id] ?? 0) > 500)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 4.w,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.bluePale,
                                    borderRadius: BorderRadius.circular(14.r),
                                  ),
                                  child: Text(
                                    'UBO',
                                    style: AppTextStyles.text(
                                      12,
                                      color: AppColors.blueStrong,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 6.w),
                          Text(
                            shareholder
                                ? '${member.details?.isDirector == true ? 'Director' : 'Minority'} · ${member.details?.shareClass ?? 'Ordinary'}'
                                : member.relationship,
                            style: AppTextStyles.text(
                              14,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      kycShareLabel(store.allocations[member.id] ?? 0),
                      style: AppTextStyles.text(
                        14,
                        weight: FontWeight.w600,
                        color: shareholder
                            ? AppColors.investorLink
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                _AllocationSlider(
                  value: store.allocations[member.id] ?? 0,
                  label: member.name,
                  onChanged: store.editable && !store.busy
                      ? (value) => store.allocate(member.id, value)
                      : null,
                ),
              ],
              SizedBox(height: 8.w),
              const Divider(height: 1, color: AppColors.borderStrong),
              SizedBox(height: 18.w),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total',
                      style: AppTextStyles.text(14, weight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    kycShareLabel(store.totalAllocation),
                    style: AppTextStyles.text(
                      14,
                      weight: FontWeight.w700,
                      color: AppColors.mintText,
                    ),
                  ),
                ],
              ),
              if (shareholder) ...[
                SizedBox(height: 12.w),
                Text(
                  '$issuedSummary${members.length} Holders',
                  style: AppTextStyles.text(14, color: AppColors.muted),
                ),
                SizedBox(height: 12.w),
                Text(
                  '${members.where((member) => (store.allocations[member.id] ?? 0) > 500).length} UBOs > 5%',
                  style: AppTextStyles.text(14, color: AppColors.muted),
                ),
              ],
              SizedBox(height: 16.w),
            ],
          ),
        ),
      ],
    );
  }
}

class _AllocationSlider extends StatelessWidget {
  const _AllocationSlider({
    required this.value,
    required this.label,
    this.onChanged,
  });
  final int value;
  final String label;
  final ValueChanged<double>? onChanged;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48.w.clamp(48, double.infinity),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final valuePosition = value.clamp(0, 10000) / 10000;
        final progress = Directionality.of(context) == TextDirection.rtl
            ? 1 - valuePosition
            : valuePosition;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 8.w,
                trackShape: const _AllocationTrack(),
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.mintBorder,
                thumbColor: AppColors.white,
                thumbShape: RoundSliderThumbShape(
                  enabledThumbRadius: 14.w,
                  elevation: 0,
                  pressedElevation: 0,
                ),
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Semantics(
                label: '$label allocation',
                child: Slider(
                  padding: EdgeInsets.zero,
                  value: value.clamp(0, 10000).toDouble(),
                  max: 10000,
                  onChanged: onChanged,
                  semanticFormatterCallback: (value) =>
                      kycShareLabel(value.round()),
                ),
              ),
            ),
            Positioned(
              left: constraints.maxWidth * progress - 13.5.w,
              child: IgnorePointer(
                child: AppIcon(AppAssets.investorAllocationThumb, size: 27),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _AllocationTrack extends RoundedRectSliderTrackShape {
  const _AllocationTrack();
  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) => super.paint(
    context,
    offset,
    parentBox: parentBox,
    sliderTheme: sliderTheme,
    enableAnimation: enableAnimation,
    textDirection: textDirection,
    thumbCenter: thumbCenter,
    secondaryOffset: secondaryOffset,
    isDiscrete: isDiscrete,
    isEnabled: isEnabled,
    additionalActiveTrackHeight: 0,
  );
}
