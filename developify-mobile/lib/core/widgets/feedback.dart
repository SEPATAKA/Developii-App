import 'dart:async';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';

ScaffoldFeatureController<MaterialBanner, MaterialBannerClosedReason>
showSimulationNotice(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  return messenger.showMaterialBanner(
    MaterialBanner(
      content: Text(message, style: AppTextStyles.text(14)),
      backgroundColor: AppColors.mint,
      actions: [
        TextButton(
          onPressed: messenger.hideCurrentMaterialBanner,
          child: const Text('Dismiss'),
        ),
      ],
    ),
  );
}

void showFeedback(BuildContext context, String message, {bool error = false}) {
  if (!context.mounted || message.trim().isEmpty) return;
  unawaited(
    Flushbar<void>(
      messageText: Text(
        message,
        style: AppTextStyles.text(14, color: AppColors.white),
      ),
      backgroundColor: error ? AppColors.error : AppColors.darkTeal,
      borderRadius: BorderRadius.circular(12.r),
      margin: EdgeInsets.all(12.r),
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
    ).show(context),
  );
}
