import 'dart:async';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/services/mock_request_scope.dart';
import 'package:developify_mobile/core/services/mock_behavior.dart';
import 'package:developify_mobile/core/services/session_service.dart';
import 'package:developify_mobile/features/landowner/domain/landowner_repository.dart';
import 'package:developify_mobile/features/landowner/domain/property.dart';
import 'package:developify_mobile/features/landowner/domain/submission_draft.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

final class MockLandownerRepository implements LandownerRepository {
  MockLandownerRepository(this.behavior, {SessionService? session})
    : _session = session {
    _userId = _session?.user?.id;
    _session?.addListener(_onSession);
  }
  final MockBehavior behavior;
  final SessionService? _session;
  String? _userId;

  void _onSession() {
    final next = _session?.user?.id;
    if (next == _userId) return;
    _userId = next;
    _drafts.clear();
    _submitted.clear();
    _submittedDraftIds.clear();
    if (!_changes.isClosed) _changes.add(null);
  }

  bool get _showSeeded => !behavior.empty && !isFreshLocalAccount(_userId);
  bool _balanceVisible = true;
  final _visibilityChanges = StreamController<bool>.broadcast(sync: true);
  @override
  bool get balanceVisible => _balanceVisible;
  @override
  Stream<bool> get balanceVisibilityChanges => _visibilityChanges.stream;
  @override
  void setBalanceVisible(bool visible) {
    if (_balanceVisible == visible) return;
    _balanceVisible = visible;
    _visibilityChanges.add(visible);
  }

  final _requests = MockRequestScope();
  Future<Result<T>> _run<T>(T Function() operation) =>
      _requests.run(behavior, operation);
  final _changes = StreamController<void>.broadcast();
  @override
  Stream<void> get changes => _changes.stream;
  @override
  Future<void> dispose() {
    _session?.removeListener(_onSession);
    _requests.cancel();
    unawaited(_visibilityChanges.close());
    return _changes.close();
  }

  @override
  void clearSession() {
    _requests.cancel();
    setBalanceVisible(true);
    _drafts.clear();
    _submitted.clear();
    _submittedDraftIds.clear();
    _changes.add(null);
  }

  final Map<String, SubmissionDraft> _drafts = {};
  final List<Property> _submitted = [];
  final Set<String> _submittedDraftIds = {};
  static const fixtures = [
    Property(
      id: 'sea-point',
      name: 'Sea Point Sunset Rd',
      town: 'Cape Town',
      status: PropertyStatus.live,
    ),
    Property(
      id: 'ridge-offer',
      name: 'Ridge Site 12',
      town: 'KZN',
      status: PropertyStatus.offerReady,
    ),
    Property(
      id: 'ridge-review',
      name: 'Ridge Site 12',
      town: 'KZN',
      status: PropertyStatus.underReview,
    ),
    Property(
      id: 'marula-paused',
      name: 'Marula Heights',
      town: 'Mpuma',
      status: PropertyStatus.paused,
    ),
    Property(
      id: 'marula-draft',
      name: 'Marula Heights',
      town: 'Mpuma',
      status: PropertyStatus.draft,
    ),
    Property(
      id: 'ridge-review-2',
      name: 'Ridge Site 12',
      town: 'KZN',
      status: PropertyStatus.underReview,
    ),
    Property(
      id: 'ridge-live',
      name: 'Ridge Site 12',
      town: 'KZN',
      status: PropertyStatus.live,
    ),
    Property(
      id: 'ridge-offer-2',
      name: 'Ridge Site 12',
      town: 'KZN',
      status: PropertyStatus.offerReady,
    ),
    Property(
      id: 'marula-paused-2',
      name: 'Marula Heights',
      town: 'Mpuma',
      status: PropertyStatus.paused,
    ),
  ];
  List<Property> get _properties => [
    ..._submitted,
    ..._drafts.values
        .where((draft) => draft.name.trim().isNotEmpty)
        .map(
          (draft) => Property(
            id: draft.id,
            name: draft.name,
            town: draft.city,
            status: PropertyStatus.draft,
            size: '${draft.size} ${draft.unit}',
            draftStep: draft.step,
          ),
        ),
    if (_showSeeded)
      ...fixtures.where(
        (property) =>
            !_drafts.containsKey(property.id) &&
            !_submittedDraftIds.contains(property.id),
      ),
  ];
  @override
  Future<Result<LandownerOverview>> overview() => _run(
    () => LandownerOverview(
      properties: _submitted.isNotEmpty
          ? [_submitted.last]
          : _showSeeded
          ? [fixtures.firstWhere((p) => p.id == 'ridge-live')]
          : [],
      propertyCount: (_showSeeded ? 5 : 0) + _submitted.length,
      approvedCount: _showSeeded ? 2 : 0,
      earnedCents: _showSeeded ? 48000001 : 0,
      nextPayoutCents: _showSeeded ? 6000000 : 0,
    ),
  );
  @override
  Future<Result<List<Property>>> properties() =>
      _run(() => List.unmodifiable(_properties));
  @override
  Future<Result<Property>> property(String id) async {
    final items = _properties.where((item) => item.id == id);
    if (items.isEmpty) {
      return const Failure(
        AppFailure(FailureKind.notFound, 'This property could not be found.'),
      );
    }
    return _run(() => items.first);
  }

