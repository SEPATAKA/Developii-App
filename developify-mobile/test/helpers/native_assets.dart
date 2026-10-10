import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> settleNativeImages(
  WidgetTester tester, {
  bool settleAnimations = true,
}) async {
  final images = tester.elementList(find.byType(Image)).toList();
  await tester.runAsync(() async {
    await Future.wait([
      for (final element in images)
        precacheImage((element.widget as Image).image, element),
    ]);
  });
  if (settleAnimations) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}
