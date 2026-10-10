import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';

class AppIcon extends StatelessWidget {
  const AppIcon(
    this.asset, {
    super.key,
    this.size = 24,
    this.color,
    this.semanticLabel,
  });
  final String asset;
  final double size;
  final Color? color;
  final String? semanticLabel;
  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size.r,
      child: Center(
        child: SvgPicture.asset(
          asset,
          width: size.r,
          height: size.r,
          fit: BoxFit.contain,
          semanticsLabel: semanticLabel,
          colorFilter: color == null
              ? null
              : ColorFilter.mode(color!, BlendMode.srcIn),
        ),
      ),
    );
  }
}

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.asset,
    required this.label,
    required this.onPressed,
    this.color = AppColors.primary,
  });
  final String asset;
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label,
    onPressed: onPressed,
    constraints: BoxConstraints(minWidth: 44.r, minHeight: 44.r),
    padding: EdgeInsets.all(10.r),
    icon: AppIcon(asset, color: color),
  );
}
