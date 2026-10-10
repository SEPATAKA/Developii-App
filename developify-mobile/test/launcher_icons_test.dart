import 'dart:convert';
import 'dart:io';

import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../tool/launcher_icon_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void checkBounds(img.Image image, double scale, String path) {
    final metrics = paintedMetrics(image);
    final tolerance = 200 / image.height;
    expect(
      metrics['heightPercent'],
      closeTo(scale * 100, tolerance),
      reason: path,
    );
    expect(
      metrics['widthPercent'],
      closeTo(
        scale * 100 * launcherSourceWidth / launcherSourceHeight,
        tolerance,
      ),
      reason: path,
    );
    expect(metrics['boundsAreaRatio'], greaterThan(0.38), reason: path);
    expect(metrics['centerX'], closeTo(0.5, 0.035), reason: path);
    expect(metrics['centerY'], closeTo(0.5, 0.035), reason: path);
    for (final point in [(0, 0), (image.width - 1, image.height - 1)]) {
      final pixel = image.getPixel(point.$1, point.$2);
      expect([pixel.r, pixel.g, pixel.b], [255, 255, 255], reason: path);
    }
  }

  test('Canonical launcher asset is the exact three-path coloured mark', () {
    final source = readLauncherSource();
    expect(RegExp(r'<path\b').allMatches(source).length, 3);
    expect(source, isNot(contains('<text')));
    expect(source, isNot(contains('<image')));
    expect(source, isNot(contains('<rect')));
    for (final color in launcherColors) {
      expect(source, contains('fill="$color"'));
    }
    expect(AppAssets.launcherMark, isNot(contains('splash')));
  });

  test('All iOS AppIcon mappings exist at their required opaque RGB sizes', () {
    final inventory = iosIconInventory();
    expect(inventory.length, 15);
    expect(inventory['Icon-App-1024x1024@1x.png'], 1024);
    for (final entry in inventory.entries) {
      final path = '$iosIconRoot/${entry.key}';
      final bytes = File(path).readAsBytesSync();
      final image = img.decodePng(bytes)!;
      expect(
        [image.width, image.height],
        [entry.value, entry.value],
        reason: path,
      );
      expect(
        bytes[25],
        2,
        reason: '$path must be RGB PNG without an alpha channel',
      );
      expect(image.numChannels, 3, reason: path);
      checkBounds(image, iosMarkScale, path);
    }
    final master = img.decodePng(
      File('$iosIconRoot/Icon-App-1024x1024@1x.png').readAsBytesSync(),
    )!;
    // Metrics are emitted for review; the bounds assertions prevent padded regressions.
    stdout.writeln(
      'iOS launcher metrics: ${jsonEncode(paintedMetrics(master))}',
    );
  });

  test(
    'Android legacy and round fallbacks have matching full white canvases',
    () {
      for (final entry in androidDensities.entries) {
        final directory = '$androidResourceRoot/mipmap-${entry.key}';
        final icon = File('$directory/ic_launcher.png').readAsBytesSync();
        final round = File(
          '$directory/ic_launcher_round.png',
        ).readAsBytesSync();
        expect(
          round,
          icon,
          reason: 'Both names must use the same source composition',
        );
        final image = img.decodePng(icon)!;
        expect([image.width, image.height], [entry.value, entry.value]);
        checkBounds(image, androidVisibleMarkScale, directory);
      }
    },
  );

  test(
    'Adaptive icons separate the white background from exact transparent paths',
    () async {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      expect(manifest, contains('android:icon="@mipmap/ic_launcher"'));
      expect(
        manifest,
        contains('android:roundIcon="@mipmap/ic_launcher_round"'),
      );
      final background = File(
        '$androidResourceRoot/values/launcher_colors.xml',
      ).readAsStringSync();
      expect(
        background,
        contains('<color name="ic_launcher_background">#FFFFFF</color>'),
      );
      for (final name in ['ic_launcher', 'ic_launcher_round']) {
        expect(
          File(
            '$androidResourceRoot/mipmap-anydpi-v26/$name.xml',
          ).readAsStringSync(),
          adaptiveIconXml,
        );
      }
      final foreground = File(
        '$androidResourceRoot/drawable/ic_launcher_foreground.xml',
      ).readAsStringSync();
      expect(foreground, androidForegroundXml());
      expect(RegExp(r'<path\b').allMatches(foreground).length, 3);
      expect(foreground, isNot(contains('#FFFFFF')));
      expect(foreground, isNot(contains('splash')));
      expect(foreground, isNot(contains('17:17')));
      final rendered = await renderLauncher(
        1080,
        markScale: androidVisibleMarkScale,
        viewportFraction: 72 / 108,
        opaque: false,
      );
      expect(rendered.numChannels, 4);
      expect(rendered.getPixel(0, 0).a, 0);
      expect(rendered.getPixel(540, 100).a, 0);
      final metrics = paintedMetrics(rendered, transparent: true);
      expect(metrics['heightPercent'], closeTo(68 * 72 / 108, 0.3));
      expect(metrics['widthPercent'], greaterThan(42));
      expect(metrics['centerX'], closeTo(0.5, 0.02));
      expect(metrics['centerY'], closeTo(0.5, 0.02));
      for (final pixel in rendered) {
        if (pixel.a < 16) continue;
        final dx = (pixel.x + 0.5 - 540) / 720;
        final dy = (pixel.y + 0.5 - 540) / 720;
        expect(
          dx * dx + dy * dy,
          lessThan(0.25),
          reason: 'Circle mask clips the mark',
        );
      }
      stdout.writeln('Android adaptive metrics: ${jsonEncode(metrics)}');
    },
  );
}
