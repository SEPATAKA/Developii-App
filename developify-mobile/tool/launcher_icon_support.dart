import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image/image.dart' as img;

const launcherSourceSha256 =
    'c80eaf03b51d4bf6af5cb9512f1bb139250b851f98f20ccb17063257bb381d5b';
const launcherSourceWidth = 167.834;
const launcherSourceHeight = 179.777;
const androidVisibleMarkScale = 0.68;
const iosMarkScale = 0.72;
const launcherOffsetX = -0.008;
const launcherOffsetY = 0.008;
const androidResourceRoot = 'android/app/src/main/res';
const iosIconRoot = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
const androidDensities = {
  'mdpi': 48,
  'hdpi': 72,
  'xhdpi': 96,
  'xxhdpi': 144,
  'xxxhdpi': 192,
};
const launcherColors = ['#018091', '#03B281', '#68E470'];

String readLauncherSource() {
  final bytes = File(AppAssets.launcherMark).readAsBytesSync();
  if (sha256.convert(bytes).toString() != launcherSourceSha256) {
    throw StateError('Launcher source differs from the approved brand SVG.');
  }
  return utf8.decode(bytes);
}

Map<String, int> iosIconInventory() {
  final contents =
      jsonDecode(File('$iosIconRoot/Contents.json').readAsStringSync())
          as Map<String, dynamic>;
  return {
    for (final entry in contents['images'] as List<dynamic>)
      entry['filename'] as String:
          (double.parse((entry['size'] as String).split('x').first) *
                  double.parse((entry['scale'] as String).replaceAll('x', '')))
              .round(),
  };
}

Future<img.Image> renderLauncher(
  int size, {
  required double markScale,
  bool opaque = true,
  double viewportFraction = 1,
}) async {
  final picture = await vg.loadPicture(
    SvgStringLoader(readLauncherSource()),
    null,
  );
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  if (opaque) canvas.drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src);
  final viewport = size * viewportFraction;
  final height = viewport * markScale;
  final scale = height / launcherSourceHeight;
  canvas.translate(
    (size - launcherSourceWidth * scale) / 2 + viewport * launcherOffsetX,
    (size - height) / 2 + viewport * launcherOffsetY,
  );
  canvas.scale(scale);
  canvas.drawPicture(picture.picture);
  final composition = recorder.endRecording();
  final raster = await composition.toImage(size, size);
  final bytes = (await raster.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final result = img.Image.fromBytes(
    width: size,
    height: size,
    bytes: bytes.buffer,
    bytesOffset: bytes.offsetInBytes,
    numChannels: 4,
  );
  raster.dispose();
  composition.dispose();
  picture.picture.dispose();
  return opaque ? result.convert(numChannels: 3) : result;
}

String androidForegroundXml() {
  final paths = RegExp(r'<path\b[^>]+/>').allMatches(readLauncherSource());
  final scale = 72 * androidVisibleMarkScale / launcherSourceHeight;
  final x = (108 - launcherSourceWidth * scale) / 2 + 72 * launcherOffsetX;
  final y = (108 - 72 * androidVisibleMarkScale) / 2 + 72 * launcherOffsetY;
  final elements = paths
      .map((match) {
        final path = match.group(0)!;
        final data = RegExp(r'\bd="([^"]+)"').firstMatch(path)!.group(1)!;
        final fill = RegExp(r'\bfill="([^"]+)"').firstMatch(path)!.group(1)!;
        return '        <path android:fillColor="$fill" '
            'android:fillType="evenOdd" android:pathData="$data" />';
      })
      .join('\n');
  return '''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <group android:scaleX="$scale" android:scaleY="$scale"
        android:translateX="$x" android:translateY="$y">
$elements
    </group>
</vector>
''';
}

const adaptiveIconXml = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
''';

Map<String, double> paintedMetrics(
  img.Image image, {
  bool transparent = false,
}) {
  var left = image.width;
  var right = -1;
  var top = image.height;
  var bottom = -1;
  var painted = 0;
  for (final pixel in image) {
    final visible = transparent
        ? pixel.a > 16
        : (255 - pixel.r) + (255 - pixel.g) + (255 - pixel.b) > 48;
    if (!visible) continue;
    if (pixel.x < left) left = pixel.x;
    if (pixel.x > right) right = pixel.x;
    if (pixel.y < top) top = pixel.y;
    if (pixel.y > bottom) bottom = pixel.y;
    painted++;
  }
  if (painted == 0) throw StateError('Launcher mark has no painted pixels.');
  return {
    'widthPercent': (right - left + 1) / image.width * 100,
    'heightPercent': (bottom - top + 1) / image.height * 100,
    'boundsAreaRatio':
        (right - left + 1) * (bottom - top + 1) / image.width / image.height,
    'paintedAreaRatio': painted / image.width / image.height,
    'centerX': (left + right + 1) / 2 / image.width,
    'centerY': (top + bottom + 1) / 2 / image.height,
  };
}
