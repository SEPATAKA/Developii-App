import 'dart:io';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Every declared SVG parses with the production Flutter loader',
    () async {
      final source = File('lib/core/assets/app_assets.dart').readAsStringSync();
      final assets = RegExp(
        r"'(assets/[^']+\.svg)'",
      ).allMatches(source).map((match) => match.group(1)!).toSet();
      expect(assets, isNotEmpty);
      for (final asset in assets) {
        final bytes = await SvgAssetLoader(asset).loadBytes(null);
        expect(bytes.lengthInBytes, greaterThan(0), reason: asset);
      }
    },
  );

  test(
    'MobX stores never depend on another store or presentation infrastructure',
    () {
      final stores = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('_store.dart'))
          .toList();
      expect(stores.length, greaterThanOrEqualTo(15));
      final storeNames = stores
          .map((file) => file.uri.pathSegments.last)
          .toSet();
      for (final file in stores) {
        final source = file.readAsStringSync();
        for (final import in RegExp(
          r'''(?:import|export)\s+['"]([^'"]+)['"]''',
        ).allMatches(source)) {
          expect(
            storeNames.contains(import.group(1)!.split('/').last),
            false,
            reason: '${file.path} imports ${import.group(1)}',
          );
        }
        expect(
          RegExp(
            r'\b(GetIt|BuildContext|GoRouter|Navigator|TextEditingController|FocusNode)\b',
          ).hasMatch(source),
          false,
          reason: '${file.path} crosses a store boundary',
        );
      }
    },
  );
  test(
    'Local assets exist, contain data, and native text uses one font family',
    () {
      final manifest = File(
        'lib/core/assets/app_assets.dart',
      ).readAsStringSync();
      for (final match in RegExp(
        r"'((?:assets/)[^']+)'\s*;",
      ).allMatches(manifest)) {
        final file = File(match.group(1)!);
        expect(file.existsSync(), true, reason: file.path);
        expect(file.lengthSync(), greaterThan(0), reason: file.path);
        if (file.path.endsWith('.svg')) {
          expect(file.readAsStringSync(), contains('<svg'));
        }
      }
      for (final file
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((file) => file.path.endsWith('.dart'))) {
        final source = file.readAsStringSync();
        expect(
          source.contains('figma.com/api/mcp/asset'),
          false,
          reason: file.path,
        );
        if (!file.path.endsWith('app_theme.dart')) {
          expect(
            RegExp(r'''fontFamily:\s*['"]''').hasMatch(source),
            false,
            reason: file.path,
          );
        }
      }
    },
  );
  test(
    'Production colours stay in tokens and Investor icons stay in approved assets',
    () {
      for (final file
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where(
                (file) =>
                    file.path.endsWith('.dart') &&
                    !file.path.endsWith('.g.dart'),
              )) {
        final source = file.readAsStringSync();
        if (!file.path.endsWith('app_theme.dart')) {
          expect(
            RegExp(r'\b(?:Color\(|Color\.from|Colors\.)').hasMatch(source),
            false,
            reason: file.path,
          );
        }
        if (file.path.contains('/investor/')) {
          expect(
            RegExp(r'\b(?:Icons\.|IconData\()').hasMatch(source),
            false,
            reason: file.path,
          );
          expect(
            source.runes.where((rune) => rune >= 0x1F300 && rune <= 0x1FAFF),
            isEmpty,
            reason: file.path,
          );
        }
      }
      final tokens = File('lib/core/theme/app_theme.dart').readAsStringSync();
      expect(RegExp(r'Color\(0x').hasMatch(tokens), false);
    },
  );
  test(
    'Navigation passes primitive parameters and owns stores at route boundaries',
    () {
      for (final file
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where(
                (file) =>
                    file.path.endsWith('.dart') &&
                    !file.path.endsWith('.g.dart'),
              )) {
        final source = file.readAsStringSync();
        if (file.path.contains('/router/') ||
            file.path.contains('/presentation/')) {
          expect(
            RegExp(r'\bextra\s*:|\bstate\.extra\b').hasMatch(source),
            false,
            reason: file.path,
          );
        }
      }
      final stores = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('_store.dart'));
      for (final file in stores) {
        expect(
          RegExp(
            r'\b(?:AnimationController|ScrollController|PageController|TabController|FocusScopeNode)\b',
          ).hasMatch(file.readAsStringSync()),
          false,
          reason: file.path,
        );
      }
    },
  );
  test('Production asset literals are registered once in AppAssets', () {
    final manifest = File('lib/core/assets/app_assets.dart').readAsStringSync();
    final pattern = RegExp(r'''['"](assets/[^'"]+)['"]''');
    final paths = pattern
        .allMatches(manifest)
        .map((match) => match.group(1)!)
        .toList();
    expect(paths.toSet().length, paths.length);
    for (final file
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))) {
      for (final match in pattern.allMatches(file.readAsStringSync())) {
        expect(paths, contains(match.group(1)), reason: file.path);
      }
    }
  });
}
