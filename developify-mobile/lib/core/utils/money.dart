import 'package:developify_mobile/core/models/monetary_amount.dart';

abstract final class Money {
  static String compact(
    MonetaryAmount value, {
    bool lowercaseSuffix = false,
    int fractionDigits = 1,
  }) {
    RangeError.checkValueInInterval(fractionDigits, 0, 2, 'fractionDigits');
    final major = value.minorUnits / 100;
    if (major.abs() < 1000) return amount(value, decimals: false);
    final million = major.abs() >= 1000000;
    var number = (major.abs() / (million ? 1000000 : 1000)).toStringAsFixed(
      fractionDigits,
    );
    if (number.contains('.')) {
      number = number
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
    }
    final suffix = million ? 'M' : 'K';
    return '${major < 0 ? '-' : ''}${value.currency.symbol}$number${lowercaseSuffix ? suffix.toLowerCase() : suffix}';
  }

  static String amount(
    MonetaryAmount value, {
    bool decimals = true,
    bool showPositiveSign = false,
    String locale = 'en_ZA',
    bool spaceAfterSymbol = false,
  }) {
    final commaDecimal = locale.startsWith('af');
    final grouping = commaDecimal ? ' ' : ',';
    final separator = commaDecimal ? ',' : '.';
    final absolute = value.minorUnits.abs();
    final whole = (absolute ~/ 100).toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}$grouping',
    );
    final fraction = decimals
        ? '$separator${(absolute % 100).toString().padLeft(2, '0')}'
        : '';
    final sign = value.minorUnits < 0
        ? '-'
        : showPositiveSign && value.minorUnits > 0
        ? '+'
        : '';
    return '$sign${value.currency.symbol}${spaceAfterSymbol ? ' ' : ''}$whole$fraction';
  }

  static String rand(int cents, {bool decimals = true}) {
    final absolute = cents.abs();
    final whole = (absolute ~/ 100).toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    final fraction = decimals
        ? '.${(absolute % 100).toString().padLeft(2, '0')}'
        : '';
    return '${cents < 0 ? '-' : ''}R $whole$fraction';
  }
}
