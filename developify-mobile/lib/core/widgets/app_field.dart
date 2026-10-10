import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';

class AppField extends StatelessWidget {
  const AppField({
    super.key,
    required this.label,
    this.hint,
    this.value,
    this.controller,
    this.onChanged,
    this.error,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.autofillHints,
    this.inputFormatters,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.fillColor = AppColors.surface,
    this.hintColor = AppColors.placeholder,
    this.prefix,
    this.prefixWidth,
    this.invalid = false,
    this.errorColor = AppColors.error,
    this.focusNode,
    this.textColor = AppColors.body,
    this.contentPadding,
    this.fieldHeight,
    this.hintWeight = FontWeight.w500,
    this.labelSpacing = 4,
    this.borderColor = AppColors.border,
    this.textSize = 14,
    this.textHeight = 1.2,
    this.borderRadius = AppRadii.field,
  });
  final String label;
  final String? hint;
  final String? value;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? error;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Color fillColor;
  final Color hintColor;
  final Widget? prefix;
  final double? prefixWidth;
  final bool invalid;
  final Color errorColor;
  final FocusNode? focusNode;
  final Color textColor;
  final EdgeInsetsGeometry? contentPadding;
  final double? fieldHeight;
  final FontWeight hintWeight;
  final double labelSpacing;
  final Color borderColor;
  final double textSize;
  final double textHeight;
  final double borderRadius;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (label.isNotEmpty) ...[
        Text(label, style: AppTextStyles.label),
        SizedBox(height: labelSpacing.w),
      ],
      SizedBox(
        height: fieldHeight,
        child: TextFormField(
          key: ValueKey('field-$label'),
          controller: controller,
          focusNode: focusNode,
          initialValue: controller == null ? value : null,
          onChanged: onChanged,
          keyboardType: keyboardType,
          obscureText: obscure,
          maxLines: fieldHeight == null ? maxLines : null,
          expands: fieldHeight != null,
          textAlignVertical: fieldHeight == null ? null : TextAlignVertical.top,
          readOnly: readOnly,
          onTap: onTap,
          autofillHints: autofillHints,
          inputFormatters: inputFormatters,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          enableSuggestions: !obscure,
          autocorrect: !obscure,
          style: AppTextStyles.text(
            textSize,
            weight: FontWeight.w500,
            color: textColor,
            height: textHeight,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.text(
              textSize,
              weight: hintWeight,
              color: hintColor,
              height: textHeight,
            ),
            filled: true,
            fillColor: fillColor,
            isDense: true,
            contentPadding:
                contentPadding ??
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.5.w),
            errorText: error,
            errorMaxLines: 2,
            errorStyle: AppTextStyles.text(12, color: AppColors.error),
            suffixIcon: suffix,
            prefixIcon: prefix,
            prefixIconConstraints: prefixWidth == null
                ? null
                : BoxConstraints(
                    minWidth: prefixWidth!.w,
                    maxWidth: prefixWidth!.w,
                  ),
            suffixIconConstraints: BoxConstraints(
              minHeight: 44.r,
              minWidth: 44.r,
              maxHeight: 46.w,
              maxWidth: 44.r,
            ),
            border: OutlineInputBorder(
              gapPadding: 0,
              borderRadius: BorderRadius.circular(borderRadius.r),
              borderSide: BorderSide(color: invalid ? errorColor : borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              gapPadding: 0,
              borderRadius: BorderRadius.circular(borderRadius.r),
              borderSide: BorderSide(color: invalid ? errorColor : borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              gapPadding: 0,
              borderRadius: BorderRadius.circular(borderRadius.r),
              borderSide: BorderSide(
                color: invalid ? errorColor : AppColors.primary,
              ),
            ),
            errorBorder: OutlineInputBorder(
              gapPadding: 0,
              borderRadius: BorderRadius.circular(borderRadius.r),
              borderSide: BorderSide(color: errorColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              gapPadding: 0,
              borderRadius: BorderRadius.circular(borderRadius.r),
              borderSide: BorderSide(color: errorColor),
            ),
          ),
        ),
      ),
    ],
  );
}

class AppSelect extends StatelessWidget {
  const AppSelect({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
    this.error,
    this.leadingIcon,
    this.fillColor = AppColors.surface,
    this.trailing = const AppSelectTrailingIcon(),
    this.hintColor = AppColors.iconMuted,
  });
  final String label;
  final String value;
  final String hint;
  final VoidCallback onTap;
  final String? error;
  final String? leadingIcon;
  final Color fillColor;
  final Widget? trailing;
  final Color hintColor;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.label),
      SizedBox(height: 4.w),
      Semantics(
        button: true,
        label: '$label, ${value.isEmpty ? hint : value}',
        child: Material(
          color: fillColor,
          borderRadius: BorderRadius.circular(10.r),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10.r),
            child: Container(
              constraints: BoxConstraints(minHeight: 46.w),
              padding: EdgeInsets.fromLTRB(11.w, 10.w, 8.w, 10.w),
              decoration: BoxDecoration(
                border: Border.all(
                  color: error == null
                      ? AppColors.borderStrong
                      : AppColors.error,
                ),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                children: [
                  if (leadingIcon != null) ...[
                    AppIcon(leadingIcon!, size: 20),
                    SizedBox(width: 10.w),
                  ],
                  Expanded(
                    child: Text(
                      value.isEmpty ? hint : value,
                      style: AppTextStyles.text(
                        14,
                        weight: FontWeight.w500,
                        color: value.isEmpty ? hintColor : AppColors.body,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
        ),
      ),
      if (error != null)
        Padding(
          padding: EdgeInsets.only(top: 6.h),
          child: Text(
            error!,
            style: AppTextStyles.text(12, color: AppColors.error),
          ),
        ),
    ],
  );
}

class AppSelectTrailingIcon extends StatelessWidget {
  const AppSelectTrailingIcon({super.key});

  @override
  Widget build(BuildContext context) => const AppIcon(AppAssets.chevronDown);
}
