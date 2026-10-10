import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'launcher_icon_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Generate native launcher resources from the approved brand mark',
    () async {
      void write(String path, List<int> bytes) {
        final file = File(path)..parent.createSync(recursive: true);
        file.writeAsBytesSync(bytes);
      }

      for (final entry in iosIconInventory().entries) {
        write(
          '$iosIconRoot/${entry.key}',
          img.encodePng(
            await renderLauncher(entry.value, markScale: iosMarkScale),
          ),
        );
      }
      for (final entry in androidDensities.entries) {
        final bytes = img.encodePng(
          await renderLauncher(entry.value, markScale: androidVisibleMarkScale),
        );
        for (final name in ['ic_launcher', 'ic_launcher_round']) {
          write('$androidResourceRoot/mipmap-${entry.key}/$name.png', bytes);
        }
      }
      for (final name in ['ic_launcher', 'ic_launcher_round']) {
        write(
          '$androidResourceRoot/mipmap-anydpi-v26/$name.xml',
          adaptiveIconXml.codeUnits,
        );
      }
      write(
        '$androidResourceRoot/drawable/ic_launcher_foreground.xml',
        androidForegroundXml().codeUnits,
      );
      write(
        '$androidResourceRoot/values/launcher_colors.xml',
        '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#FFFFFF</color>
</resources>
'''
            .codeUnits,
      );
      const previews = String.fromEnvironment('LAUNCHER_PREVIEW_DIR');
      if (previews.isNotEmpty) {
        for (final scale in [0.64, 0.68, 0.72, 0.76]) {
          write(
            '$previews/candidate-${(scale * 100).round()}.png',
            img.encodePng(await renderLauncher(1024, markScale: scale)),
          );
        }
        write(
          '$previews/adaptive-foreground.png',
          img.encodePng(
            await renderLauncher(
              1080,
              markScale: androidVisibleMarkScale,
              viewportFraction: 72 / 108,
              opaque: false,
            ),
          ),
        );
      }
    },
  );
}