  @override
  Future<Result<EarningsSummary>> earnings() => _run(
    () => EarningsSummary(
      totalCents: _showSeeded ? 48000001 : 0,
      nextPayoutCents: _showSeeded ? 6000000 : 0,
      payouts: _showSeeded
          ? List.generate(
              4,
              (index) => Payout(
                id: 'payout-$index',
                propertyName: 'Marula Heigths',
                amountCents: 6000000,
                period: 'Q2 lease',
                date: '15 Feb, 2026 10:24pm',
              ),
            )
          : [],
    ),
  );
  @override
  SubmissionDraft readDraft(String id) {
    if (_submittedDraftIds.contains(id)) return SubmissionDraft(id: id);
    if (_drafts[id] case final draft?) return draft;
    if (id == 'marula-draft' && _showSeeded) {
      return const SubmissionDraft(
        id: 'marula-draft',
        step: 6,
        name: 'Marula Heights',
        legalDescription: 'Malibongwe Erf 4412',
        propertyNumber: '12',
        propertyType: 'Vacant land',
        size: '1.4',
        unit: 'Hectares',
        deedsOffice: 'Johannesburg',
        address: 'Malibongwe Drive, off Republic Rd',
        city: 'Johannesburg',
        province: 'Gauteng',
        postalCode: '2184',
        latitude: '-26.076',
        longitude: '27.958',
        photos: [
          LocalAttachment(id: 'photo-0', name: 'North boundary'),
          LocalAttachment(id: 'photo-1', name: 'South boundary'),
          LocalAttachment(id: 'photo-2', name: 'East boundary'),
          LocalAttachment(id: 'photo-3', name: 'West boundary'),
        ],
      );
    }
    return SubmissionDraft(id: id);
  }

  @override
  void saveDraft(SubmissionDraft draft) {
    _drafts[draft.id] = draft;
    _changes.add(null);
  }

  @override
  Future<Result<String>> submit(SubmissionDraft draft) => _run(() {
    final id = _submitted.isEmpty
        ? 'PROP-4412-A28K'
        : 'PROP-4412-A28K-${_submitted.length + 1}';
    _submitted.add(
      Property(
        id: id,
        name: draft.name,
        town: draft.city,
        status: PropertyStatus.underReview,
        size: '${draft.size} ${draft.unit}',
      ),
    );
    _drafts.remove(draft.id);
    _submittedDraftIds.add(draft.id);
    _changes.add(null);
    return id;
  });
}
