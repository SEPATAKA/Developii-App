import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

List<InvestorTransaction> investorTransactionFixtures(EntityType entity) {
  final card = InvestorPaymentMethod(
    id: '${entity.name}-visa',
    kind: PaymentMethodKind.card,
    name: 'Visa',
    lastFour: '2526',
    holder: 'Babatunde Yusuf',
    expiry: '09/27',
  );
  final bank = InvestorPaymentMethod(
    id: '${entity.name}-bank',
    kind: PaymentMethodKind.bankAccount,
    name: 'Access Bank',
    lastFour: '0119',
    holder: 'Babatunde Yusuf',
  );
  const bankTransfer = InvestorPaymentMethod(
    id: 'historical-bank-transfer',
    kind: PaymentMethodKind.bankAccount,
    name: 'Zenith bank',
    lastFour: '7890',
    holder: 'Babatunde Yusuf',
  );
  return [
    InvestorTransaction(
      id: '${entity.name}-investment-payment',
      title: 'Marula Heights',
      kind: InvestorTransactionKind.investment,
      status: InvestorTransactionStatus.successful,
      amount: const MonetaryAmount(-102500, Currency.zar),
      fee: const MonetaryAmount(0, Currency.zar),
      createdAt: DateTime.utc(2026, 7, 8, 22, 24),
      reference: 'INV-MH-381KJ-2982',
      projectId: 'marula-heights',
      description: 'Investment',
      projectTerms: InvestorTransactionProject(
        name: 'Marula Heights',
        distributionPayout: const MonetaryAmount(
          102500,
          Currency.zar,
        ).basisPoints(1450, denominator: 4),
        durationMonths: 18,
      ),
    ),
    InvestorTransaction(
      id: '${entity.name}-topup-0',
      title: 'Wallet Top - Up',
      kind: InvestorTransactionKind.topUp,
      status: InvestorTransactionStatus.successful,
      amount: const MonetaryAmount(1002500, Currency.zar),
      fee: const MonetaryAmount(0, Currency.zar),
      createdAt: DateTime.utc(2026, 7, 8, 22, 24),
      reference: 'DFY-TOPUP-0',
      methodId: card.id,
      paymentMethod: card,
    ),
    InvestorTransaction(
      id: '${entity.name}-distribution-marula',
      title: 'Marula Heights',
      kind: InvestorTransactionKind.distribution,
      status: InvestorTransactionStatus.successful,
      amount: const MonetaryAmount(302500, Currency.zar),
      fee: const MonetaryAmount(0, Currency.zar),
      createdAt: DateTime.utc(2026, 7, 7, 22, 24),
      reference: 'DIST-MH-381KJ-2982',
      projectId: 'marula-heights',
      projectTerms: const InvestorTransactionProject(
        name: 'Marula Heights',
        distributionPayout: MonetaryAmount(302500, Currency.zar),
        durationMonths: 18,
      ),
    ),
    InvestorTransaction(
      id: '${entity.name}-withdrawal',
      title: 'Withdrawal',
      kind: InvestorTransactionKind.withdrawal,
      status: InvestorTransactionStatus.successful,
      amount: const MonetaryAmount(-102500, Currency.zar),
      fee: const MonetaryAmount(0, Currency.zar),
      createdAt: DateTime.utc(2026, 7, 6, 22, 24),
      reference: 'DFY-WITHDRAWAL-1',
      methodId: bank.id,
      paymentMethod: bank,
      paymentMethodIsDestination: true,
    ),
    InvestorTransaction(
      id: '${entity.name}-distribution-saffron',
      title: 'Saffron Towers',
      kind: InvestorTransactionKind.distribution,
      status: InvestorTransactionStatus.successful,
      amount: const MonetaryAmount(1002500, Currency.zar),
      fee: const MonetaryAmount(0, Currency.zar),
      createdAt: DateTime.utc(2026, 7, 6, 22, 24),
      reference: 'DIST-ST-381KJ-2982',
      projectId: 'saffron-towers',
      projectTerms: const InvestorTransactionProject(
        name: 'Saffron Towers',
        distributionPayout: MonetaryAmount(1002500, Currency.zar),
        durationMonths: 18,
      ),
    ),
    InvestorTransaction(
      id: '${entity.name}-topup-1',
      title: 'Wallet Top - Up',
      kind: InvestorTransactionKind.topUp,
      status: InvestorTransactionStatus.successful,
      amount: const MonetaryAmount(100000, Currency.zar),
      fee: const MonetaryAmount(0, Currency.zar),
      createdAt: DateTime.utc(2026, 7, 5, 10, 24),
      reference: 'DFY-TOPUP-1',
      paymentMethod: bankTransfer,
      description: 'Investment Funds',
    ),
  ];
}
