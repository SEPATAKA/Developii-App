import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/phone_number_field.dart';
import 'package:developify_mobile/core/widgets/selection_sheet.dart';

class ProfileCountryField extends StatelessWidget {
  const ProfileCountryField({
    super.key,
    required this.countryCode,
    required this.onChanged,
  });
  final String countryCode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final country = PhoneNumberField.countries.firstWhere(
      (c) => c.$1 == countryCode,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Country', style: AppTextStyles.label),
        SizedBox(height: 4.w),
        Semantics(
          button: true,
          label: 'Country, ${country.$3}',
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10.w),
            child: InkWell(
              key: const ValueKey('field-Country'),
              borderRadius: BorderRadius.circular(10.w),
              onTap: () async {
                FocusManager.instance.primaryFocus?.unfocus();
                final choice = await showSelectionSheet<String>(
                  context,
                  builder: (context) => SelectionSheetFrame(
                    height: 335,
                    title: 'Country',
                    titleLeft: 155.5,
                    titleWidth: 64,
                    closeLeft: 337.5,
                    children: [
                      for (final item in PhoneNumberField.countries)
                        SelectionSheetRow(
                          label: item.$3,
                          selected: item.$1 == countryCode,
                          onTap: () => Navigator.pop(context, item.$1),
                          divider: item != PhoneNumberField.countries.last,
                        ),
                    ],
                  ),
                );
                if (choice != null) onChanged(choice);
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border, width: 1.w),
                  borderRadius: BorderRadius.circular(10.w),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 11.w,
                  ),
                  child: Row(
                    children: [
                      AppIcon(country.$4, size: 20),
                      SizedBox(width: 8.w),
                      const AppIcon(AppAssets.chevronDown, size: 24),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(country.$3, style: AppTextStyles.label),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
