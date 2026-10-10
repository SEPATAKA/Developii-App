import 'package:flutter/material.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/selection_sheet.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';

abstract final class KycChoiceSheet {
  static bool hasAuthoredSheet(KycFieldDefinition field) =>
      field.key == 'masterOffice' ||
      field.key == 'trustType' ||
      field.label == 'Bank Type';

  static String displayLabel(KycFieldDefinition field, String value) =>
      switch ((field.key, value)) {
        ('accountType', 'Current') => 'Current Account',
        ('masterOffice', 'Makhanda / Grahamstown') =>
          'Makhanda / Grahamstown (EC)',
        ('trustType', 'Testamentary') => 'Testamentary (created by will)',
        ('stokvelType', 'Investment') => 'Investment Stokvel',
        _ => value,
      };

  static Future<String?> show(
    BuildContext context,
    KycFieldDefinition field,
    String selected,
  ) {
    final court = field.key == 'masterOffice';
    final trust = field.key == 'trustType';
    return showSelectionSheet<String>(
      context,
      builder: (context) => SelectionSheetFrame(
        height: trust ? 624 : 696,
        title: court
            ? 'Court office location'
            : trust
            ? 'Trust Type'
            : 'Select Bank',
        titleLeft: court
            ? 51
            : trust
            ? 53
            : 44,
        titleWidth: 273,
        closeLeft: trust
            ? 339
            : court
            ? 334
            : 340,
        children: [
          for (final (index, value) in field.options.indexed)
            SelectionSheetRow(
              label: displayLabel(field, value),
              selected: selected == value,
              onTap: () => Navigator.pop(context, value),
              divider: index != field.options.length - 1,
              leading: court
                  ? const AppIcon(AppAssets.investorCourtFlag, size: 24)
                  : null,
            ),
        ],
      ),
    );
  }
}
