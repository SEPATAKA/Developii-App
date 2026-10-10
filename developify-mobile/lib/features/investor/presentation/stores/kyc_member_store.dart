import 'dart:async';
import 'package:mobx/mobx.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/utils/lifecycle.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_member_plan.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_repository.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
part 'kyc_member_store.g.dart';

class KycMemberStore = KycMemberStoreBase with _$KycMemberStore;

abstract class KycMemberStoreBase with Store, Lifecycle {
  KycMemberStoreBase(this._repository, this.entity) {
    _changes = _repository.changes.listen((event) {
      if (isDisposed || event.entity != null) return;
      beginRequest();
      runInAction(() {
        application = null;
        draft = null;
        busy = false;
        uploading = null;
        errors = const {};
        allocations = const {};
        status = LoadStatus.error;
        error = 'The selected profile changed. Reopen the member to continue.';
      });
    });
  }
  final KycRepository _repository;
  final EntityType entity;
  late final StreamSubscription<KycChange> _changes;
  String _key = '';
  @observable
  LoadStatus status = LoadStatus.initial;
  @observable
  KycDraft? application;
  @observable
  KycMemberDraft? draft;
  @observable
  String? error;
  @observable
  Map<String, String> errors = const {};
  @observable
  bool busy = false;
  @observable
  String? uploading;
  @observable
  Map<String, int> allocations = const {};
  @computed
  bool get editable =>
      !isDisposed &&
      application != null &&
      application!.status != VerificationStatus.pending &&
      application!.status != VerificationStatus.verified;
  @computed
  Map<String, String> get values => draft?.values ?? const {};
  @computed
  KycMember? get member => application?.members
      .where((member) => member.id == draft?.id)
      .firstOrNull;
  @computed
  int? get age => KycMemberPlan.age(values['birthDate'] ?? '', DateTime.now());
  @computed
  List<KycDocumentDefinition> get documents => draft == null
      ? const []
      : KycMemberPlan.documents(draft!, DateTime.now());
  @computed
  bool get canSave =>
      editable &&
      !busy &&
      draft != null &&
      KycMemberPlan.validate(draft!, DateTime.now()).isEmpty;
  @computed
  int get shareBasisPoints => draft?.role == KycMemberRole.shareholder
      ? KycMemberPlan.sharesBasisPoints(values)
      : member?.shareBasisPoints ?? 0;

  @action
  Future<void> load(KycMemberRole role, {String? id}) async {
    if (isDisposed) return;
    final request = beginRequest();
    status = LoadStatus.loading;
    errors = const {};
    error = null;
    final result = await _repository.load(entity);
    if (!isCurrent(request)) return;
    runInAction(() {
      if (!_accept(result)) {
        status = LoadStatus.error;
        return;
      }
      final existing = application!.members
          .where((member) => member.id == id)
          .firstOrNull;
      if (KycMemberPlan.role(entity, role.name) == null ||
          id != null &&
              (id.isEmpty || existing == null || existing.role != role)) {
        status = LoadStatus.error;
        error = 'This member could not be found.';
        return;
      }
      _key = id ?? 'new-${role.name}';
      draft =
          application!.memberDrafts[_key] ??
          (existing == null
              ? KycMemberDraft(
                  id: '${entity.name}-${role.name}-${application!.revision + 1}',
                  role: role,
                  values: const {'country': 'South Africa', 'share': '0'},
                )
              : KycMemberPlan.fromMember(existing));
      if (editable &&
          !_accept(_repository.saveMemberDraft(entity, _key, draft!))) {
        status = LoadStatus.error;
        return;
      }
      status = LoadStatus.success;
      allocations = {
        for (final member in application!.members.where(
          (member) => member.role == role,
        ))
          member.id:
              int.tryParse(
                application!.values['allocation:${member.id}'] ?? '',
              ) ??
              member.shareBasisPoints,
      };
    });
  }

  bool _accept(Result<KycDraft> result) {
    switch (result) {
      case Success(:final value):
        application = value;
        draft = value.memberDrafts[_key] ?? draft;
        error = null;
        return true;
      case Failure(:final error):
        this.error = error.message;
        errors = error.fields;
        return false;
    }
  }

