// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'information_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$InformationStore on InformationStoreBase, Store {
  late final _$expandedQuestionAtom = Atom(
    name: 'InformationStoreBase.expandedQuestion',
    context: context,
  );

  @override
  int? get expandedQuestion {
    _$expandedQuestionAtom.reportRead();
    return super.expandedQuestion;
  }

  @override
  set expandedQuestion(int? value) {
    _$expandedQuestionAtom.reportWrite(value, super.expandedQuestion, () {
      super.expandedQuestion = value;
    });
  }

  late final _$acceptedTermsAtom = Atom(
    name: 'InformationStoreBase.acceptedTerms',
    context: context,
  );

  @override
  bool get acceptedTerms {
    _$acceptedTermsAtom.reportRead();
    return super.acceptedTerms;
  }

  @override
  set acceptedTerms(bool value) {
    _$acceptedTermsAtom.reportWrite(value, super.acceptedTerms, () {
      super.acceptedTerms = value;
    });
  }

  late final _$InformationStoreBaseActionController = ActionController(
    name: 'InformationStoreBase',
    context: context,
  );

  @override
  void toggleQuestion(int index) {
    final _$actionInfo = _$InformationStoreBaseActionController.startAction(
      name: 'InformationStoreBase.toggleQuestion',
    );
    try {
      return super.toggleQuestion(index);
    } finally {
      _$InformationStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void acceptTerms(bool value) {
    final _$actionInfo = _$InformationStoreBaseActionController.startAction(
      name: 'InformationStoreBase.acceptTerms',
    );
    try {
      return super.acceptTerms(value);
    } finally {
      _$InformationStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
expandedQuestion: ${expandedQuestion},
acceptedTerms: ${acceptedTerms}
    ''';
  }
}
