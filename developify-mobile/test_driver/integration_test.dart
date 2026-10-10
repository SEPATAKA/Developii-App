import 'dart:convert';
import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final directory = Directory(
    Platform.environment['DEVELOPIFY_TEST_OUTPUT'] ??
        'build/integration-results',
  )..createSync(recursive: true);
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      await File('${directory.path}/$name.png').writeAsBytes(bytes);
      return bytes.isNotEmpty;
    },
    writeResponseOnFailure: true,
    responseDataCallback: (data) async {
      if (data == null) return;
      final summary = Map<String, dynamic>.of(data);
      final screenshots = summary.remove('screenshots') as List<dynamic>?;
      summary['screenshotCount'] = screenshots?.length ?? 0;
      await File(
        '${directory.path}/results.json',
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(summary));
    },
  );
}
