import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_switch.dart';

class PreferenceGroup extends StatelessWidget {
  const PreferenceGroup({
    super.key,
    required this.values,
    required this.onChanged,
    this.inactiveColor,
  });
  final Map<String, bool> values;
  final void Function(String key, bool value)? onChanged;
  final Color? inactiveColor;

  @override
  Widget build(BuildContext context) {
    final entries = values.entries.toList(growable: false);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10.w),
        border: Border.all(color: AppColors.border, width: 1.w),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 5.w),
        child: Column(
          children: [
            for (var index = 0; index < entries.length; index++) ...[
              _PreferenceRow(
                entry: entries[index],
                textInset: index == 1 ? 3 : 0,
                switchInset: switch (index) {
                  2 => 2,
                  3 => 6,
                  4 => 5,
                  _ => 3,
                },
                divider: index < 2 && index < entries.length - 1,
                onChanged: onChanged,
                inactiveColor: inactiveColor,
              ),
              if (index < entries.length - 1)
                SizedBox(
                  height: (index < 2 ? 2 : 8).w,
                  child: index < 2
                      ? null
                      : Center(
                          child: Container(
                            height: 1.w,
                            color: AppColors.borderStrong,
                          ),
                        ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    required this.entry,
    required this.textInset,
    required this.switchInset,
    required this.divider,
    required this.onChanged,
    required this.inactiveColor,
  });
  final MapEntry<String, bool> entry;
  final double textInset;
  final double switchInset;
  final bool divider;
  final void Function(String key, bool value)? onChanged;
  final Color? inactiveColor;

  @override
  Widget build(BuildContext context) => Semantics(
    label: entry.key,
    toggled: entry.value,
    enabled: onChanged != null,
    onTap: onChanged == null ? null : () => onChanged!(entry.key, !entry.value),
    excludeSemantics: true,
    child: Material(
      color: AppColors.transparent,
      child: InkWell(
        key: ValueKey('preference-${entry.key}'),
        onTap: onChanged == null
            ? null
            : () => onChanged!(entry.key, !entry.value),
        child: Stack(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  textInset.w,
                  12.w,
                  switchInset.w,
                  12.w,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key == 'Push Notification'
                            ? 'Push  Notification'
                            : entry.key,
                        style: AppTextStyles.text(
                          14,
                          weight: FontWeight.w500,
                          color: AppColors.muted,
                          height: 17 / 14,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    AppSwitch(value: entry.value, inactiveColor: inactiveColor),
                  ],
                ),
              ),
            ),
            if (divider)
              Positioned(
                left: 0,
                right: 0,
                bottom: 2.w,
                child: Container(height: 1.w, color: AppColors.borderStrong),
              ),
          ],
        ),
      ),
    ),
  );
}
