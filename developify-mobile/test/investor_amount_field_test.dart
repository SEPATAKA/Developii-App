import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_amount_field.dart';

void main() {
  testWidgets(
    'An amount keeps the latest edit when focus changes before its parent rebuilds',
    (tester) async {
      final value = ValueNotifier('0');
      addTearDown(value.dispose);
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(393, 852),
          builder: (context, child) => MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: ValueListenableBuilder(
                valueListenable: value,
                builder: (context, amount, child) => InvestorAmountField(
                  value: amount,
                  onChanged: (amount) => value.value = amount,
                ),
              ),
            ),
          ),
        ),
      );
      final field = find.byKey(const ValueKey('investor-amount'));
      await tester.showKeyboard(field);
      tester.testTextInput.enterText('20000');
      expect(value.value, '20000');
      FocusManager.instance.primaryFocus!.unfocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
      final controller = tester.widget<TextField>(field).controller!;
      expect(controller.text, '20000.00');
      await tester.pump();
      expect(controller.text, '20000.00');
      value.value = '1500.25';
      await tester.pump();
      expect(controller.text, '1500.25');
      await tester.tap(field);
      await tester.pump();
      expect(controller.text, '1500.25');
      await tester.enterText(field, '20000');
      FocusManager.instance.primaryFocus!.unfocus();
      await tester.pumpAndSettle();
      expect(value.value, '20000');
      expect(controller.text, '20000.00');
      expect(tester.takeException(), isNull);
    },
  );
}
