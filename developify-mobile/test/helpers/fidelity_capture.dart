import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';

Future<void> captureFidelity(
  WidgetTester tester,
  GlobalKey key,
  String name, {
  String directory = 'build/test-artifacts/screenshots',
  Finder? target,
}) async {
  if (!const bool.fromEnvironment('CAPTURE_FIDELITY')) return;
  const outputRoot = String.fromEnvironment('FIDELITY_OUTPUT');
  if (outputRoot.isNotEmpty) directory = outputRoot;
  final captureContext = target == null
      ? key.currentContext!
      : tester.element(target);
  await tester.runAsync(() async {
    await Future.wait([
      for (final asset in AppAssets.rasterImages)
        precacheImage(AssetImage(asset), captureContext),
      for (final widget in tester.widgetList<Image>(find.byType(Image)))
        precacheImage(widget.image, captureContext),
    ]);
  });
  await tester.pump();
  final boundary = captureContext.findRenderObject()! as RenderRepaintBoundary;
  final previous = debugDisableShadows;
  debugDisableShadows = false;
  void repaint(RenderObject object) {
    object.markNeedsPaint();
    object.visitChildren(repaint);
  }

  repaint(boundary);
  await tester.pump();
  try {
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$directory/$name.png');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  } finally {
    debugDisableShadows = previous;
    repaint(boundary);
    await tester.pump();
  }
}
