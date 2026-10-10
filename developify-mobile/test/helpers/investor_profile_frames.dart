import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/features/authentication/presentation/recovery_screen.dart';
import 'package:developify_mobile/features/profile/domain/profile_repository.dart';
import 'package:developify_mobile/features/investor/presentation/screens/investor_profile_screen.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_logout_sheet.dart';

const investorProfileRootFrames = {
  '63680',
  '63889',
  '64098',
  '64307',
  '64516',
  '64725',
  '64934',
  '65143',
  '65352',
  '65561',
  '65874',
  '66098',
  '66307',
  '66516',
  '66725',
};

Future<void> prepareInvestorProfileFrame(
  AppDependencies dependencies,
  String node,
) async {
  final repository = dependencies.container<ProfileRepository>();
  if (investorProfileRootFrames.contains(node)) {
    final current = repository.preferences;
    await repository.updatePreferences(
      ProfilePreferences(
        channels: current.channels,
        topics: current.topics,
        language: 'English (US)',
      ),
    );
  }
  if (node == '67914') {
    final current = repository.preferences;
    await repository.updatePreferences(
      ProfilePreferences(
        channels: {for (final key in current.channels.keys) key: false},
        topics: {for (final key in current.topics.keys) key: false},
      ),
    );
  }
  if (node == '68499' || node == '68593') {
    repository.saveSecurityPreferences(
      const SecurityPreferences(twoFactorEnabled: true),
    );
  }
}

Future<void> showInvestorProfileFrame(WidgetTester tester, String node) async {
  if (node == '65874') {
    unawaited(
      showInvestorLogoutSheet(
        tester.element(find.byType(InvestorProfileScreen)),
      ),
    );
    await tester.pumpAndSettle();
  }
  Future<void> enter(Finder finder, String value) async {
    await tester.ensureVisible(finder);
    await tester.enterText(finder, value);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  Future<void> tap(String label) async {
    final finder = find.widgetWithText(AppButton, label);
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  if (node == '69134') {
    for (final label in [
      'Current Password',
      'New Password',
      'Confirm New Password',
    ]) {
      await enter(find.byKey(ValueKey('field-$label')), 'TestPassword123!');
    }
    await tap('Update Password');
  }
  if (const {'69194', '69236', '69281', '69326'}.contains(node)) {
    await enter(
      find.byKey(const ValueKey('field-Enter Current Password')),
      'TestPassword123!',
    );
    if (node == '69194') {
      await tester.tap(find.byTooltip('Show password'));
      await tester.pumpAndSettle();
    } else {
      await tap('Continue');
      if (node != '69236') {
        await enter(
          find.byKey(const ValueKey('transaction-pin-field')),
          '1234',
        );
        if (node == '69326') await tap('Continue');
      }
    }
  }
  const smsCode = {'69535', '69697', '69783', '69895'};
  const appCode = {'69578', '69740', '69839', '69938'};
  if (smsCode.contains(node) || node == '69659') {
    await enter(
      find.byKey(const ValueKey('field-Phone Number')),
      '9012737476172',
    );
    if (smsCode.contains(node)) await tap('Send code');
  }
  if (appCode.contains(node) || node == '69389') {
    await enter(
      find.byKey(const ValueKey('authenticator-setup-code')),
      '284091',
    );
    if (appCode.contains(node)) await tap('Continue');
  }
  if (const {
    '69697',
    '69740',
    '69783',
    '69839',
    '69895',
    '69938',
  }.contains(node)) {
    await enter(
      find.descendant(
        of: find.byType(CodeField),
        matching: find.byType(TextField),
      ),
      node == '69783' || node == '69839' ? '123456' : '000000',
    );
    if (node != '69697' && node != '69740') await tap('Verify');
  }
  if (node == '70137') {
    for (final label in [
      'Use for login',
      'Use for investment',
      'Use for withdrawals',
    ]) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
  }
}
