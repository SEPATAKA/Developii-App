import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';

Future<T?> showSelectionSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  barrierColor: AppColors.modalScrim,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(14.w)),
  ),
  clipBehavior: Clip.antiAlias,
  builder: builder,
);

class SelectionSheetFrame extends StatelessWidget {
  const SelectionSheetFrame({
    super.key,
    required this.height,
    required this.title,
    required this.titleLeft,
    required this.titleWidth,
    required this.closeLeft,
    required this.children,
  });

  final double height;
  final String title;
  final double titleLeft;
  final double titleWidth;
  final double closeLeft;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final extraBottom = math.max(
      0.0,
      MediaQuery.viewPaddingOf(context).bottom - 34.w,
    );
    return SizedBox(
      height: height.w + extraBottom,
      child: Column(
        children: [
          SizedBox(
            height: 101.w,
            child: Stack(
              children: [
                Positioned(
                  left: titleLeft.w,
                  top: 42.w,
                  width: titleWidth.w,
                  height: 33.w,
                  child: Center(
                    child: Text(
                      title,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      style: AppTextStyles.text(
                        16,
                        weight: FontWeight.w500,
                        color: AppColors.gray900,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: closeLeft.w - (44 - 33.w) / 2,
                  top: 42.w - (44 - 33.w) / 2,
                  child: const SelectionSheetCloseButton(),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(21.w, 0, 17.w, extraBottom),
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class SelectionSheetRow extends StatelessWidget {
  const SelectionSheetRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.divider,
    this.leading,
    this.showChevron = true,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool divider;
  final Widget? leading;
  final bool showChevron;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: divider
            ? const Border(bottom: BorderSide(color: AppColors.border))
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 72.w),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 14.w),
            child: Row(
              children: [
                if (leading != null) ...[leading!, SizedBox(width: 12.2456.w)],
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.text(
                      16.327486,
                      weight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                  ),
                ),
                if (showChevron) const AppIcon(AppAssets.chevronRight),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class SelectionSheetCloseButton extends StatelessWidget {
  const SelectionSheetCloseButton({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Close',
    child: InkResponse(
      key: const ValueKey('selection-sheet-close'),
      onTap: () => Navigator.pop(context),
      radius: 22,
      child: SizedBox.square(
        dimension: 44,
        child: Center(
          child: SizedBox.square(
            dimension: 33.w,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.borderStrong,
                  width: 1.375.w,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 6.w,
                    top: 7.w,
                    child: const AppIcon(AppAssets.sheetClose, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
