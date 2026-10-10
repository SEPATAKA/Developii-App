import 'package:flutter/services.dart';

class AuthenticatorCodeFormatter extends TextInputFormatter {
  const AuthenticatorCodeFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 6 ? digits.substring(0, 6) : digits;
    final text = limited.length > 3
        ? '${limited.substring(0, 3)} ${limited.substring(3)}'
        : limited;
    final before = newValue.text
        .substring(
          0,
          newValue.selection.extentOffset.clamp(0, newValue.text.length),
        )
        .replaceAll(RegExp(r'\D'), '')
        .length;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: (before + (before > 3 ? 1 : 0)).clamp(0, text.length),
      ),
    );
  }
}
