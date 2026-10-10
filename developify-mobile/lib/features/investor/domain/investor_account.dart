import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/features/investor/domain/investment_policy.dart';
import 'package:developify_mobile/features/investor/domain/investor_project.dart';

enum VerificationStatus { incomplete, pending, correctionRequired, verified }

enum InvestorTransactionKind {
  investment,
  distribution,
  topUp,
  withdrawal,
  refund,
}

enum InvestorTransactionStatus { successful, pending, failed }

enum InvestorInvestmentStatus { active, completed, underfunded }

enum InvestmentMilestoneStage { planned, confirmed, foundation, matured }

enum PaymentMethodKind { card, bankAccount }

enum InvestorDestination {
  project,
  investment,
  transaction,
  verification,
  wallet,
}

enum InvestorNotificationKind {
  targetReached,
  distribution,
  newProject,
  withdrawal,
  verification,
  investment,
  topUp,
}

enum InvestorNotificationFilter { walletTopUp, investments, updates }

enum InvestorDataKind {
  privacy,
  scope,
  wallet,
  portfolio,
  transactions,
  notifications,
  methods,
  verification,
}

final class InvestorPaymentMethod {
  const InvestorPaymentMethod({
    required this.id,
    required this.kind,
    required this.name,
    required this.lastFour,
    required this.holder,
    this.expiry = '',
    this.bankType = '',
    this.branchCode = '',
    this.reusable = true,
    this.isDefault = false,
  });

  final String id;
  final PaymentMethodKind kind;
  final String name;
  final String lastFour;
  final String holder;
  final String expiry;
  final String bankType;
  final String branchCode;
  final bool reusable;
  final bool isDefault;

  InvestorPaymentMethod withDefault(bool value) => InvestorPaymentMethod(
    id: id,
    kind: kind,
    name: name,
    lastFour: lastFour,
    holder: holder,
    expiry: expiry,
    bankType: bankType,
    branchCode: branchCode,
    reusable: reusable,
    isDefault: value,
  );
}

abstract final class InvestorDepositAccount {
  static const method = InvestorPaymentMethod(
    id: 'developify-deposit',
    kind: PaymentMethodKind.bankAccount,
    name: 'Wema Bank',
    lastFour: '1902',
    holder: 'Developify Holding (Babatunde Yusuf)',
  );
  static const number = '102932821902';
  static const formattedNumber = '1029 3282 1902';
  static const reference = '1234567';
}

final class InvestorTransaction {
  const InvestorTransaction({
    required this.id,
    required this.title,
    required this.kind,
    required this.status,
    required this.amount,
    required this.fee,
    required this.createdAt,
    required this.reference,
    this.description = '',
    this.projectId,
    this.methodId,
    this.paymentMethod,
    this.paymentMethodIsDestination = false,
    this.projectTerms,
  });

  final String id;
  final String title;
  final InvestorTransactionKind kind;
  final InvestorTransactionStatus status;
  final MonetaryAmount amount;
  final MonetaryAmount fee;
  final DateTime createdAt;
  final String reference;
  final String description;
  final String? projectId;
  final String? methodId;
  final InvestorPaymentMethod? paymentMethod;
  final bool paymentMethodIsDestination;
  final InvestorTransactionProject? projectTerms;
}

final class InvestorTransactionProject {
  const InvestorTransactionProject({
    required this.name,
    required this.distributionPayout,
    this.payoutEveryMonths = 3,
    this.projection,
    required this.durationMonths,
  });

  final String name;
  final MonetaryAmount distributionPayout;
  final int payoutEveryMonths;
  final InvestmentProjection? projection;
  final int durationMonths;
}

final class InvestorInvestment {
  const InvestorInvestment({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.location,
    required this.amount,
    required this.earned,
    required this.projectedPayout,
    required this.createdAt,
    required this.status,
    required this.progressBasisPoints,
    required this.imageAsset,
    this.category = ProjectCategory.residential,
    this.durationMonths = 18,
    this.thumbnailAsset,
    this.recordedMilestone = InvestmentMilestoneStage.planned,
    this.principalReturned = false,
    this.payoutEveryMonths = 3,
    this.annualRateBasisPoints,
  });

