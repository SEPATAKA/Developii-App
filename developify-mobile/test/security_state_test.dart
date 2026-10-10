import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/core/services/mock_behavior.dart';
import 'package:developify_mobile/core/services/session_service.dart';
import 'package:developify_mobile/features/profile/data/mock_profile_repository.dart';
import 'package:developify_mobile/features/profile/presentation/stores/security_store.dart';

void main() {
  test(
    'Open security stores observe repository changes and stop on disposal',
    () async {
      final session = SessionService();
      final repository = MockProfileRepository(
        MockBehavior(delay: Duration.zero),
        session,
      );
      final menu = SecurityStore(repository);
      final editor = SecurityStore(repository);
      editor.setCode('123456');
      expect(await editor.perform('verify-code'), true);
      expect(menu.twoFactorEnabled, true);
      menu.toggleBiometric('Use for investment', true);
      expect(editor.biometrics['Use for investment'], true);
      editor.removeDevice('previous-1');
      expect(menu.previousDevices, ['previous-2']);
      editor.dispose();
      repository.clearSession();
      expect(menu.twoFactorEnabled, false);
      expect(menu.biometrics.values.every((value) => !value), true);
      expect(menu.previousDevices, hasLength(2));
      expect(editor.twoFactorEnabled, true);
      menu.dispose();
      repository.dispose();
      session.dispose();
    },
  );

  test(
    'Logout cancels pending security changes and disposed stores stay clear',
    () async {
      final session = SessionService();
      final repository = MockProfileRepository(
        MockBehavior(delay: const Duration(milliseconds: 30)),
        session,
      );
      final store = SecurityStore(repository);
      store.setCode('123456');
      final pending = store.perform('verify-code');
      store.previousStage();
      store.setCode('654321');
      expect(store.code, '123456');
      repository.clearSession();
      expect(await pending, false);
      expect(repository.securityPreferences.twoFactorEnabled, false);
      store.setPassword('ExistingPass123!');
      store.setNewPassword('Replacement123!');
      store.setConfirmation('Replacement123!');
      final update = store.perform('change-password');
      store.dispose();
      repository.clearSession();
      expect(await update, false);
      expect(store.password, isEmpty);
      expect(store.newPassword, isEmpty);
      expect(repository.securityPreferences.previousDevices, hasLength(2));
      repository.dispose();
      session.dispose();
    },
  );
}
