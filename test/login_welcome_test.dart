import 'package:flutter_test/flutter_test.dart';
import 'package:twohearts/services/login_welcome_session.dart';

void main() {
  test('welcome is per login; refreshes and adoption do not restart it', () {
    final session = LoginWelcomeSession();
    expect(session.needsWelcome('account-a'), isTrue);
    session.complete('account-a');
    expect(session.needsWelcome('account-a'), isFalse);
    expect(session.needsWelcome('account-b'), isTrue);
    session.reset();
    expect(session.needsWelcome('account-a'), isTrue);
  });
}
