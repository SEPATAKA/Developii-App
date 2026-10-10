import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/utils/money.dart';

abstract final class InvestmentPolicy {
  static const currency = Currency.zar;
  static const minimumMinorUnits = 100;
  static const minimum = MonetaryAmount(minimumMinorUnits, currency);
  static const minimumMajorUnits = minimumMinorUnits ~/ 100;
  static const minimumLabel = 'R$minimumMajorUnits.00';
  static const payoutEveryMonths = 1;
  static const termMonths = 36;
  static const calculatorDisclaimer =
      'This assumes a fixed annual rate, without compounding, and rounds monetary results to cents. Fees and taxes are not deducted.';
}

final class InvestmentProjection {
  InvestmentProjection({
    required this.principal,
    required this.annualRateBasisPoints,
    required this.termMonths,
    this.payoutEveryMonths = 3,
  }) {
    if (principal.minorUnits < 0 ||
        annualRateBasisPoints < 0 ||
        termMonths <= 0 ||
        payoutEveryMonths <= 0 ||
        termMonths % payoutEveryMonths != 0) {
      throw ArgumentError('This projection schedule is not supported.');
    }
  }

  final MonetaryAmount principal;
  final int annualRateBasisPoints;
  final int termMonths;
  final int payoutEveryMonths;
  int get distributionCount => termMonths ~/ payoutEveryMonths;
  MonetaryAmount get earnings => principal.basisPoints(
    annualRateBasisPoints,
    numerator: termMonths,
    denominator: 12,
  );
  MonetaryAmount get payout => principal + earnings;
  List<MonetaryAmount> get payments => distribute(earnings, distributionCount);
  String get paymentRangeLabel {
    final schedule = payments;
    return schedule.first == schedule.last
        ? Money.amount(schedule.first)
        : '${Money.amount(schedule.last)}–${Money.amount(schedule.first)}';
  }

  bool matches(InvestmentProjection other) =>
      principal == other.principal &&
      annualRateBasisPoints == other.annualRateBasisPoints &&
      termMonths == other.termMonths &&
      payoutEveryMonths == other.payoutEveryMonths;

  // Allocate residual cents after rounding total earnings once, so schedule
  // payments sum exactly to earnings for monthly and historical cadences.
  static List<MonetaryAmount> distribute(MonetaryAmount earnings, int count) {
    if (earnings.minorUnits < 0 || count <= 0) {
      throw ArgumentError('This distribution schedule is not supported.');
    }
    final total = earnings.minorUnits;
    final base = total ~/ count;
    final remainder = total % count;
    return List.unmodifiable(
      List.generate(
        count,
        (index) => MonetaryAmount(
          base + (index < remainder ? 1 : 0),
          earnings.currency,
        ),
      ),
    );
  }
}