  final String id;
  final String projectId;
  final String projectName;
  final String location;
  final MonetaryAmount amount;
  final MonetaryAmount earned;
  final MonetaryAmount projectedPayout;
  final DateTime createdAt;
  final InvestorInvestmentStatus status;
  final int progressBasisPoints;
  final String imageAsset;
  final ProjectCategory category;
  final int durationMonths;
  final String? thumbnailAsset;
  final InvestmentMilestoneStage recordedMilestone;
  final bool principalReturned;
  final int payoutEveryMonths;
  final int? annualRateBasisPoints;
  bool get holdsPrincipal =>
      !principalReturned && status != InvestorInvestmentStatus.completed;
  InvestorInvestment withPrincipalReturned() => InvestorInvestment(
    id: id,
    projectId: projectId,
    projectName: projectName,
    location: location,
    amount: amount,
    earned: earned,
    projectedPayout: projectedPayout,
    createdAt: createdAt,
    status: status,
    progressBasisPoints: progressBasisPoints,
    imageAsset: imageAsset,
    category: category,
    durationMonths: durationMonths,
    thumbnailAsset: thumbnailAsset,
    recordedMilestone: recordedMilestone,
    principalReturned: true,
    payoutEveryMonths: payoutEveryMonths,
    annualRateBasisPoints: annualRateBasisPoints,
  );

  InvestmentMilestoneStage get milestoneStage =>
      status == InvestorInvestmentStatus.completed
      ? InvestmentMilestoneStage.matured
      : recordedMilestone;

  List<MonetaryAmount> get distributionPayments =>
      InvestmentProjection.distribute(
        projectedPayout - amount,
        durationMonths ~/ payoutEveryMonths,
      );
  MonetaryAmount get distribution => distributionPayments.first;
  MonetaryAmount get principalAtMaturity => amount;

  DateTime get maturityAt {
    final month = createdAt.month + durationMonths;
    final create = createdAt.isUtc ? DateTime.utc : DateTime.new;
    final lastDay = create(createdAt.year, month + 1, 0).day;
    return create(
      createdAt.year,
      month,
      createdAt.day > lastDay ? lastDay : createdAt.day,
      createdAt.hour,
      createdAt.minute,
      createdAt.second,
      createdAt.millisecond,
      createdAt.microsecond,
    );
  }
}

final class InvestorFundingMilestone {
  const InvestorFundingMilestone({
    required this.projectName,
    required this.location,
    required this.imageAsset,
    required this.raised,
    required this.investors,
    required this.daysToClose,
    required this.nextSteps,
  });

  final String projectName;
  final String location;
  final String imageAsset;
  final MonetaryAmount raised;
  final int investors;
  final int daysToClose;
  final List<String> nextSteps;
}

final class InvestorNotification {
  const InvestorNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.destination,
    required this.kind,
    this.targetId,
    this.read = false,
    this.fundingMilestone,
    this.timeLabel = 'Now',
  });

  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final InvestorDestination destination;
  final InvestorNotificationKind kind;
  final String? targetId;
  final bool read;
  final InvestorFundingMilestone? fundingMilestone;
  final String timeLabel;

  InvestorNotificationFilter get category => switch (kind) {
    InvestorNotificationKind.topUp => InvestorNotificationFilter.walletTopUp,
    InvestorNotificationKind.investment ||
    InvestorNotificationKind.distribution =>
      InvestorNotificationFilter.investments,
    _ => InvestorNotificationFilter.updates,
  };

  InvestorNotification markRead() => InvestorNotification(
    id: id,
    title: title,
    message: message,
    createdAt: createdAt,
    destination: destination,
    kind: kind,
    targetId: targetId,
    read: true,
    fundingMilestone: fundingMilestone,
    timeLabel: timeLabel,
  );
}

final class InvestorAccountSnapshot {
  InvestorAccountSnapshot({
    required Map<Currency, int> balances,
    required List<InvestorInvestment> investments,
    required List<InvestorTransaction> transactions,
    required List<InvestorNotification> notifications,
    required List<InvestorPaymentMethod> paymentMethods,
    required this.verification,
    required this.asOf,
    this.balanceVisible = true,
  }) : balances = Map.unmodifiable(balances),
       investments = List.unmodifiable(investments),
       transactions = List.unmodifiable(transactions),
       notifications = List.unmodifiable(notifications),
       paymentMethods = List.unmodifiable(paymentMethods);

  final bool balanceVisible;
  final Map<Currency, int> balances;
  final List<InvestorInvestment> investments;
  final List<InvestorTransaction> transactions;
  final List<InvestorNotification> notifications;
  final List<InvestorPaymentMethod> paymentMethods;
  final VerificationStatus verification;
  final DateTime asOf;

  MonetaryAmount balance(Currency currency) =>
      MonetaryAmount(balances[currency] ?? 0, currency);
}

final class InvestorAccountChange {
  const InvestorAccountChange(this.kinds);
  final Set<InvestorDataKind> kinds;
  bool affects(InvestorDataKind kind) =>
      kinds.contains(InvestorDataKind.scope) || kinds.contains(kind);
}

final class InvestorOperationReceipt {
  const InvestorOperationReceipt({
    required this.transactionId,
    this.investmentId,
  });
  final String transactionId;
  final String? investmentId;
}
