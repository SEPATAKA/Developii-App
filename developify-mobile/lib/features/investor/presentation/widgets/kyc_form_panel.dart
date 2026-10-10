import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';

class KycFormPanel extends StatelessWidget {
  const KycFormPanel({
    super.key,
    required this.children,
    this.spacing = 16,
    this.padding,
    this.borderColor = AppColors.borderStrong,
  });
  final List<Widget> children;
  final double spacing;
  final EdgeInsetsGeometry? padding;
  final Color borderColor;

  @override
  Widget build(BuildContext context) => InvestorSurface(
    color: AppColors.investorCard,
    radius: 10,
    border: borderColor,
    padding: padding ?? EdgeInsets.symmetric(horizontal: 18.w, vertical: 20.w),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, child) in children.indexed) ...[
          if (index > 0) SizedBox(height: spacing.w),
          child,
        ],
      ],
    ),
  );
}
