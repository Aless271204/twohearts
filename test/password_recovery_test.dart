import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twohearts/services/password_recovery.dart';
import 'package:twohearts/presentation/sign_up_login_screen/password_recovery_screen.dart';

class FakeRecoveryGateway implements RecoveryGateway {
  int requests = 0, verifications = 0, updates = 0, closes = 0;
  bool badCode = false, changedAccount = false, closeFails = false;
  bool? lastCloseAll;
  Completer<String>? pendingVerify;
  @override
  Future<void> request(String email) async {
    requests++;
  }

  @override
  Future<String> verify(String email, String code) async {
    verifications++;
    if (badCode) throw StateError('invalid or expired');
    return pendingVerify?.future ?? Future.value('recovery-user');
  }

  @override
  Future<void> replacePassword(String verifiedUserId, String password) async {
    if (changedAccount) throw StateError('account changed');
    expect(verifiedUserId, 'recovery-user');
    updates++;
  }

  @override
  Future<void> closeSession({required bool allSessions}) async {
    closes++;
    lastCloseAll = allSessions;
    if (closeFails) throw StateError('offline');
  }
}

void main() {
  late FakeRecoveryGateway gateway;
  late PasswordRecovery recovery;
  setUp(() {
    gateway = FakeRecoveryGateway();
    recovery = PasswordRecovery(gateway)..begin('person@example.test');
  });
  tearDown(() => recovery.dispose());

  Future<void> verified() async {
    await recovery.sendCode('person@example.test');
    await recovery.verifyCode('123456');
  }

  test('invalid email does not send a request', () async {
    await recovery.sendCode('not an email');
    expect(gateway.requests, 0);
    expect(recovery.step, RecoveryStep.email);
    expect(recovery.error, isNotNull);
  });
  test('request stays unauthenticated and local resend is throttled', () async {
    await recovery.sendCode(' person@example.test ');
    expect(recovery.email, 'person@example.test');
    expect(recovery.step, RecoveryStep.code);
    await recovery.sendCode(recovery.email);
    expect(gateway.requests, 1);
    expect(gateway.updates, 0);
    expect(recovery.resendSeconds, greaterThan(0));
  });
  test(
    'an invalid or expired code never reaches password replacement',
    () async {
      await recovery.sendCode(recovery.email);
      gateway.badCode = true;
      await recovery.verifyCode('123456');
      await recovery.savePassword(
        'very-long-new-password',
        'very-long-new-password',
      );
      expect(recovery.step, RecoveryStep.code);
      expect(gateway.updates, 0);
      expect(recovery.error, contains('no es válido'));
    },
  );
  test('short or mismatching passwords never reach the server', () async {
    await verified();
    await recovery.savePassword('short', 'short');
    await recovery.savePassword('long-enough-password', 'different-password');
    expect(gateway.updates, 0);
    expect(recovery.step, RecoveryStep.password);
  });
  test(
    'success closes all refresh sessions and requires login again',
    () async {
      await verified();
      await recovery.savePassword(
        'long-enough-password',
        'long-enough-password',
      );
      expect(gateway.updates, 1);
      expect(gateway.lastCloseAll, isTrue);
      expect(recovery.active, isFalse);
      expect(recovery.step, RecoveryStep.complete);
    },
  );
  test('an account switch cannot complete recovery', () async {
    await verified();
    gateway.changedAccount = true;
    await recovery.savePassword('long-enough-password', 'long-enough-password');
    expect(gateway.updates, 0);
    expect(recovery.active, isTrue);
    expect(recovery.step, RecoveryStep.password);
    expect(recovery.error, isNotNull);
  });
  test('failed sign-out retry does not change the password twice', () async {
    await verified();
    gateway.closeFails = true;
    await recovery.savePassword('long-enough-password', 'long-enough-password');
    expect(gateway.updates, 1);
    expect(recovery.active, isTrue);
    gateway.closeFails = false;
    await recovery.savePassword('', '');
    expect(gateway.updates, 1);
    expect(recovery.step, RecoveryStep.complete);
  });
  test('cancel cannot race an in-flight code verification', () async {
    await recovery.sendCode(recovery.email);
    gateway.pendingVerify = Completer<String>();
    final pending = recovery.verifyCode('123456');
    expect(await recovery.cancel(), isFalse);
    gateway.pendingVerify!.complete('recovery-user');
    await pending;
    expect(recovery.step, RecoveryStep.password);
    expect(await recovery.cancel(), isTrue);
    expect(gateway.lastCloseAll, isFalse);
    expect(recovery.active, isFalse);
  });
  testWidgets('recovery UI does not promise that an account exists', (
    tester,
  ) async {
    await recovery.sendCode(recovery.email);
    await tester.pumpWidget(
      MaterialApp(
        home: PasswordRecoveryScreen(recovery: recovery, onExit: () {}),
      ),
    );
    expect(find.textContaining('Si existe una cuenta'), findsOneWidget);
    expect(find.text('Código del correo'), findsOneWidget);
    expect(find.text('Guardar contraseña'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
