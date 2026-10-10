import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';

class EmptyPaymentMethods extends StatelessWidget {
  const EmptyPaymentMethods({
    super.key,
    required this.withdrawal,
    required this.onAdd,
  });
  final bool withdrawal;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => ListView(
    children: [
      SizedBox(height: 248.w),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          children: [
            Text(
              withdrawal ? 'No bank accounts added' : 'No Cards Added Yet',
              textAlign: TextAlign.center,
              style: AppTextStyles.text(16, weight: FontWeight.w600),
            ),
            SizedBox(height: 12.w),
            Text(
              withdrawal
                  ? 'Add a bank account for withdrawals.'
                  : "You haven't added any cards yet. Add a card to start making payments and managing your transactions.",
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
          ],
        ),
      ),
      SizedBox(height: 35.w),
      AppButton(
        label: withdrawal ? 'Add Bank Account' : 'Add Card',
        onPressed: onAdd,
      ),
      SizedBox(height: 24.w),
    ],
  );
}
