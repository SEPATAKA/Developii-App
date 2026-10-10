import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/features/investor/domain/investor_repository.dart';

Future<void> prepareInvestorExploreFrame(
  AppDependencies dependencies,
  String node,
) async {
  if (node == '84794') {
    for (final id in [
      'saffron-towers',
      'saffron-hospitality',
      'coastline-villas',
    ]) {
      await dependencies.container<InvestorCatalogRepository>().setFavourite(
        id,
        true,
      );
    }
  }
}

Future<void> showInvestorExploreFrame(WidgetTester tester, String node) async {
  if (node == '74436') {
    await tester.tap(find.byKey(const ValueKey('field-')));
    tester.view.viewInsets = const FakeViewPadding(bottom: 291);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
  }
  if (node == '75054') {
    await tester.enterText(
      find.byKey(const ValueKey('investor-amount')),
      '26000',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }
}
