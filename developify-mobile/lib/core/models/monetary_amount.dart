enum Currency {
  zar('ZAR', 'R'),
  usd('USD', r'$');

  const Currency(this.code, this.symbol);
  final String code;
  final String symbol;

  static Currency? tryParse(String? value) {
    for (final currency in values) {
      if (currency.code == value?.toUpperCase()) return currency;
    }
    return null;
  }
}

final class MonetaryAmount {
  const MonetaryAmount(this.minorUnits, this.currency);

  /// Exact minor units (cents for ZAR); never decode ledger values via double.
  final int minorUnits;
  final Currency currency;

  static MonetaryAmount? tryParse(String input, Currency currency) {
    final text = input.trim();
    if (!RegExp(r'^\d{1,12}(?:\.\d{0,2})?$').hasMatch(text)) return null;
    final parts = text.split('.');
    final whole = int.tryParse(parts.first);
    if (whole == null) return null;
    final fraction = parts.length == 1
        ? 0
        : int.parse(parts[1].padRight(2, '0'));
    return MonetaryAmount(whole * 100 + fraction, currency);
  }

  MonetaryAmount operator +(MonetaryAmount other) {
    _requireCurrency(other);
    return MonetaryAmount(minorUnits + other.minorUnits, currency);
  }

  MonetaryAmount operator -(MonetaryAmount other) {
    _requireCurrency(other);
    return MonetaryAmount(minorUnits - other.minorUnits, currency);
  }

  int compareTo(MonetaryAmount other) {
    _requireCurrency(other);
    return minorUnits.compareTo(other.minorUnits);
  }

  MonetaryAmount basisPoints(
    int points, {
    int numerator = 1,
    int denominator = 1,
  }) {
    if (denominator <= 0) {
      throw ArgumentError.value(
        denominator,
        'denominator',
        'Must be positive.',
      );
    }
    final product =
        BigInt.from(minorUnits) * BigInt.from(points) * BigInt.from(numerator);
    final divisor = BigInt.from(10000) * BigInt.from(denominator);
    final rounded =
        (product.abs() + divisor ~/ BigInt.two) ~/
        divisor *
        BigInt.from(product.sign);
    final result = rounded.toInt();
    if (BigInt.from(result) != rounded) {
      throw RangeError('The calculated amount exceeds the supported range.');
    }
    return MonetaryAmount(result, currency);
  }

  void _requireCurrency(MonetaryAmount other) {
    if (currency != other.currency) {
      throw ArgumentError('Amounts must use the same currency.');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is MonetaryAmount &&
      minorUnits == other.minorUnits &&
      currency == other.currency;

  @override
  int get hashCode => Object.hash(minorUnits, currency);
}
