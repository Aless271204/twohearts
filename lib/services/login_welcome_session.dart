/// A welcome belongs to the current signed-in session, independently of adoption.
/// Token refreshes and returning from a minigame must not restart it.
class LoginWelcomeSession {
  static final instance = LoginWelcomeSession();
  String? _completedUser;

  bool needsWelcome(String userId) => _completedUser != userId;
  void complete(String userId) => _completedUser = userId;
  void reset() => _completedUser = null;
}
