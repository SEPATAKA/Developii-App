import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/utils/money.dart';
import 'package:developify_mobile/features/investor/domain/investor_project.dart';
import 'package:developify_mobile/features/investor/domain/portfolio_analytics.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';

class PortfolioAnalyticsView extends StatelessWidget {
  const PortfolioAnalyticsView({
    super.key,
    required this.data,
    required this.period,
    required this.onPeriod,
  });
  final PortfolioAnalytics data;
  final PortfolioPeriod period;
  final ValueChanged<PortfolioPeriod> onPeriod;

  @override
  Widget build(BuildContext context) => InvestorPage(
    title: 'Analytics',
    child: ListView(
      padding: EdgeInsets.only(top: 32.w, bottom: 36.w),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(9.r),
          child: ColoredBox(
            color: AppColors.investorCard,
            child: Row(
              children: [
                for (final (value, label) in const [
                  (PortfolioPeriod.year, '12 month'),
                  (PortfolioPeriod.month, '30 days'),
                  (PortfolioPeriod.week, '7 days'),
                  (PortfolioPeriod.day, '24 hours'),
                ])
                  Expanded(
                    child: Semantics(
                      selected: period == value,
                      child: TextButton(
                        onPressed: () => onPeriod(value),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(44, 44),
                          backgroundColor: period == value
                              ? AppColors.primary
                              : AppColors.investorCard,
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 10.w,
                          ),
                          shape: const RoundedRectangleBorder(),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.text(
                            14,
                            weight: FontWeight.w500,
                            height: 20 / 14,
                            color: period == value
                                ? AppColors.white
                                : AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: 19.w),
        PortfolioHistoryChart(key: ValueKey(period), points: data.points),
        SizedBox(height: 18.w),
        Row(
          children: [
            Expanded(
              child: _Statistic(
                'Total Invested',
                Money.amount(data.invested, decimals: false),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _Statistic(
                'Projected Payout',
                Money.amount(data.projected, decimals: false),
                primary: true,
              ),
            ),
          ],
        ),
        SizedBox(height: 7.w),
        Row(
          children: [
            Expanded(
              child: _Statistic(
                'Total ROI',
                '${(data.roiBasisPoints / 100).toStringAsFixed(1)}%',
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _Statistic(
                'Distributions Payout',
                Money.amount(data.earned, decimals: false),
              ),
            ),
          ],
        ),
        SizedBox(height: 21.w),
        Text('By Project type', style: AppTextStyles.section),
        SizedBox(height: 12.w),
        InvestorSurface(
          radius: 11,
          border: AppColors.border,
          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 14.w),
          child: data.allocations.isEmpty
              ? Text(
                  'No investment allocation yet.',
                  style: AppTextStyles.text(14, color: AppColors.muted),
                )
              : Column(
                  children: [
                    for (final (index, allocation)
                        in data.allocations.indexed) ...[
                      if (index > 0) SizedBox(height: 19.w),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              allocation.category.label,
                              style: AppTextStyles.text(
                                14,
                                weight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            '${(allocation.basisPoints / 100).toStringAsFixed(0)}%',
                            style: AppTextStyles.text(
                              14,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 9.w),
                      Semantics(
                        label: '${allocation.category.name} allocation',
                        value: Money.amount(allocation.amount),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4.r),
                          child: LinearProgressIndicator(
                            value: allocation.basisPoints / 10000,
                            minHeight: 5.w,
                            backgroundColor: AppColors.borderStrong,
                            color: switch (allocation.category) {
                              ProjectCategory.residential => AppColors.primary,
                              ProjectCategory.hospitality =>
                                AppColors.investorLink,
                              ProjectCategory.commercial =>
                                AppColors.investorGrowth,
                              ProjectCategory.industrial ||
                              ProjectCategory.retail => AppColors.muted,
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    ),
  );
}

class _Statistic extends StatelessWidget {
  const _Statistic(this.label, this.value, {this.primary = false});
  final String label;
  final String value;
  final bool primary;

  @override
  Widget build(BuildContext context) => InvestorSurface(
    radius: 11,
    border: AppColors.border,
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.w),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.text(
            14,
            weight: FontWeight.w500,
            color: AppColors.muted,
            height: 26 / 14,
            letterSpacing: -.28,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.text(
            16,
            weight: FontWeight.w600,
            color: primary ? AppColors.primary : AppColors.gray900,
            height: 26 / 16,
            letterSpacing: -.32,
          ),
        ),
      ],
    ),
  );
}

class PortfolioHistoryChart extends StatefulWidget {
  const PortfolioHistoryChart({super.key, required this.points});
  final List<PortfolioPoint> points;

  @override
  State<PortfolioHistoryChart> createState() => _PortfolioHistoryChartState();
}

class _PortfolioHistoryChartState extends State<PortfolioHistoryChart> {
  int _selected = 3;

  void _select(int index) =>
      setState(() => _selected = index.clamp(0, widget.points.length - 1));

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) return const SizedBox.shrink();
    final selected = _selected.clamp(0, widget.points.length - 1);
    final point = widget.points[selected];
    return InvestorSurface(
      color: AppColors.white,
      radius: 11,
      border: AppColors.border,
      padding: EdgeInsets.fromLTRB(7.w, 49.w, 7.w, 23.w),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth - 22.w;
              final values = widget.points
                  .map((point) => point.amount.minorUnits)
                  .toList();
              final offsets = _PortfolioHistoryPainter.offsets(
                values,
                Size(width, 216.w),
              );
              final tooltipWidth = math.min(147.w, width);
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 11.w),
                child: Semantics(
                  label: 'Invested capital history',
                  value: '${point.label}, ${Money.amount(point.amount)}',
                  increasedValue: selected < widget.points.length - 1
                      ? widget.points[selected + 1].label
                      : null,
                  decreasedValue: selected > 0
                      ? widget.points[selected - 1].label
                      : null,
                  onIncrease: selected < widget.points.length - 1
                      ? () => _select(selected + 1)
                      : null,
                  onDecrease: selected > 0 ? () => _select(selected - 1) : null,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) => _select(
                      (details.localPosition.dx / width * (values.length - 1))
                          .round(),
                    ),
                    onHorizontalDragUpdate: (details) => _select(
                      (details.localPosition.dx / width * (values.length - 1))
                          .round(),
                    ),
                    child: SizedBox(
                      height: 216.w,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: _PortfolioHistoryPainter(
                                  values,
                                  selected,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: (offsets[selected].dx + 16.w).clamp(
                              0,
                              math.max(0, width - tooltipWidth),
                            ),
                            top: (offsets[selected].dy - 23.w).clamp(0, 160.w),
                            width: tooltipWidth,
                            child: IgnorePointer(
                              child: InvestorSurface(
                                color: AppColors.white,
                                radius: 11,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 15.w,
                                  vertical: 13.w,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        Money.compact(point.amount),
                                        style: AppTextStyles.text(
                                          12.388,
                                          weight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Flexible(
                                      child: Text(
                                        point.label,
                                        style: AppTextStyles.text(
                                          12.388,
                                          color: AppColors.muted,
                                        ),
                                      ),
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
            },
          ),
          SizedBox(height: 9.w),
          Row(
            children: [
              for (final point in widget.points)
                Expanded(
                  child: Text(
                    point.label,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.text(
                      14.397,
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PortfolioHistoryPainter extends CustomPainter {
  _PortfolioHistoryPainter(this.values, this.selected);
  final List<int> values;
  final int selected;

  static List<Offset> offsets(List<int> values, Size size) {
    final maximum = values.fold<int>(0, math.max);
    final minimum = values.fold<int>(maximum, math.min);
    final range = math.max(maximum - minimum, math.max(1, maximum * .2));
    return [
      for (var index = 0; index < values.length; index++)
        Offset(
          values.length < 2
              ? size.width / 2
              : index / (values.length - 1) * size.width,
          size.height * (.75 - (values[index] - minimum) / range * .45),
        ),
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final points = offsets(values, size);
    final grid = Paint()
      ..color = AppColors.borderStrong
      ..strokeWidth = 1;
    for (final point in points) {
      for (var y = 0.0; y < size.height; y += 12) {
        canvas.drawLine(
          Offset(point.dx, y),
          Offset(point.dx, math.min(y + 7, size.height)),
          grid,
        );
      }
    }
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }
    final area = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.secondaryButton, AppColors.transparent],
        ).createShader(Offset.zero & size),
    );
    final point = points[selected.clamp(0, points.length - 1)];
    canvas.drawRect(
      Rect.fromLTRB(
        math.max(0, point.dx - 26),
        point.dy,
        math.min(size.width, point.dx + 26),
        size.height,
      ),
      Paint()..color = AppColors.secondaryButton,
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(point, 6.8, Paint()..color = AppColors.white);
    canvas.drawCircle(point, 4.1, Paint()..color = AppColors.primary);
  }

  @override
  bool shouldRepaint(_PortfolioHistoryPainter oldDelegate) =>
      oldDelegate.selected != selected ||
      oldDelegate.values.length != values.length ||
      List.generate(
        values.length,
        (index) => index,
      ).any((index) => oldDelegate.values[index] != values[index]);
}
