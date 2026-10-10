// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ChatStore on ChatStoreBase, Store {
  late final _$statusAtom = Atom(
    name: 'ChatStoreBase.status',
    context: context,
  );

  @override
  LoadStatus get status {
    _$statusAtom.reportRead();
    return super.status;
  }

  @override
  set status(LoadStatus value) {
    _$statusAtom.reportWrite(value, super.status, () {
      super.status = value;
    });
  }

  late final _$messagesAtom = Atom(
    name: 'ChatStoreBase.messages',
    context: context,
  );

  @override
  List<ChatMessage> get messages {
    _$messagesAtom.reportRead();
    return super.messages;
  }

  @override
  set messages(List<ChatMessage> value) {
    _$messagesAtom.reportWrite(value, super.messages, () {
      super.messages = value;
    });
  }

  late final _$draftAtom = Atom(name: 'ChatStoreBase.draft', context: context);

  @override
  String get draft {
    _$draftAtom.reportRead();
    return super.draft;
  }

  @override
  set draft(String value) {
    _$draftAtom.reportWrite(value, super.draft, () {
      super.draft = value;
    });
  }

  late final _$sendingAtom = Atom(
    name: 'ChatStoreBase.sending',
    context: context,
  );

  @override
  bool get sending {
    _$sendingAtom.reportRead();
    return super.sending;
  }

  @override
  set sending(bool value) {
    _$sendingAtom.reportWrite(value, super.sending, () {
      super.sending = value;
    });
  }

  late final _$errorAtom = Atom(name: 'ChatStoreBase.error', context: context);

  @override
  String? get error {
    _$errorAtom.reportRead();
    return super.error;
  }

  @override
  set error(String? value) {
    _$errorAtom.reportWrite(value, super.error, () {
      super.error = value;
    });
  }

  late final _$loadAsyncAction = AsyncAction(
    'ChatStoreBase.load',
    context: context,
  );

  @override
  Future<void> load() {
    return _$loadAsyncAction.run(() => super.load());
  }

  late final _$sendAsyncAction = AsyncAction(
    'ChatStoreBase.send',
    context: context,
  );

  @override
  Future<bool> send() {
    return _$sendAsyncAction.run(() => super.send());
  }

  late final _$ChatStoreBaseActionController = ActionController(
    name: 'ChatStoreBase',
    context: context,
  );

  @override
  void setDraft(String value) {
    final _$actionInfo = _$ChatStoreBaseActionController.startAction(
      name: 'ChatStoreBase.setDraft',
    );
    try {
      return super.setDraft(value);
    } finally {
      _$ChatStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
status: ${status},
messages: ${messages},
draft: ${draft},
sending: ${sending},
error: ${error}
    ''';
  }
}
