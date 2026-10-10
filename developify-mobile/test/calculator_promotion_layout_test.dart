import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_home_promotions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers/fonts.dart';
import 'helpers/fidelity_capture.dart';

void main() {
  setUpAll(loadAppFonts);
  for (final width in [360.0, 393.0, 412.0]) {
    for (final scale in [1.0, 1.3, 1.6, 2.0]) {
      testWidgets('Calculator remains horizontal at $width / $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 852);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final boundary = GlobalKey();
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(393, 852),
            minTextAdapt: true,
            builder: (_, _) => MaterialApp(
              theme: AppTheme.light,
              home: Scaffold(
                body: RepaintBoundary(
                  key: boundary,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: const InvestorHomePromotions(),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final banner = tester.getRect(find.byType(InvestorHomePromotions));
        final copy = tester.getRect(
          find.byKey(const ValueKey('promotion-copy')),
        );
        final art = tester.getRect(
          find.byKey(const ValueKey('promotion-artwork')),
        );
        final heading = tester.renderObject<RenderParagraph>(
          find.text('Try the investment calculator'),
        );
        final subtitle = tester.renderObject<RenderParagraph>(
          find.textContaining('See projected return before'),
        );
        final headingLines = heading.getBoxesForSelection(
          TextSelection(
            baseOffset: 0,
            extentOffset: heading.text.toPlainText().length,
          ),
        );
        final subtitleLines = subtitle.getBoxesForSelection(
          TextSelection(
            baseOffset: 0,
            extentOffset: subtitle.text.toPlainText().length,
          ),
        );
        // ignore: avoid_print
        print(
          'METRICS $width/$scale banner=$banner copy=$copy art=$art font=${heading.text.style?.fontSize} headline=${headingLines.map((b) => b.toRect()).toList()} subtitle=${subtitleLines.map((b) => b.toRect()).toList()}',
        );
        expect(copy.right, lessThanOrEqualTo(art.left + .1));
        expect(art.top, lessThan(copy.bottom));
        expect(art.bottom, greaterThan(copy.top));
        expect(
          banner.height,
          closeTo(
            (copy.height + 34 * banner.width / 370).clamp(
              92 * banner.width / 370,
              double.infinity,
            ),
            1,
          ),
        );
        expect(art.center.dy, closeTo(banner.center.dy, .1));
        expect(banner.width, closeTo(width * 369 / 393, .1));
        expect(banner.height, closeTo(92 * banner.width / 370, 1));
        expect(headingLines.length, 1);
        expect(subtitleLines.length, 2);
        expect(heading.textScaler.scale(14), 14);
        expect(subtitle.textScaler.scale(12), 12);
        expect(
          MediaQuery.textScalerOf(
            tester.element(find.byType(InvestorHomePromotions)),
          ).scale(14),
          closeTo(14 * scale, .01),
        );
        expect(tester.takeException(), isNull);
        if (width == 393 && (scale == 1 || scale == 2)) {
          await captureFidelity(tester, boundary, "widget-$width-$scale");
        }
      });
    }
  }
}
