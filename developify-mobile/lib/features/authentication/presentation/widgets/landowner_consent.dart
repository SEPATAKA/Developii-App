import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';

class LandownerConsent extends StatefulWidget {
  const LandownerConsent({
    super.key,
    required this.accepted,
    required this.onChanged,
    required this.onTerms,
  });
  final bool accepted;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTerms;

  @override
  State<LandownerConsent> createState() => _LandownerConsentState();
}

class _LandownerConsentState extends State<LandownerConsent> {
  late final TapGestureRecognizer _terms = TapGestureRecognizer()
    ..onTap = () => widget.onTerms();
  @override
  void dispose() {
    _terms.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    checked: widget.accepted,
    label: 'Agree to the Landowner Terms and FICA verification',
    child: InkWell(
      onTap: () => widget.onChanged(!widget.accepted),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox.square(
              dimension: 22.w,
              child: widget.accepted
                  ? const AppIcon(AppAssets.consentChecked, size: 22)
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.mintBorder,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6.w),
                      ),
                    ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Landowner Terms',
                      style: const TextStyle(color: AppColors.primary),
                      recognizer: _terms,
                    ),
                    const TextSpan(
                      text:
                          ' and consent to FICA verification for property transactions.',
                    ),
                  ],
                ),
                style: AppTextStyles.text(
                  14,
                  weight: FontWeight.w500,
                  color: AppColors.muted,
                  height: 17 / 14,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
