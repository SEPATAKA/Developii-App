// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'experience_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ExperienceStore on ExperienceStoreBase, Store {
  late final _$selectedAtom = Atom(
    name: 'ExperienceStoreBase.selected',
    context: context,
  );

  @override
  Experience get selected {
    _$selectedAtom.reportRead();
    return super.selected;
  }

  @override
  set selected(Experience value) {
    _$selectedAtom.reportWrite(value, super.selected, () {
      super.selected = value;
    });
  }

  late final _$investorUnavailableAtom = Atom(
    name: 'ExperienceStoreBase.investorUnavailable',
    context: context,
  );

  @override
  bool get investorUnavailable {
    _$investorUnavailableAtom.reportRead();
    return super.investorUnavailable;
  }

  @override
  set investorUnavailable(bool value) {
    _$investorUnavailableAtom.reportWrite(value, super.investorUnavailable, () {
      super.investorUnavailable = value;
    });
  }

  late final _$ExperienceStoreBaseActionController = ActionController(
    name: 'ExperienceStoreBase',
    context: context,
  );

  @override
  void select(Experience value) {
    final _$actionInfo = _$ExperienceStoreBaseActionController.startAction(
      name: 'ExperienceStoreBase.select',
    );
    try {
      return super.select(value);
    } finally {
      _$ExperienceStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  bool confirm() {
    final _$actionInfo = _$ExperienceStoreBaseActionController.startAction(
      name: 'ExperienceStoreBase.confirm',
    );
    try {
      return super.confirm();
    } finally {
      _$ExperienceStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
selected: ${selected},
investorUnavailable: ${investorUnavailable}
    ''';
  }
}
