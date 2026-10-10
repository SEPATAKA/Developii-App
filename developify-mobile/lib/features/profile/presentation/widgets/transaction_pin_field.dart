import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';

class TransactionPinField extends StatelessWidget {
  const TransactionPinField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onSubmitted,
    this.completed = false,
  });
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final bool completed;
  @override
  Widget build(BuildContext context) => Semantics(
    label: completed ? 'Transaction PIN updated' : '4-digit transaction PIN',
    child: SizedBox(
      height: 44.w,
      child: Stack(
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 4; i++) ...[
                      if (i > 0) SizedBox(width: 32.w),
                      Container(
                        width: 15.1138.w,
                        height: 15.1138.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: completed || value.length > i
                              ? AppColors.primary
                              : AppColors.borderStrong,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (!completed)
            Positioned.fill(
              child: TextFormField(
                key: const ValueKey('transaction-pin-field'),
                initialValue: value,
                onChanged: onChanged,
                onFieldSubmitted: (_) => onSubmitted(),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                showCursor: false,
                enableInteractiveSelection: false,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                style: AppTextStyles.text(16, color: AppColors.transparent),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: AppColors.transparent,
                  filled: true,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
