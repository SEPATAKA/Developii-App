import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/features/authentication/presentation/recovery_screen.dart';

Future<void> showInvestorAuthFrame(WidgetTester tester, String node) async {
  Future<void> enter(String label, String value) async {
    final finder = find.byKey(ValueKey('field-$label'));
    await tester.ensureVisible(finder);
    await tester.enterText(finder, value);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  Future<void> next() async {
    final finder = find.widgetWithText(AppButton, 'Continue');
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
    if (find
        .text('Demo recovery: use 123456. No email is sent.')
        .evaluate()
        .isNotEmpty) {
      await tester.tap(find.widgetWithText(TextButton, 'Dismiss'));
      await tester.pumpAndSettle();
    }
  }

  Future<void> code(String value) async {
    await tester.enterText(
      find.descendant(
        of: find.byType(CodeField),
        matching: find.byType(TextField),
      ),
      value,
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  if (node == '40719' || node == '41099') {
    if (node == '41099') await enter('Email Address', 'Thomashook@gmail.com');
    await enter('Password', 'Winner2026\$\$\$');
    await tester.tap(find.byTooltip('Show password'));
    await tester.pumpAndSettle();
    return;
  }
  if (!const {
    '40110',
    '40274',
    '40312',
    '40350',
    '40398',
    '40446',
    '40494',
    '40558',
    '40606',
  }.contains(node)) {
    return;
  }
  await enter('Email Address', 'Thomashook@gmail.com');
  if (node == '40110') {
    tester.view.viewInsets = const FakeViewPadding(bottom: 304);
    tester.view.padding = const FakeViewPadding(top: 56);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.view.resetPadding);
    await tester.showKeyboard(
      find.byKey(const ValueKey('field-Email Address')),
    );
    await tester.pumpAndSettle();
    return;
  }
  await next();
  if (node == '40274') return;
  if (node == '40312' || node == '40606') {
    await code('000000');
    if (node == '40606') await next();
    return;
  }
  await code('123456');
  await next();
  if (node == '40350') return;
  await enter('Password', 'Winner2026\$\$\$');
  await enter(
    'Confirm new Password',
    node == '40558' ? 'Winner2026\$\$' : 'Winner2026\$\$\$',
  );
  await tester.tap(find.byTooltip('Show password').first);
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Show password').last);
  await tester.pumpAndSettle();
  if (node == '40494') await next();
}
