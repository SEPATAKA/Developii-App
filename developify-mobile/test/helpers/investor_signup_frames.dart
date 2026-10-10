import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/features/authentication/presentation/recovery_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/investor_signup_screen.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investor_signup_store.dart';

Future<void> showInvestorSignupFrame(WidgetTester tester, String node) async {
  if (find.byType(InvestorSignupScreen).evaluate().isEmpty) return;
  final store = tester
      .widget<InvestorSignupScreen>(find.byType(InvestorSignupScreen))
      .store;
  Future<void> enter(String label, String value) async {
    final field = find.byKey(ValueKey('field-$label'));
    await tester.ensureVisible(field);
    await tester.enterText(field, value);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  Future<void> tap(String label) async {
    final button = find.widgetWithText(AppButton, label).last;
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    if (label == 'Create account' &&
        store.stage == InvestorSignupStage.verification) {
      await tester.tap(find.widgetWithText(TextButton, 'Dismiss'));
      await tester.pumpAndSettle();
    }
  }

  Future<void> scrollTop() async {
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    scrollable.position.jumpTo(0);
    await tester.pumpAndSettle();
  }

  if (const {'38651', '38704', '38758'}.contains(node)) return;
  if (node == '38833' || node == '38958') {
    store.addRepresentative();
    store.addRepresentative();
    if (node == '38958') {
      for (var index = 0; index < 3; index++) {
        store.updateRepresentative(
          index,
          name: 'Thomas Brood',
          identityNumber: '123732170',
        );
      }
    }
    await tester.pumpAndSettle();
    return;
  }
  final filledDetails = const {'39083', '39135', '39731'}.contains(node);
  await enter('Full Name', 'Babatunde Yusuf');
  await enter(
    'Email Address',
    filledDetails ? 'Thomashook@gmail.com' : 'bafrke@gmail.com',
  );
  await enter('Phone Number', filledDetails ? '71081280182' : '8317277127');
  await enter('Password', 'Winner2026\$\$\$');
  await enter(
    'Confirm Password',
    node == '39731' ? 'Different2026\$\$\$' : 'Winner2026\$\$\$',
  );
  if (filledDetails) {
    await tester.tap(find.byTooltip('Show password').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Show password').last);
    if (node == '39731') {
      await tap('Create account');
      expect(store.errors['confirmation'], 'Passwords do not match');
      expect(store.stage, InvestorSignupStage.details);
    }
    await scrollTop();
    return;
  }
  store.setCountry('ZA', '+27');
  await tap('Create account');
  if (node == '39187') return;
  Future<void> code(String value, {bool unfocus = true}) async {
    await tester.enterText(
      find.descendant(
        of: find.byType(CodeField),
        matching: find.byType(TextField),
      ),
      value,
    );
    if (unfocus) FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  if (node == '39330' || node == '39693') {
    await code('000000');
    if (node == '39693') await tap('Verify');
    return;
  }
  await code('123456');
  await tap('Verify');
  if (node == '39368') return;
  await tap('Continue');
  if (node == '39225') return;
  if (node == '39260') {
    await code('000', unfocus: false);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(store.error, 'Enter a four-digit PIN.');
    return;
  }
  await code('0000');
  if (node == '39295') return;
  await tap('Continue');
  if (node == '39597') return;
  await tap('Continue');
  if (node == '39643') return;
  await tester.tap(find.bySemanticsLabel('Simulate fingerprint setup'));
  await tester.pumpAndSettle();
  if (node == '39422') return;
  if (node == '39546') {
    await tap('Maybe Later');
    return;
  }
  await tap('Continue');
  if (node == '39785') return;
  store.captureFace();
  await tester.pump();
  if (node == '39469') return;
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
  expect(store.stage, InvestorSignupStage.faceComplete);
}
