import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/investor_project.dart';
import 'package:developify_mobile/features/investor/domain/portfolio_analytics.dart';

void main() {
  InvestorInvestment investment(
    String id,
    int cents, {
    Currency currency = Currency.zar,
    InvestorInvestmentStatus status = InvestorInvestmentStatus.active,
    ProjectCategory category = ProjectCategory.residential,
    DateTime? createdAt,
    int durationMonths = 18,
  }) => InvestorInvestment(
    id: id,
    projectId: id,
    projectName: id,
    location: 'Capetown, South Africa',
    amount: MonetaryAmount(cents, currency),
    earned: MonetaryAmount(cents ~/ 10, currency),
    projectedPayout: MonetaryAmount(cents + cents ~/ 5, currency),
    createdAt: createdAt ?? DateTime.utc(2026, 6, 1),
    durationMonths: durationMonths,
    status: status,
    progressBasisPoints: 6500,
    imageAsset: '',
    category: category,
  );
  InvestorAccountSnapshot snapshot(List<InvestorInvestment> investments) =>
      InvestorAccountSnapshot(
        balances: const {},
        investments: investments,
        transactions: const [],
        notifications: const [],
        paymentMethods: const [],
        verification: VerificationStatus.verified,
        asOf: DateTime.utc(2026, 7, 1),
      );

  test(
    'Analytics separates currencies and released capital from active allocation',
    () {
      final data = PortfolioAnalytics.from(
        snapshot([
          investment('active', 10000),
          investment(
            'hospitality',
            30000,
            category: ProjectCategory.hospitality,
          ),
          investment(
            'completed',
            50000,
            status: InvestorInvestmentStatus.completed,
          ),
          investment('unsupported-usd', 99999999, currency: Currency.usd),
        ]),
        PortfolioPeriod.year,
      );
      expect(data.invested.minorUnits, 90000);
      expect(data.capital.minorUnits, 40000);
      expect(data.projected.minorUnits, 108000);
      expect(data.earned.minorUnits, 9000);
      expect(data.roiBasisPoints, 2000);
      expect(data.allocations.map((item) => item.basisPoints), [2500, 7500]);
      expect(
        data.allocations.every((item) => item.amount.currency == Currency.zar),
        true,
      );
    },
  );

  test('Periods cover their stated ranges and zero history remains finite', () {
    final source = snapshot([]);
    for (final period in PortfolioPeriod.values) {
      final data = PortfolioAnalytics.from(source, period);
      expect(data.points.length, 7);
      expect(data.points.every((point) => point.amount.minorUnits == 0), true);
      expect(data.roiBasisPoints, 0);
      expect(data.allocations, isEmpty);
      final range = data.points.last.date.difference(data.points.first.date);
      expect(range, switch (period) {
        PortfolioPeriod.year => const Duration(days: 365),
        PortfolioPeriod.month => const Duration(days: 30),
        PortfolioPeriod.week => const Duration(days: 6),
        PortfolioPeriod.day => const Duration(hours: 24),
      });
    }
  });

  test('Investment maturity preserves month-end, time and timezone', () {
    for (final (start, expected) in [
      (
        DateTime.utc(2024, 1, 31, 12, 34, 56),
        DateTime.utc(2024, 2, 29, 12, 34, 56),
      ),
      (DateTime.utc(2025, 1, 31), DateTime.utc(2025, 2, 28)),
      (DateTime(2026, 12, 31, 12, 34), DateTime(2027, 1, 31, 12, 34)),
    ]) {
      final holding = investment(
        'maturity',
        10000,
        createdAt: start,
        durationMonths: 1,
      );
      expect(holding.maturityAt, expected);
      expect(holding.maturityAt.isUtc, start.isUtc);
    }
  });
}
