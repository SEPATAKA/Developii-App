import 'package:developify_mobile/features/investor/domain/investment_policy.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_switch.dart';
import 'package:developify_mobile/features/investor/domain/investor_project.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/stores/explore_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';

class ExploreFilterScreen extends StatefulWidget {
  const ExploreFilterScreen({
    super.key,
    required this.store,
    required this.initial,
  });
  final ExploreStore store;
  final ProjectFilter initial;

  @override
  State<ExploreFilterScreen> createState() => _ExploreFilterScreenState();
}

class _ExploreFilterScreenState extends State<ExploreFilterScreen> {
  ExploreStore get store => widget.store;
  ProjectFilter get initial => widget.initial;
  late bool _sortSelected = initial.sort != ProjectSort.trending;
  late bool _returnSelected = initial.minimumReturnBasisPoints != 0;

  void _apply(BuildContext context) {
    final parameters = store.filter.parameters;
    if (context.canPop()) {
      context.pop(Uri(queryParameters: parameters).query);
    } else {
      context.goNamed(InvestorRoutes.explore, queryParameters: parameters);
    }
  }

  @override
  Widget build(BuildContext context) => InvestorPage(
    title: 'Filter Projects',
    bodyPadding: EdgeInsets.only(left: 11.w, right: 13.w),
    child: Observer(
      builder: (_) => ListView(
        padding: EdgeInsets.only(top: 31.w, bottom: 18.w),
        children: [
          _heading('Location'),
          _choices([
            for (final location in ProjectFilter.locations)
              _FilterChoice(
                label: location,
                selected: store.location == location,
                onTap: () => store.setLocation(
                  store.location == location ? '' : location,
                ),
              ),
          ]),
          SizedBox(height: 19.w),
          _heading('Project Type'),
          _choices([
            for (final category in ProjectCategory.values)
              _FilterChoice(
                label: category.label,
                selected: store.category == category,
                onTap: () => store.selectCategory(
                  store.category == category ? null : category,
                ),
              ),
          ]),
          SizedBox(height: 22.w),
          _heading('Sort'),
          _choices(
            [
              for (final sort in ProjectSort.values)
                _FilterChoice(
                  label: sort.label,
                  selected:
                      (_sortSelected || store.sort != ProjectSort.trending) &&
                      store.sort == sort,
                  onTap: () {
                    setState(() => _sortSelected = true);
                    store.setSort(sort);
                  },
                ),
            ],
            rowLengths: [3, 2, 1],
            runSpacing: 8,
          ),
          SizedBox(height: 22.w),
          _heading('Investment Level'),
          _InvestmentRange(
            minimum: store.minimumInvestment,
            maximum: store.maximumInvestment,
            onChanged: store.setInvestmentRange,
          ),
          SizedBox(height: 42.w),
          _heading('Funding Status', bottom: 8),
          for (final (status, label) in const [
            (ProjectFundingStatus.open, 'Open for funding'),
            (ProjectFundingStatus.targetReached, 'Target Reached'),
            (ProjectFundingStatus.newToday, 'New Today'),
          ]) ...[
            Semantics(
              toggled: store.funding.contains(status),
              child: Material(
                color: AppColors.investorCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: InkWell(
                  onTap: () => store.toggleFunding(status),
                  borderRadius: BorderRadius.circular(16.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 17.w,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: AppTextStyles.text(
                              16,
                              weight: FontWeight.w500,
                              height: 26 / 16,
                              letterSpacing: -.32,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        AppSwitch.solid(
                          value: store.funding.contains(status),
                          showThumbIndicator: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.w),
          ],
          SizedBox(height: 8.w),
          _heading('Estimated ROI', bottom: 6),
          _choices(
            [
              for (final roi in [0, 1000, 1500])
                _FilterChoice(
                  label: roi == 0 ? 'Any' : '${roi ~/ 100}% +',
                  selected:
                      (_returnSelected || store.minimumReturn != 0) &&
                      store.minimumReturn == roi,
                  width: roi == 0 ? 107 : 115,
                  onTap: () {
                    setState(() => _returnSelected = true);
                    store.setReturn(roi);
                  },
                ),
            ],
            rowSpacings: [7],
          ),
          SizedBox(height: 44.w),
          AppButton(
            label: 'Apply Filter',
            onPressed:
                Uri(queryParameters: store.filter.parameters).query ==
                    Uri(queryParameters: initial.parameters).query
                ? null
                : () => _apply(context),
          ),
          SizedBox(height: 12.w),
          AppButton(
            label: 'Reset',
            style: AppButtonStyle.secondary,
            onPressed: () {
              setState(() {
                _sortSelected = false;
                _returnSelected = false;
              });
              store.resetFilters();
            },
          ),
        ],
      ),
    ),
  );

  Widget _heading(String title, {double bottom = 14}) => Padding(
    padding: EdgeInsets.only(bottom: bottom.w),
    child: Text(title, style: AppTextStyles.text(16, weight: FontWeight.w700)),
  );

  Widget _choices(
    List<Widget> children, {
    List<int> rowLengths = const [3, 3, 3],
    List<double> rowSpacings = const [12, 7, 9],
    double runSpacing = 4,
  }) {
    var start = 0;
    final rows = <Widget>[];
    for (var row = 0; start < children.length; row++) {
      final end = math.min(
        start + rowLengths[math.min(row, rowLengths.length - 1)],
        children.length,
      );
      if (rows.isNotEmpty) rows.add(SizedBox(height: runSpacing.w));
      rows.add(
        Wrap(
          spacing: rowSpacings[math.min(row, rowSpacings.length - 1)].w,
          runSpacing: runSpacing.w,
          children: children.sublist(start, end),
        ),
      );
      start = end;
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}

class _FilterChoice extends StatelessWidget {
  const _FilterChoice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.width,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double? width;

  double get _width =>
      width ??
      switch (label) {
        'Durban' => 77,
        'East London' || 'Hospitality' => 98,
        'Pretoria' ||
        'Port Elizabeth' ||
        'Industrial' ||
        'Retail' ||
        'Highest ROI' => 107,
        'Commercial' || 'Newest' => 108,
        'Johannesburg' => 115,
        'Bloemfontein' => 125,
        'Closing Soon' => 114,
        'Lowest Minimum' => 131,
        'Funding Progress' => 124,
        _ => 96,
      };

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22.r),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 44, maxWidth: _width.w),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 5.w),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.borderStrong,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.w),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.text(
                    14,
                    weight: FontWeight.w500,
                    height: 26 / 14,
                    letterSpacing: -.28,
                    color: selected ? AppColors.white : AppColors.muted,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _InvestmentRange extends StatelessWidget {
  const _InvestmentRange({
    required this.minimum,
    required this.maximum,
    required this.onChanged,
  });
  final int minimum;
  final int maximum;
  final void Function(int, int) onChanged;

  static double _position(int amount) =>
      math.log(amount / InvestmentPolicy.minimumMajorUnits) /
      math.log(50000 / InvestmentPolicy.minimumMajorUnits);
  static int _amount(double position) =>
      (InvestmentPolicy.minimumMajorUnits *
              math.pow(50000 / InvestmentPolicy.minimumMajorUnits, position))
          .round()
          .clamp(InvestmentPolicy.minimumMajorUnits, 50000);
  static String _label(int amount) => amount == 50000 ? 'R50k +' : 'R$amount';

  @override
  Widget build(BuildContext context) => Column(
    children: [
      LayoutBuilder(
        builder: (context, constraints) {
          final style = AppTextStyles.text(14, weight: FontWeight.w500);
          final label = _label(maximum);
          final painter = TextPainter(
            text: TextSpan(text: label, style: style),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(maxWidth: constraints.maxWidth);
          final width = painter.width;
          final height = painter.height;
          painter.dispose();
          final center =
              12.w + (constraints.maxWidth - 24.w) * _position(maximum);
          return SizedBox(
            height: height,
            child: Stack(
              children: [
                Positioned(
                  left: (center - width / 2).clamp(
                    0,
                    constraints.maxWidth - width,
                  ),
                  child: Text(label, style: style),
                ),
              ],
            ),
          );
        },
      ),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 8.w,
          activeTrackColor: AppColors.primary,
          inactiveTrackColor: AppColors.investorSliderTrack,
          thumbColor: AppColors.primary,
          rangeThumbShape: _InvestmentRangeThumb(scale: 1.w),
          rangeTrackShape: _InvestmentRangeTrack(scale: 1.w),
          valueIndicatorTextStyle: AppTextStyles.text(
            14,
            color: AppColors.white,
          ),
          showValueIndicator: ShowValueIndicator.onlyForContinuous,
        ),
        child: Stack(
          children: [
            SizedBox(
              height: 48.w,
              child: RangeSlider(
                padding: EdgeInsets.zero,
                values: RangeValues(_position(minimum), _position(maximum)),
                labels: RangeLabels(_label(minimum), _label(maximum)),
                semanticFormatterCallback: (value) =>
                    '${_label(_amount(value))} South African rand minimum investment',
                onChanged: (values) =>
                    onChanged(_amount(values.start), _amount(values.end)),
              ),
            ),
            Positioned(
              left: 16.w,
              right: 16.w,
              bottom: 1.w,
              child: IgnorePointer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var index = 0; index <= 20; index++)
                      Container(
                        width: (index % 10 == 0 ? 2 : 1).w,
                        height: (index % 10 == 0 ? 8 : 4).w,
                        color: AppColors.investorSliderTrack,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'R${InvestmentPolicy.minimumMajorUnits}',
              style: AppTextStyles.text(14, weight: FontWeight.w500),
            ),
            Text(
              'R50k +',
              style: AppTextStyles.text(14, weight: FontWeight.w500),
            ),
          ],
        ),
      ),
    ],
  );
}

class _InvestmentRangeTrack extends RoundedRectRangeSliderTrackShape {
  const _InvestmentRangeTrack({required this.scale});
  final double scale;

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) => Rect.fromLTWH(
    offset.dx + 12 * scale,
    offset.dy + (parentBox.size.height - sliderTheme.trackHeight!) / 2,
    math.max(0, parentBox.size.width - 24 * scale),
    sliderTheme.trackHeight!,
  );
}

class _InvestmentRangeThumb extends RoundRangeSliderThumbShape {
  _InvestmentRangeThumb({required this.scale})
    : super(enabledThumbRadius: 14 * scale, elevation: 0, pressedElevation: 0);

  final double scale;

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool? isOnTop,
    required SliderThemeData sliderTheme,
    TextDirection? textDirection,
    Thumb? thumb,
    bool? isPressed,
  }) {
    super.paint(
      context,
      center,
      activationAnimation: activationAnimation,
      enableAnimation: enableAnimation,
      isDiscrete: isDiscrete,
      isEnabled: isEnabled,
      isOnTop: isOnTop,
      sliderTheme: sliderTheme,
      textDirection: textDirection,
      thumb: thumb,
      isPressed: isPressed,
    );
    final paint = Paint()..color = AppColors.mint;
    for (final (x, height) in [(-4, 8), (0, 12), (4, 8)]) {
      context.canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center + Offset(x * scale, 0),
            width: 2 * scale,
            height: height * scale,
          ),
          Radius.circular(scale),
        ),
        paint,
      );
    }
  }
}
