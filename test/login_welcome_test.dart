import 'package:flutter_test/flutter_test.dart';
import 'package:twohearts/services/login_welcome_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('welcome survives restart and sign out and is separate per account', () async {
    SharedPreferences.setMockInitialValues({});
    final session = LoginWelcomeSession();
    await session.initialize();
    expect(session.needsWelcome('account-a'), isTrue);
    await session.complete('account-a');
    expect(session.needsWelcome('account-a'), isFalse);
    expect(session.needsWelcome('account-b'), isTrue);
    session.reset();
    expect(session.needsWelcome('account-a'), isFalse);
    final restarted = LoginWelcomeSession();
    await restarted.initialize();
    expect(restarted.needsWelcome('account-a'), isFalse);
    expect(restarted.needsWelcome('account-b'), isTrue);
  });
}
