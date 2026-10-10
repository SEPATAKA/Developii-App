import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/utils/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Prorated returns preserve fractional basis points and round signed cents once',
    () {
      const amount = MonetaryAmount(100000, Currency.usd);
      expect(
        amount.basisPoints(1450, denominator: 4),
        const MonetaryAmount(3625, Currency.usd),
      );
      expect(
        amount.basisPoints(1450, numerator: 18, denominator: 12),
        const MonetaryAmount(21750, Currency.usd),
      );
      expect(
        const MonetaryAmount(50, Currency.usd).basisPoints(-100),
        const MonetaryAmount(-1, Currency.usd),
      );
      expect(
        const MonetaryAmount(-50, Currency.usd).basisPoints(100),
        const MonetaryAmount(-1, Currency.usd),
      );
      expect(
        const MonetaryAmount(50, Currency.usd).basisPoints(100),
        const MonetaryAmount(1, Currency.usd),
      );
    },
  );

  test(
    'Rate calculation protects large intermediate values and rejects invalid divisors',
    () {
      const amount = MonetaryAmount(100000000000000, Currency.zar);
      expect(
        amount.basisPoints(20000, numerator: 120, denominator: 12),
        const MonetaryAmount(2000000000000000, Currency.zar),
      );
      expect(
        () => amount.basisPoints(100, denominator: 0),
        throwsArgumentError,
      );
      expect(
        () => amount.basisPoints(1000000000, numerator: 1000000),
        throwsRangeError,
      );
    },
  );
  test('Amount entry retains exact cents and rejects ambiguous input', () {
    expect(
      MonetaryAmount.tryParse('10182.01', Currency.usd),
      const MonetaryAmount(1018201, Currency.usd),
    );
    expect(
      MonetaryAmount.tryParse('50.', Currency.zar),
      const MonetaryAmount(5000, Currency.zar),
    );
    for (final value in ['', '-1', 'NaN', '1e6', '1.001', '1,000', '1.2.3']) {
      expect(MonetaryAmount.tryParse(value, Currency.usd), isNull);
    }
  });

  test('Financial arithmetic cannot mix currencies', () {
    const dollars = MonetaryAmount(10000, Currency.usd);
    const rand = MonetaryAmount(10000, Currency.zar);
    expect(() => dollars + rand, throwsArgumentError);
    expect(() => dollars - rand, throwsArgumentError);
    expect(() => dollars.compareTo(rand), throwsArgumentError);
    expect(
      dollars + const MonetaryAmount(50, Currency.usd),
      const MonetaryAmount(10050, Currency.usd),
    );
    expect(dollars.basisPoints(150), const MonetaryAmount(150, Currency.usd));
  });

  test('Currency formatting preserves symbols, cents, locale and signs', () {
    expect(
      Money.amount(const MonetaryAmount(1018201, Currency.usd)),
      r'$10,182.01',
    );
    expect(
      Money.amount(const MonetaryAmount(-102500, Currency.zar)),
      '-R1,025.00',
    );
    expect(
      Money.amount(
        const MonetaryAmount(1018201, Currency.zar),
        locale: 'af_ZA',
      ),
      'R10 182,01',
    );
    expect(Money.rand(1018201), 'R 10,182.01');
    expect(
      Money.compact(const MonetaryAmount(240000000, Currency.usd)),
      r'$2.4M',
    );
    expect(
      Money.compact(
        const MonetaryAmount(156000000, Currency.usd),
        fractionDigits: 2,
      ),
      r'$1.56M',
    );
    expect(
      Money.compact(
        const MonetaryAmount(-150000000, Currency.zar),
        fractionDigits: 2,
      ),
      '-R1.5M',
    );
    expect(Money.compact(const MonetaryAmount(5000, Currency.usd)), r'$50');
  });
}
