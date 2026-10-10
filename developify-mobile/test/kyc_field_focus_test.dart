import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_fields.dart';

void main() {
  testWidgets(
    'KYC preserves the latest amount when focus leaves before rebuild',
    (tester) async {
      final value = ValueNotifier('');
      addTearDown(value.dispose);
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(393, 852),
          builder: (context, child) => MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: ValueListenableBuilder(
                valueListenable: value,
                builder: (context, amount, child) => KycField(
                  definition: const KycFieldDefinition(
                    'income',
                    'Annual income',
                    kind: KycFieldKind.amount,
                  ),
                  value: amount,
                  onChanged: (amount) => value.value = amount,
                ),
              ),
            ),
          ),
        ),
      );
      final field = find.byType(TextFormField);
      await tester.showKeyboard(field);
      tester.testTextInput.enterText('600000');
      FocusManager.instance.primaryFocus!.unfocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
      final controller = tester.widget<TextFormField>(field).controller!;
      expect(value.value, '600000');
      expect(controller.text, 'R 600,000');
      await tester.pump();
      expect(controller.text, 'R 600,000');
      value.value = '1500.25';
      await tester.pump();
      expect(controller.text, 'R 1,500.25');
      await tester.tap(field);
      await tester.pump();
      expect(controller.text, '1500.25');
      expect(tester.takeException(), isNull);
    },
  );
}
