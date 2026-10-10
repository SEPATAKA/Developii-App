import 'package:flutter/material.dart';
import 'package:developify_mobile/core/widgets/selection_sheet.dart';

enum PropertySelection { propertyType, unit }

Future<String?> showPropertySelectionSheet(
  BuildContext context, {
  required PropertySelection selection,
  required String selected,
}) => showSelectionSheet<String>(
  context,
  builder: (_) =>
      PropertySelectionSheet(selection: selection, selected: selected),
);

class PropertySelectionSheet extends StatelessWidget {
  const PropertySelectionSheet({
    super.key,
    required this.selection,
    required this.selected,
  });
  final PropertySelection selection;
  final String selected;

  static const propertyTypes = [
    'Vacant Land',
    'Existing Building',
    'Mixed ( Vacant & Existing)',
  ];
  static const units = ['Square Metre', 'Hectares', 'Acres', 'Plot'];

  @override
  Widget build(BuildContext context) {
    final (title, height, left, width, close, choices) = switch (selection) {
      PropertySelection.propertyType => (
        'Property Type',
        335.0,
        139.5,
        96.0,
        337.5,
        propertyTypes,
      ),
      PropertySelection.unit => ('Unit Type', 405.0, 155.5, 64.0, 321.5, units),
    };
    return SelectionSheetFrame(
      key: ValueKey('${selection.name}-sheet'),
      height: height,
      title: title,
      titleLeft: left,
      titleWidth: width,
      closeLeft: close,
      children: [
        for (var index = 0; index < choices.length; index++)
          SelectionSheetRow(
            key: ValueKey('${selection.name}-$index'),
            label: choices[index],
            selected: selected == choices[index],
            onTap: () => Navigator.pop(context, choices[index]),
            divider: index < choices.length - 1,
          ),
      ],
    );
  }
}
