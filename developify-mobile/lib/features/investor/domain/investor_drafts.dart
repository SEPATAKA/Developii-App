import 'dart:async';
import 'package:developify_mobile/features/investor/domain/investment_policy.dart';
import 'package:developify_mobile/features/investor/domain/investor_account_context.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

enum InvestorTransferKind { topUp, withdrawal }

final class InvestmentDraft {
  const InvestmentDraft({this.amount = '', this.agreed = false, this.quote});
  final String amount;
  final bool agreed;
  final InvestmentProjection? quote;
}

final class TransferDraft {
  const TransferDraft({this.amount = '', this.methodId});
  final String amount;
  final String? methodId;
}

final class InvestorDrafts {
  InvestorDrafts(this._context) {
    _userId = _context.scope?.userId;
    _subscription = _context.changes.listen((scope) {
      if (_userId != scope?.userId) {
        _investments.clear();
        _transfers.clear();
        _userId = scope?.userId;
      }
    });
  }
  final InvestorAccountContext _context;
  String? _userId;
  late final StreamSubscription<InvestorScope?> _subscription;
  // Entity/project keys preserve a journey during portal switches. Drafts are
  // memory-only and are cleared when the authenticated user changes.
  final _investments = <(EntityType, String), InvestmentDraft>{};
  final _transfers = <(EntityType, InvestorTransferKind), TransferDraft>{};
  InvestmentDraft investment(String id) =>
      _investments[(_context.entity, id)] ?? const InvestmentDraft();
  void saveInvestment(String id, InvestmentDraft draft) {
    if (_context.scope != null) _investments[(_context.entity, id)] = draft;
  }

  void clearInvestment(String id) => _investments.remove((_context.entity, id));
  TransferDraft transfer(InvestorTransferKind kind) =>
      _transfers[(_context.entity, kind)] ?? const TransferDraft();
  void saveTransfer(InvestorTransferKind kind, TransferDraft draft) {
    if (_context.scope != null) _transfers[(_context.entity, kind)] = draft;
  }

  void clearTransfer(InvestorTransferKind kind) =>
      _transfers.remove((_context.entity, kind));
  void dispose() {
    unawaited(_subscription.cancel());
    _investments.clear();
    _transfers.clear();
  }
}
