import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

enum RecoveryStep { email, code, password, complete }

abstract interface class RecoveryGateway {
  Future<void> request(String email);
  Future<String> verify(String email, String code);
  Future<void> replacePassword(String verifiedUserId, String password);
  Future<void> closeSession({required bool allSessions});
}

class SupabaseRecoveryGateway implements RecoveryGateway {
  SupabaseClient get _client => SupabaseService.instance.client;

  @override
  Future<void> request(String email) =>
      _client.auth.resetPasswordForEmail(email);

  @override
  Future<String> verify(String email, String code) async {
    final response = await _client.auth.verifyOTP(
      email: email,
      token: code,
      type: OtpType.recovery,
    );
    if (response.session == null || response.user == null) {
      throw const AuthException('Recovery session missing');
    }
    return response.user!.id;
  }

  @override
  Future<void> replacePassword(String verifiedUserId, String password) async {
    // Never reuse a recovery grant after an account/session switch.
    if (_client.auth.currentSession == null ||
        _client.auth.currentUser?.id != verifiedUserId) {
      throw const AuthException('Recovery session expired');
    }
    await _client.auth.updateUser(UserAttributes(password: password));
  }

  @override
  Future<void> closeSession({required bool allSessions}) => SupabaseService
      .instance
      .signOut(scope: allSessions ? SignOutScope.global : SignOutScope.local);
}

/// Client navigation state only. Supabase verifies the code and authorizes
/// password changes; no token, code or password is persisted by this controller.
class PasswordRecovery extends ChangeNotifier {
  PasswordRecovery(this._gateway);
  final RecoveryGateway _gateway;
  static final instance = PasswordRecovery(SupabaseRecoveryGateway());

  RecoveryStep step = RecoveryStep.email;
  String email = '';
  String? error;
  bool busy = false;
  bool active = false;
  String? _verifiedUserId;
  bool _passwordWasChanged = false;
  DateTime? _lastRequest;

  int get resendSeconds {
    final sent = _lastRequest;
    if (sent == null) return 0;
    return (60 - DateTime.now().difference(sent).inSeconds).clamp(0, 60);
  }

  void begin([String initialEmail = '']) {
    if (busy || active) return;
    email = initialEmail.trim();
    step = RecoveryStep.email;
    error = null;
    _verifiedUserId = null;
    _passwordWasChanged = false;
    active = true;
    notifyListeners();
  }

  void handleAuthState(AuthState state) {
    if (state.event == AuthChangeEvent.passwordRecovery &&
        state.session != null) {
      active = true;
      email = state.session!.user.email ?? email;
      _verifiedUserId = state.session!.user.id;
      step = RecoveryStep.password;
      error = null;
      notifyListeners();
    } else if (state.event == AuthChangeEvent.signedOut &&
        active &&
        !busy &&
        _verifiedUserId != null) {
      _verifiedUserId = null;
      step = RecoveryStep.code;
      error = 'La sesión venció. Solicita un código nuevo.';
      notifyListeners();
    }
  }

  Future<void> sendCode(String value) async {
    if (busy || !active || resendSeconds > 0) return;
    final candidate = value.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(candidate)) {
      error = 'Escribe un correo válido.';
      notifyListeners();
      return;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      await _gateway.request(candidate);
      email = candidate;
      _lastRequest = DateTime.now();
      _verifiedUserId = null;
      step = RecoveryStep.code;
    } catch (_) {
      error = 'No pudimos solicitar el correo. Espera e inténtalo de nuevo.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> verifyCode(String value) async {
    if (busy || !active || step != RecoveryStep.code) return;
    final code = value.trim();
    if (!RegExp(r'^\d{6,10}$').hasMatch(code)) {
      error = 'Escribe el código numérico de tu correo.';
      notifyListeners();
      return;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      _verifiedUserId = await _gateway.verify(email, code);
      step = RecoveryStep.password;
    } catch (_) {
      _verifiedUserId = null;
      step = RecoveryStep.code;
      error =
          'El código no es válido o ya venció. Solicita otro si lo necesitas.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> savePassword(String password, String confirmation) async {
    if (busy ||
        !active ||
        step != RecoveryStep.password ||
        _verifiedUserId == null) {
      return;
    }
    if (!_passwordWasChanged && password.length < 12) {
      error = 'Usa una contraseña de al menos 12 caracteres.';
      notifyListeners();
      return;
    }
    if (!_passwordWasChanged && password != confirmation) {
      error = 'Las contraseñas no coinciden.';
      notifyListeners();
      return;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      if (!_passwordWasChanged) {
        await _gateway.replacePassword(_verifiedUserId!, password);
        _passwordWasChanged = true;
      }
      // Revoke refresh sessions after recovery, then require a new login.
      // An already issued access token can remain valid until its expiry.
      await _gateway.closeSession(allSessions: true);
      _verifiedUserId = null;
      step = RecoveryStep.complete;
      active = false;
    } catch (_) {
      error = _passwordWasChanged
          ? 'La contraseña cambió. Reintenta para terminar el cierre de sesión.'
          : 'No pudimos cambiar la contraseña. Si la sesión venció, solicita otro código.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> cancel() async {
    if (busy) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      if (_verifiedUserId != null) {
        await _gateway.closeSession(allSessions: _passwordWasChanged);
      }
      _verifiedUserId = null;
      _passwordWasChanged = false;
      active = false;
      step = RecoveryStep.email;
      return true;
    } catch (_) {
      error = 'No pudimos cerrar esta sesión. Inténtalo de nuevo.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
