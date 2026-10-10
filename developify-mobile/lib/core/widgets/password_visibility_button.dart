import 'package:flutter/material.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';

class PasswordVisibilityButton extends StatelessWidget {
  const PasswordVisibilityButton({
    super.key,
    required this.visible,
    required this.onPressed,
    this.color,
    this.solid = false,
  });

  final bool visible;
  final VoidCallback onPressed;
  final Color? color;
  final bool solid;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: visible ? 'Hide password' : 'Show password',
    onPressed: onPressed,
    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    padding: const EdgeInsets.all(10),
    icon: AppIcon(
      visible
          ? solid
                ? AppAssets.passwordRevealed
                : AppAssets.passwordRevealedOutline
          : AppAssets.passwordConcealed,
      color: color,
    ),
  );
}
