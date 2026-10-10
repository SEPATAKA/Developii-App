import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers/fonts.dart';
import 'helpers/client_review_journey.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  registerClientReviewJourney(surfaceSize: const Size(393, 852));
}
