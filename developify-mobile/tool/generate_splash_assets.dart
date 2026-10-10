import 'dart:io';
import 'dart:ui' as ui;

import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Generate native launch images from the plain Developify SVG', () async {
    final source = await vg.loadPicture(
      SvgStringLoader(File(AppAssets.nativeSplash).readAsStringSync()),
      null,
    );
    Future<void> render(String path, double scale, {int? canvasSize}) async {
      final width = canvasSize ?? (295 * scale).round();
      final height = canvasSize ?? (68 * scale).round();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder)
        ..translate((width - 295 * scale) / 2, (height - 68 * scale) / 2)
        ..scale(scale);
      canvas.drawPicture(source.picture);
      final picture = recorder.endRecording();
      final image = await picture.toImage(width, height);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
    }

    const android = 'android/app/src/main/res';
    for (final density in {
      'mdpi': 1.0,
      'hdpi': 1.5,
      'xhdpi': 2.0,
      'xxhdpi': 3.0,
      'xxxhdpi': 4.0,
    }.entries) {
      await render(
        '$android/drawable-${density.key}/developify_splash.png',
        density.value,
      );
    }
    await render(
      '$android/drawable-xxxhdpi/developify_splash_android12.png',
      720 / 295,
      canvasSize: 1152,
    );
    const ios = 'ios/Runner/Assets.xcassets/LaunchImage.imageset';
    for (var scale = 1; scale <= 3; scale++) {
      await render(
        '$ios/LaunchImage${scale == 1 ? '' : '@${scale}x'}.png',
        scale.toDouble(),
      );
    }
    source.picture.dispose();
  });
}
