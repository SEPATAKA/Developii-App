import 'package:flutter/services.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';

Future<void> loadAppFonts() async {
  final loader = FontLoader(AppTextStyles.fontFamily);
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    loader.addFont(
      rootBundle.load('assets/fonts/TASAOrbiterDisplay-$weight.otf'),
    );
  }
  await loader.load();
}
