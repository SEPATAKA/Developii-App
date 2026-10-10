// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$OnboardingStore on OnboardingStoreBase, Store {
  Computed<bool>? _$isLastComputed;

  @override
  bool get isLast => (_$isLastComputed ??= Computed<bool>(
    () => super.isLast,
    name: 'OnboardingStoreBase.isLast',
  )).value;

  late final _$pageAtom = Atom(
    name: 'OnboardingStoreBase.page',
    context: context,
  );

  @override
  int get page {
    _$pageAtom.reportRead();
    return super.page;
  }

  @override
  set page(int value) {
    _$pageAtom.reportWrite(value, super.page, () {
      super.page = value;
    });
  }

  late final _$OnboardingStoreBaseActionController = ActionController(
    name: 'OnboardingStoreBase',
    context: context,
  );

  @override
  void setPage(int value) {
    final _$actionInfo = _$OnboardingStoreBaseActionController.startAction(
      name: 'OnboardingStoreBase.setPage',
    );
    try {
      return super.setPage(value);
    } finally {
      _$OnboardingStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  bool next() {
    final _$actionInfo = _$OnboardingStoreBaseActionController.startAction(
      name: 'OnboardingStoreBase.next',
    );
    try {
      return super.next();
    } finally {
      _$OnboardingStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void finish() {
    final _$actionInfo = _$OnboardingStoreBaseActionController.startAction(
      name: 'OnboardingStoreBase.finish',
    );
    try {
      return super.finish();
    } finally {
      _$OnboardingStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
page: ${page},
isLast: ${isLast}
    ''';
  }
}
