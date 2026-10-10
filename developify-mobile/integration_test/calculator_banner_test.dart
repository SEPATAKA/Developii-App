import 'dart:ui' as ui;
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_home_promotions.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../test/helpers/native_assets.dart';

void main() {
  final binding = _NativeTextBinding();
  testWidgets('Native calculator banner composition and return navigation', (
    tester,
  ) async {
    final dependencies = await AppDependencies.create(
      environment: const AppEnvironment(mockDelay: Duration.zero),
    );
    dependencies.session.signIn(
      const AppUser(
        id: 'banner-qa',
        name: 'Babatunde Yusuf',
        email: 'investor@example.test',
      ),
      experience: Experience.investor,
    );
    final router = createAppRouter(
      dependencies,
      initialLocation: '/investor/home',
    );
    await tester.pumpWidget(
      DevelopifyApp(dependencies: dependencies, router: router),
    );
    await tester.pumpAndSettle();
    final scroll = find
        .descendant(
          of: find.byKey(const PageStorageKey('investor-home-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;
    final promotion = find.byType(InvestorHomePromotions);
    await tester.scrollUntilVisible(
      promotion,
      180,
      scrollable: scroll,
      maxScrolls: 30,
    );
    final position = tester.state<ScrollableState>(scroll).position;
    position.jumpTo(
      (position.pixels - 80).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );
    await tester.pumpAndSettle();
    await settleNativeImages(tester);
    final banner = tester.getRect(promotion);
    final copy = tester.getRect(find.byKey(const ValueKey('promotion-copy')));
    final art = tester.getRect(find.byKey(const ValueKey('promotion-artwork')));
    final heading = tester.renderObject<RenderParagraph>(
      find.text('Try the investment calculator'),
    );
    final subtitle = tester.renderObject<RenderParagraph>(
      find.textContaining('See projected return before'),
    );
    List<Map<String, double>> boxes(RenderParagraph p) => p
        .getBoxesForSelection(
          TextSelection(
            baseOffset: 0,
            extentOffset: p.text.toPlainText().length,
          ),
        )
        .map(
          (b) => {
            'left': b.left,
            'top': b.top,
            'right': b.right,
            'bottom': b.bottom,
          },
        )
        .toList();
    Map<String, double> rect(Rect r) => {
      'x': r.left,
      'y': r.top,
      'width': r.width,
      'height': r.height,
    };
    final media = MediaQuery.of(tester.element(promotion));
    binding.reportData = {
      'viewport': {
        'width': media.size.width,
        'height': media.size.height,
        'dpr': media.devicePixelRatio,
        'nativeScaledFonts': {
          for (final size in [12.0, 14.0, 36.0])
            '$size': ui.PlatformDispatcher.instance.scaleFontSize(size),
        },
      },
      'banner': rect(banner),
      'copy': rect(copy),
      'art': rect(art),
      'headlineFont': heading.text.style!.fontSize,
      'headlineEffectiveFont': heading.textScaler.scale(
        heading.text.style!.fontSize!,
      ),
      'headlineLines': boxes(heading),
      'subtitleLines': boxes(subtitle),
      'recentSectionGap':
          tester.getTopLeft(find.text('Recently active')).dy - banner.bottom,
    };
    expect(copy.right, lessThan(art.left));
    expect(art.center.dy, closeTo(banner.center.dy, .5));
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
    expect(banner.height, closeTo(92 * banner.width / 370, 1));
    expect(boxes(heading).length, 1);
    expect(boxes(subtitle).length, 2);
    if (defaultTargetPlatform == TargetPlatform.android) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
    }
    await binding.takeScreenshot('banner');
    final offset = tester.state<ScrollableState>(scroll).position.pixels;
    await tester.tap(find.text('Try the investment calculator'));
    await tester.pumpAndSettle();
    expect(find.text('Select a project'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('calculator-project-marula-heights')),
    );
    await tester.pumpAndSettle();
    expect(router.state.uri.path, contains('calculator'));
    expect(find.text('Monthly Distribution'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    expect(tester.state<ScrollableState>(scroll).position.pixels, offset);
    expect(tester.getRect(promotion), banner);
    expect(find.text('Unlock Your Investment Potential'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    await tester.runAsync(dependencies.dispose);
  });
}

class _NativeTextBinding extends IntegrationTestWidgetsFlutterBinding {
  @override
  Widget wrapWithDefaultView(Widget rootWidget) => super.wrapWithDefaultView(
    MediaQuery(
      data: MediaQueryData.fromView(
        ui.PlatformDispatcher.instance.implicitView!,
      ),
      child: rootWidget,
    ),
  );
}
