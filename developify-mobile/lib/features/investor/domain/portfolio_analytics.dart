import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/investor_project.dart';

enum PortfolioPeriod { year, month, week, day }

final class PortfolioPoint {
  const PortfolioPoint(this.date, this.label, this.amount);
  final DateTime date;
  final String label;
  final MonetaryAmount amount;
}

final class PortfolioAllocation {
  const PortfolioAllocation(this.category, this.amount, this.basisPoints);
  final ProjectCategory category;
  final MonetaryAmount amount;
  final int basisPoints;
}

final class PortfolioAnalytics {
  PortfolioAnalytics.from(
    InvestorAccountSnapshot snapshot,
    PortfolioPeriod period, {
    Currency currency = Currency.zar,
  }) {
    final ids = <String>{};
    final investments = snapshot.investments
        .where((item) => item.amount.currency == currency && ids.add(item.id))
        .toList();
    final active = investments.where((item) => item.holdsPrincipal).toList();
    MonetaryAmount sum(
      Iterable<InvestorInvestment> items,
      MonetaryAmount Function(InvestorInvestment) select,
    ) => MonetaryAmount(
      items.fold(0, (sum, item) => sum + select(item).minorUnits),
      currency,
    );
    invested = sum(investments, (item) => item.amount);
    capital = sum(active, (item) => item.amount);
    earned = sum(investments, (item) => item.earned);
    projected = sum(investments, (item) => item.projectedPayout);
    projectedReturns = sum(
      active,
      (item) => item.projectedPayout - item.amount,
    );
    roiBasisPoints = invested.minorUnits == 0
        ? 0
        : ((projected.minorUnits - invested.minorUnits) *
                  10000 /
                  invested.minorUnits)
              .round();
    final grouped = <ProjectCategory, int>{};
    for (final item in active) {
      grouped.update(
        item.category,
        (amount) => amount + item.amount.minorUnits,
        ifAbsent: () => item.amount.minorUnits,
      );
    }
    allocations = List.unmodifiable(
      grouped.entries.map(
        (entry) => PortfolioAllocation(
          entry.key,
          MonetaryAmount(entry.value, currency),
          capital.minorUnits == 0
              ? 0
              : (entry.value * 10000 / capital.minorUnits).round(),
        ),
      ),
    );
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'June',
      'July',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final end = snapshot.asOf;
    points = List.unmodifiable(
      List.generate(7, (index) {
        final date = switch (period) {
          PortfolioPeriod.year => DateTime.utc(
            end.year,
            end.month - 12 + index * 2 + 1,
          ).subtract(const Duration(microseconds: 1)),
          PortfolioPeriod.month => end.subtract(
            Duration(days: (6 - index) * 5),
          ),
          PortfolioPeriod.week => end.subtract(Duration(days: 6 - index)),
          PortfolioPeriod.day => end.subtract(Duration(hours: (6 - index) * 4)),
        };
        final label = switch (period) {
          PortfolioPeriod.year => months[date.month - 1],
          PortfolioPeriod.month => '${date.day} ${months[date.month - 1]}',
          PortfolioPeriod.week => days[date.weekday - 1],
          PortfolioPeriod.day => '${date.hour.toString().padLeft(2, '0')}:00',
        };
        final held = investments.where((item) {
          if (item.createdAt.isAfter(date)) return false;
          if (item.holdsPrincipal) return true;
          final maturity = DateTime.utc(
            item.createdAt.year,
            item.createdAt.month + item.durationMonths,
            item.createdAt.day,
          );
          return date.isBefore(maturity);
        });
        return PortfolioPoint(date, label, sum(held, (item) => item.amount));
      }),
    );
  }

  late final MonetaryAmount invested;
  late final MonetaryAmount capital;
  late final MonetaryAmount earned;
  late final MonetaryAmount projected;
  late final MonetaryAmount projectedReturns;
  late final int roiBasisPoints;
  late final List<PortfolioAllocation> allocations;
  late final List<PortfolioPoint> points;
}
