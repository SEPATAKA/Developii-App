import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/features/landowner/domain/property.dart';
import 'package:developify_mobile/features/landowner/domain/submission_draft.dart';

abstract interface class LandownerRepository {
  bool get balanceVisible;
  Stream<bool> get balanceVisibilityChanges;
  void setBalanceVisible(bool visible);
  void clearSession();
  Stream<void> get changes;
  Future<void> dispose();
  Future<Result<LandownerOverview>> overview();
  Future<Result<List<Property>>> properties();
  Future<Result<Property>> property(String id);
  Future<Result<EarningsSummary>> earnings();
  SubmissionDraft readDraft(String id);
  void saveDraft(SubmissionDraft draft);
  Future<Result<String>> submit(SubmissionDraft draft);
}
