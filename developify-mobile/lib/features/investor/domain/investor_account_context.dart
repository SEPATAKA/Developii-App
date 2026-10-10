import 'dart:async';
import 'package:developify_mobile/core/services/session_service.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

final class InvestorScope {
  const InvestorScope(this.userId, this.entity, this.revision);
  final String userId;
  final EntityType entity;
  final int revision;
}

final class InvestorAccountContext {
  InvestorAccountContext(this._session) {
    _session.addListener(_sessionChanged);
    _sessionChanged();
  }

  final SessionService _session;
  final _changes = StreamController<InvestorScope?>.broadcast(sync: true);
  String? _userId;
  EntityType _entity = EntityType.individual;
  final _nonResidentProfiles = <EntityType, bool>{};
  int _revision = 0;
  bool _disposed = false;

  Stream<InvestorScope?> get changes => _changes.stream;
  EntityType get entity => _entity;
  bool get nonResident => _nonResidentProfiles[_entity] ?? false;
  bool nonResidentFor(EntityType entity) =>
      _nonResidentProfiles[entity] ?? false;
  AppUser? get user => _session.user;
  InvestorScope? get scope => _userId == null || !_session.isAuthenticated
      ? null
      : InvestorScope(_userId!, _entity, _revision);

  bool isCurrent(InvestorScope value) =>
      !_disposed &&
      _session.isAuthenticated &&
      value.userId == _userId &&
      value.entity == _entity &&
      value.revision == _revision;

  void selectEntity(EntityType entity, {bool? nonResident}) {
    if (_disposed || _userId == null) return;
    final changed =
        entity != _entity ||
        (nonResident != null &&
            nonResident != (_nonResidentProfiles[entity] ?? false));
    if (!changed) return;
    if (nonResident != null) _nonResidentProfiles[entity] = nonResident;
    _entity = entity;
    _revision++;
    final user = _session.user;
    if (user != null) {
      _session.updateUser(
        user.copyWith(entity: entity, nonResident: this.nonResident),
      );
    }
    _changes.add(scope);
  }

  void _sessionChanged() {
    if (_disposed) return;
    final id = _session.user?.id;
    if (id == _userId) return;
    _userId = id;
    _entity = _session.user?.entity ?? EntityType.individual;
    _nonResidentProfiles.clear();
    _nonResidentProfiles[_entity] = _session.user?.nonResident ?? false;
    _revision++;
    _changes.add(scope);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _session.removeListener(_sessionChanged);
    _nonResidentProfiles.clear();
    unawaited(_changes.close());
  }
}
