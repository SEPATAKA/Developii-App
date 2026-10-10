import 'package:flutter/material.dart';
import 'package:developify_mobile/core/widgets/selection_sheet.dart';

Future<String?> showPayoutSelectionSheet(
  BuildContext context, {
  required bool bank,
  required String selected,
}) => showSelectionSheet<String>(
  context,
  builder: (_) => SelectionSheetFrame(
    height: bank ? 696 : 264,
    title: bank ? 'Select Bank' : 'Select Account Type',
    titleLeft: bank ? 140 : 124,
    titleWidth: bank ? 81 : 141,
    closeLeft: bank ? 341.5 : 342,
    children: [
      for (final value in bank ? ['Standard Bank'] : ['Savings', 'Current'])
        SelectionSheetRow(
          label: value,
          selected: value == selected,
          divider: !bank && value == 'Savings',
          onTap: () => Navigator.pop(context, value),
        ),
    ],
  ),
);
