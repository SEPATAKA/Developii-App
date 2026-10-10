import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_field.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/selection_sheet.dart';

class PhoneNumberField extends StatelessWidget {
  const PhoneNumberField({
    super.key,
    required this.value,
    required this.countryCode,
    required this.onChanged,
    required this.onCountryChanged,
    this.error,
    this.enabled = true,
    this.label = 'Phone Number',
    this.hint = 'Enter Phone Number',
    this.fillColor = AppColors.surface,
    this.hintColor = AppColors.placeholder,
    this.hintWeight = FontWeight.w500,
    this.countryTrailingGap = 8,
  });
  final String value;
  final String countryCode;
  final ValueChanged<String> onChanged;
  final void Function(String countryCode, String dialCode) onCountryChanged;
  final String? error;
  final bool enabled;
  final String label;
  final String hint;
  final Color fillColor;
  final Color hintColor;
  final FontWeight hintWeight;
  final double countryTrailingGap;

  static const countries = [
    ('US', '+1', 'United States', AppAssets.flagUs),
    ('ZA', '+27', 'South Africa', AppAssets.flagSouthAfrica),
    ('GB', '+44', 'United Kingdom', AppAssets.languageFlagUk),
  ];

  @override
  Widget build(BuildContext context) {
    final country = countries.firstWhere(
      (item) => item.$1 == countryCode,
      orElse: () => countries.first,
    );
    final codeWidth =
        (country.$2.length == 2 ? 16.0 : 25.0) *
        MediaQuery.textScalerOf(context).scale(14) /
        14;
    return AppField(
      label: label,
      hint: hint,
      value: value,
      onChanged: enabled ? onChanged : null,
      readOnly: !enabled,
      fillColor: fillColor,
      hintColor: hintColor,
      hintWeight: hintWeight,
      error: error,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9 ()-]')),
      ],
      autofillHints: const [AutofillHints.telephoneNumberNational],
      prefixWidth: 66 + codeWidth + countryTrailingGap,
      prefix: Semantics(
        container: true,
        button: true,
        enabled: enabled,
        label: 'Phone country, ${country.$3}, ${country.$2}',
        child: InkWell(
          key: const ValueKey('phone-country'),
          onTap: !enabled
              ? null
              : () async {
                  final selected = await showSelectionSheet<String>(
                    context,
                    builder: (context) => SelectionSheetFrame(
                      height: 335,
                      title: 'Country',
                      titleLeft: 155.5,
                      titleWidth: 64,
                      closeLeft: 337.5,
                      children: [
                        for (final item in countries)
                          SelectionSheetRow(
                            label: '${item.$3} (${item.$2})',
                            selected: item.$1 == countryCode,
                            onTap: () => Navigator.pop(context, item.$1),
                            divider: item != countries.last,
                          ),
                      ],
                    ),
                  );
                  if (selected == null || !context.mounted) return;
                  final choice = countries.firstWhere(
                    (item) => item.$1 == selected,
                  );
                  onCountryChanged(choice.$1, choice.$2);
                },
          child: SizedBox(
            height: 44.w,
            child: Row(
              children: [
                SizedBox(width: 12.w),
                AppIcon(country.$4, size: 20),
                SizedBox(width: 8.w),
                SizedBox(
                  width: codeWidth.w,
                  child: Text(
                    country.$2,
                    style: AppTextStyles.text(
                      14,
                      height: 20 / 14,
                    ).copyWith(letterSpacing: -.084.sp),
                  ),
                ),
                SizedBox(width: 2.w),
                const AppSelectTrailingIcon(),
                SizedBox(width: countryTrailingGap.w),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
