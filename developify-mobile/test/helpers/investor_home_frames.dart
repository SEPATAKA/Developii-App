import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/investor_account_context.dart';
import 'package:developify_mobile/features/investor/domain/investor_repository.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

const investorHomeFrameOffsets = {
  '42043': 646.0,
  '42496': 646.0,
  '43648': 646.0,
  '44088': 443.0,
  '44531': 646.0,
  '44971': 443.0,
  '61367': 646.0,
  '61807': 646.0,
  '62247': 646.0,
  '71909': 646.0,
  '72937': 646.0,
};

Future<void> prepareInvestorHomeFrame(
  AppDependencies dependencies,
  String node,
) async {
  if (node == '54472') {
    dependencies.container<InvestorAccountContext>().selectEntity(
      EntityType.trust,
    );
  }
  if (node == '42829' || node == '43201') {
    dependencies.container<InvestorAccountRepository>().setVerification(
      VerificationStatus.pending,
    );
  }
  if (const {
    '41145',
    '41594',
    '42829',
    '43201',
    '43648',
    '45456',
    '45828',
    '54472',
  }.contains(node)) {
    await dependencies.container<InvestorCatalogRepository>().setFavourite(
      'marula-heights',
      true,
    );
  }
}

Future<void> showInvestorHomeFrame(WidgetTester tester, String node) async {
  final target = investorHomeFrameOffsets[node];
  if (target != null) {
    final scrollable = find
        .descendant(
          of: find.byKey(const PageStorageKey('investor-home-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;
    final state = tester.state<ScrollableState>(scrollable);
    final heading = find.text('Recently active');
    await tester.scrollUntilVisible(heading, 150, scrollable: scrollable);
    await tester.pumpAndSettle();
    state.position.jumpTo(
      (state.position.pixels + tester.getTopLeft(heading).dy - target).clamp(
        0,
        state.position.maxScrollExtent,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(heading).dy, closeTo(target, 0.01));
  }
  if (node == '42496') {
    expect(find.text('Try the investment calculator'), findsOneWidget);
    expect(find.text('Unlock Your Investment Potential'), findsNothing);
  }
  if (node == '44971') {
    await tester.tap(find.bySemanticsLabel('Switch experience'));
    await tester.pumpAndSettle();
    expect(find.text('Switch'), findsOneWidget);
  }
}