  @action
  void edit(String key, String value) {
    if (!editable || busy || draft == null) return;
    if (_accept(
      _repository.saveMemberDraft(
        entity,
        _key,
        draft!.copyWith(values: {...values, key: value}),
      ),
    )) {
      errors = {...errors}..remove(key);
    }
  }

  @action
  bool save() {
    if (!editable || busy || draft == null) return false;
    errors = KycMemberPlan.validate(draft!, DateTime.now());
    if (errors.isNotEmpty) {
      error = 'Complete the highlighted fields to continue.';
      return false;
    }
    final saved = KycMemberPlan.member(draft!, previous: member);
    return _accept(_repository.saveMember(entity, saved));
  }

  @action
  void allocate(String id, double value) {
    if (!editable || busy || !allocations.containsKey(id) || !value.isFinite) {
      return;
    }
    final member = application!.members.firstWhere((member) => member.id == id);
    var amount = value.round().clamp(0, 10000);
    final total = member.details?.issuedShares ?? 0;
    if (member.role == KycMemberRole.shareholder && total > 0) {
      final shares = (amount * total / 10000).round();
      amount = (shares * 10000 + total ~/ 2) ~/ total;
    }
    if (_accept(
      _repository.save(
        application!.copyWith(
          values: {...application!.values, 'allocation:$id': '$amount'},
        ),
      ),
    )) {
      allocations = {...allocations, id: amount};
      errors = const {};
    }
  }

  @computed
  int get totalAllocation =>
      allocations.values.fold(0, (total, value) => total + value);
  @action
  bool saveAllocations() {
    if (!editable || busy || draft == null) return false;
    return _accept(
      _repository.saveAllocations(entity, draft!.role, allocations),
    );
  }

  @action
  Future<bool> upload(
    String key, {
    required String name,
    required int bytes,
    required String mimeType,
  }) async {
    if (!editable || busy || draft == null) return false;
    final request = beginRequest();
    busy = true;
    uploading = key;
    error = null;
    final result = await _repository.uploadMemberDocument(
      entity,
      _key,
      key,
      name: name,
      bytes: bytes,
      mimeType: mimeType,
    );
    if (!isCurrent(request)) return false;
    return runInAction(() {
      busy = false;
      uploading = null;
      final accepted = _accept(result);
      if (accepted) errors = {...errors}..remove(key);
      return accepted;
    });
  }

  @action
  bool deleteDocument(String key) {
    if (!editable || busy || draft == null) return false;
    return _accept(_repository.deleteMemberDocument(entity, _key, key));
  }

  KycInvite get invitation => KycInvite(
    memberId: draft?.id ?? '',
    email: values['email']?.trim() ?? '',
    phone: values['phone']?.replaceAll(RegExp(r'[ ()-]'), '') ?? '',
    message: values['message']?.trim() ?? '',
    sendSms: values['sms'] == 'true',
    reminders: values['reminders'] == 'true',
    notifyOpened: values['opened'] == 'true',
    attachments: {
      for (final key in KycMemberPlan.inviteAttachments.keys)
        if (values['attach-$key'] == 'true') key,
    },
  );
  @computed
  bool get canInvite =>
      editable &&
      !busy &&
      draft != null &&
      KycMemberPlan.validateInvite(
        invitation,
        trust: entity == EntityType.trust,
      ).isEmpty;

  @action
  bool validateInvite() {
    errors = KycMemberPlan.validateInvite(
      invitation,
      trust: entity == EntityType.trust,
    );
    return errors.isEmpty;
  }

  @action
  Future<bool> invite() async {
    if (!canInvite || !validateInvite()) return false;
    final request = beginRequest();
    busy = true;
    error = null;
    final result = await _repository.invite(entity, invitation);
    if (!isCurrent(request)) return false;
    return runInAction(() {
      busy = false;
      return _accept(result);
    });
  }

  @override
  void dispose() {
    unawaited(_changes.cancel());
    draft = null;
    application = null;
    super.dispose();
  }
}
