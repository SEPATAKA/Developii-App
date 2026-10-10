import 'package:developify_mobile/core/widgets/adaptive_navigation_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/app/router/route_names.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';

class LandownerShell extends StatelessWidget {
  const LandownerShell({super.key, required this.shell});
  final StatefulNavigationShell shell;
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: shell.currentIndex == 0,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) shell.goBranch(0);
    },
    child: Scaffold(
      body: shell,
      bottomNavigationBar: LandownerBottomNavigation(
        currentIndex: shell.currentIndex,
        onSelected: (index) {
          if (index == -1) {
            context.pushNamed(Routes.submit, pathParameters: {'step': '1'});
          } else {
            shell.goBranch(index, initialLocation: index == shell.currentIndex);
          }
        },
      ),
    ),
  );
}

class LandownerBottomNavigation extends StatelessWidget {
  const LandownerBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    ('Home', AppAssets.navHomeActive, AppAssets.navHomeInactive, 0),
    (
      'Properties',
      AppAssets.navPropertiesActive,
      AppAssets.navPropertiesInactive,
      1,
    ),
    ('Submit', AppAssets.navSubmit, AppAssets.navSubmit, -1),
    ('Earnings', AppAssets.navEarningsActive, AppAssets.navEarningsInactive, 2),
    ('Profile', AppAssets.navProfileActive, AppAssets.navProfileInactive, 3),
  ];

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.white,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.coolGraySurface)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 1),
          child: AdaptiveNavigationRow(
            labels: [for (final item in _items) item.$1],
            children: [
              for (final item in _items)
                Semantics(
                  selected: currentIndex == item.$4,
                  button: true,
                  label: '${item.$1} tab',
                  child: InkWell(
                    key: ValueKey('landowner-tab-${item.$4}'),
                    onTap: () => onSelected(item.$4),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIcon(currentIndex == item.$4 ? item.$2 : item.$3),
                          SizedBox(height: 4.w),
                          Text(
                            item.$1,
                            style: AppTextStyles.text(
                              12,
                              weight: FontWeight.w500,
                              height: 1.55,
                              color: currentIndex == item.$4
                                  ? AppColors.primary
                                  : item.$4 == 3
                                  ? AppColors.muted
                                  : AppColors.iconMuted,
                            ).copyWith(letterSpacing: -.12.sp),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
