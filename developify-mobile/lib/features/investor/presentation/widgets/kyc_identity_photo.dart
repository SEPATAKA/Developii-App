import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';

class KycIdentityPhoto extends StatelessWidget {
  const KycIdentityPhoto({
    super.key,
    required this.title,
    required this.back,
    required this.checking,
    required this.onRetake,
  });
  final String title;
  final bool back;
  final bool checking;
  final VoidCallback? onRetake;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        title,
        style: AppTextStyles.text(14, weight: FontWeight.w500, height: 22 / 14),
      ),
      SizedBox(height: 10.w),
      ClipRRect(
        borderRadius: BorderRadius.circular(12.w),
        child: SizedBox(
          height: 168.w,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                AppAssets.investorIdentityFront,
                fit: BoxFit.fill,
                excludeFromSemantics: true,
              ),
              if (back && !checking)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 353.w,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.w),
                    child: Image.asset(
                      AppAssets.investorIdentityBack,
                      fit: BoxFit.fill,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
              if (checking)
                ColoredBox(
                  color: AppColors.identityPhotoScrim,
                  child: const Center(child: _IdentitySpinner()),
                ),
            ],
          ),
        ),
      ),
      SizedBox(height: 6.w),
      Row(
        children: [
          Semantics(
            button: true,
            label: 'Retake $title',
            child: InkWell(
              onTap: onRetake,
              borderRadius: BorderRadius.circular(8.w),
              child: SizedBox(
                width: 80.w,
                height: 44,
                child: Center(
                  child: Container(
                    height: 32.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderStrong),
                      borderRadius: BorderRadius.circular(8.w),
                    ),
                    child: Text('Retake', style: AppTextStyles.text(12)),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: (checking ? 20 : 58).w),
          Expanded(
            child: Row(
              mainAxisAlignment: checking
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                if (!checking) ...[
                  const AppIcon(AppAssets.investorDocumentAccepted, size: 12),
                  SizedBox(width: 6.w),
                ],
                Flexible(
                  child: Text(
                    checking
                        ? 'Make sure the photo is clear and not cropped'
                        : 'The sample photo is ready',
                    textAlign: TextAlign.right,
                    style: AppTextStyles.text(14, color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}

class _IdentitySpinner extends StatefulWidget {
  const _IdentitySpinner();
  @override
  State<_IdentitySpinner> createState() => _IdentitySpinnerState();
}

class _IdentitySpinnerState extends State<_IdentitySpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
    } else if (!TickerMode.valuesOf(context).enabled) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Simulating identity photo check',
    liveRegion: true,
    child: RotationTransition(
      turns: _controller,
      child: const AppIcon(AppAssets.investorIdentitySpinner, size: 40),
    ),
  );
}
