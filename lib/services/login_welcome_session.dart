import 'package:shared_preferences/shared_preferences.dart';

/// Completion survives sign-out and app restarts, independently for each account.
class LoginWelcomeSession {
  static final instance = LoginWelcomeSession();
  final Set<String> _completed = {};
  SharedPreferences? _preferences;
  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
    _completed.addAll(_preferences!.getStringList('nido_welcome_completed_accounts') ?? []);
  }

  bool needsWelcome(String userId) => !_completed.contains(userId);
  Future<void> complete(String userId) async {
    _completed.add(userId);
    await _preferences?.setStringList('nido_welcome_completed_accounts', _completed.toList());
  }
  void reset() {} // Signing out must never erase onboarding completion.
}
