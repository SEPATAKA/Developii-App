import 'package:flutter/material.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/selection_sheet.dart';

Future<String?> showDeedsOfficeSelectionSheet(
  BuildContext context, {
  required String selected,
}) => showSelectionSheet<String>(
  context,
  builder: (_) => DeedsOfficeSelectionSheet(selected: selected),
);

class DeedsOfficeSelectionSheet extends StatelessWidget {
  const DeedsOfficeSelectionSheet({super.key, required this.selected});
  final String selected;

  static const offices = [
    'Cape Town (WC)',
    'Pretoria ( GP)',
    'Johannesburg (GP)',
    'Durban (KZN)',
    'Pietermaritzburg (KZN)',
    'Bloemfontein (FS)',
    'Makhanda / Grahamstwon (EC)',
    'Mbomblea / Nelspruit (MP)',
  ];

  @override
  Widget build(BuildContext context) => SelectionSheetFrame(
    key: const ValueKey('deeds-office-sheet'),
    height: 684,
    title: 'Deeds Office',
    titleLeft: 146,
    titleWidth: 88,
    closeLeft: 337,
    children: [
      for (var index = 0; index < offices.length; index++)
        SelectionSheetRow(
          key: ValueKey('deeds-office-$index'),
          label: offices[index],
          selected: selected == offices[index],
          onTap: () => Navigator.pop(context, offices[index]),
          divider: index < offices.length - 1,
          leading: const AppIcon(AppAssets.flagSouthAfrica),
        ),
    ],
  );
}
