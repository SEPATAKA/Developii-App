import 'package:developify_mobile/core/models/monetary_amount.dart';

abstract final class InvestorTransferFees {
  static const withdrawal = MonetaryAmount(150, Currency.zar);

  static MonetaryAmount cardTopUp(MonetaryAmount amount) =>
      amount.basisPoints(150);
}
