import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/investment_policy.dart';

final class InvestorAccountSummary {
  // Count available wallet funds plus distinct principal still held.
  // Projected proceeds are neither available funds nor additional capital.
  InvestorAccountSummary.from(InvestorAccountSnapshot snapshot) {
    available = snapshot.balance(InvestmentPolicy.currency);
    final ids = <String>{};
    investedCapital = MonetaryAmount(
      snapshot.investments
          .where(
            (holding) =>
                holding.amount.currency == InvestmentPolicy.currency &&
                holding.holdsPrincipal &&
                ids.add(holding.id),
          )
          .fold(0, (total, holding) => total + holding.amount.minorUnits),
      InvestmentPolicy.currency,
    );
  }
  late final MonetaryAmount available;
  late final MonetaryAmount investedCapital;
  MonetaryAmount get overallBalance => available + investedCapital;
}
