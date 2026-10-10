import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';

class ProjectSectionTabs extends StatelessWidget {
  const ProjectSectionTabs({
    super.key,
    required this.selected,
    required this.onSelected,
    this.includeDocuments = false,
  });
  final int selected;
  final ValueChanged<int> onSelected;
  final bool includeDocuments;

  static const _baseTabs = <(String, double)>[
    ('Overview', 84.0),
    ('Details', 77.0),
    ('Developer', 96.0),
    ('Updates', 76.0),
    ('Location', 86.0),
    ('Plans', 68.0),
  ];

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ..._baseTabs,
      if (includeDocuments) ('Documents', 96.0),
    ];
    final lastIndex = tabs.length - 1;
    return SingleChildScrollView(
      key: const PageStorageKey('project-section-tabs'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (index, item) in tabs.indexed)
            Padding(
              padding: EdgeInsets.only(
                right: index == lastIndex ? 0 : (includeDocuments ? 9 : 12).w,
              ),
              child: Semantics(
                selected: selected == index,
                button: true,
                child: TextButton(
                  onPressed: () => onSelected(index),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: item.$2.w,
                      minHeight: 34.w,
                    ),
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 4.w,
                    ),
                    decoration: BoxDecoration(
                      color: selected == index
                          ? AppColors.primary
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(32.r),
                    ),
                    child: Text(
                      item.$1,
                      style: AppTextStyles.text(
                        14,
                        weight: FontWeight.w500,
                        height: 26 / 14,
                        letterSpacing: -.28,
                        color: selected == index
                            ? AppColors.surface
                            : AppColors.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
