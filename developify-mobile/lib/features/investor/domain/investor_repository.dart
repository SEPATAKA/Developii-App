import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/investor_project.dart';
import 'package:developify_mobile/features/investor/domain/investment_policy.dart';

abstract interface class InvestorCatalogRepository {
  DateTime get asOf;
  Stream<void> get changes;
  Future<Result<List<InvestorProject>>> projects();
  Future<Result<InvestorProject>> project(String id);
  Set<String> get favouriteIds;
  List<String> get recentSearches;
  List<String> get suggestedProjectIds;
  void rememberSearch(String query);
  Future<Result<void>> setFavourite(String id, bool favourite);
  InvestorProject? currentProject(String id);
  Result<void> contribute(String id, MonetaryAmount amount);
  void dispose();
}

abstract interface class InvestorAccountRepository {
  Stream<InvestorAccountChange> get changes;
  bool get balanceVisible;
  void setBalanceVisible(bool visible);
  Future<Result<InvestorAccountSnapshot>> snapshot();
  Future<Result<InvestorTransaction>> transaction(String id);
  Future<Result<InvestorInvestment>> investment(String id);
  Future<Result<InvestorNotification>> notification(String id);
  Future<Result<void>> markNotificationsRead([String? id]);
  String newOperationId();
  Future<Result<InvestorOperationReceipt>> invest({
    required InvestorProject project,
    required MonetaryAmount amount,
    required String operationId,
    required String pin,
    InvestmentProjection? quote,
    bool simulateBiometric = false,
  });
  Future<Result<InvestorOperationReceipt>> addMoney({
    required MonetaryAmount amount,
    required String methodId,
    required String operationId,
    required String pin,
    bool simulateBiometric = false,
  });
  Future<Result<InvestorOperationReceipt>> withdraw({
    required MonetaryAmount amount,
    required String methodId,
    required String operationId,
    required String pin,
    bool simulateBiometric = false,
  });
  Future<Result<InvestorPaymentMethod>> addCard({
    required String cardNumber,
    required String holder,
    required String expiry,
    required String securityCode,
    bool reusable = true,
  });
  Future<Result<InvestorPaymentMethod>> addBankAccount({
    required String bank,
    required String accountNumber,
    required String accountType,
    required String branchCode,
    required String holder,
  });
  Future<Result<void>> removePaymentMethod(String id);
  Future<Result<void>> setDefaultPaymentMethod(String id, bool isDefault);
  void setVerification(VerificationStatus status, {EntityType? entity});
  void dispose();
}
