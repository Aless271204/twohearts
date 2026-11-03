import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/password_recovery.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({
    super.key,
    required this.recovery,
    required this.onExit,
  });
  final PasswordRecovery recovery;
  final VoidCallback onExit;

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  Timer? _timer;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _email.text = widget.recovery.email;
    if (!widget.recovery.active && widget.recovery.step == RecoveryStep.email) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.recovery.begin(_email.text);
      });
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.recovery.step == RecoveryStep.code) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in [_email, _code, _password, _confirmation]) {
      controller.clear();
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _exit() async {
    if (await widget.recovery.cancel() && mounted) widget.onExit();
  }

  Future<void> _save() async {
    await widget.recovery.savePassword(_password.text, _confirmation.text);
    if (!mounted) return;
    // Do not leave entered credentials in controllers after an attempt.
    _password.clear();
    _confirmation.clear();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.recovery,
    builder: (context, _) {
      final state = widget.recovery;
      final complete = state.step == RecoveryStep.complete;
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && !state.busy) _exit();
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFFFF7F9),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFFF7F9),
            title: const Text('Volver a tu Nido'),
            leading: IconButton(
              tooltip: 'Volver a iniciar sesión',
              onPressed: state.busy ? null : _exit,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.lock_rounded,
                          size: 52,
                          color: Color(0xFFB82C59),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          complete
                              ? 'Tu contraseña está lista'
                              : 'Recupera tu cuenta',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        if (state.step == RecoveryStep.email) ...[
                          const Text(
                            'Te enviaremos un código para comprobar que el correo es tuyo. No compartas ese código con nadie.',
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _email,
                            enabled: !state.busy,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'Correo de tu cuenta',
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: state.busy
                                ? null
                                : () => state.sendCode(_email.text),
                            child: const Text('Enviar código'),
                          ),
                        ],
                        if (state.step == RecoveryStep.code) ...[
                          const Text(
                            'Si existe una cuenta con ese correo, recibirás un código. Revisa también la carpeta de spam.',
                          ),
                          const SizedBox(height: 8),
                          Text(state.email, textAlign: TextAlign.center),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _code,
                            enabled: !state.busy,
                            keyboardType: TextInputType.number,
                            autofillHints: const [AutofillHints.oneTimeCode],
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            maxLength: 10,
                            decoration: const InputDecoration(
                              labelText: 'Código del correo',
                            ),
                          ),
                          FilledButton(
                            onPressed: state.busy
                                ? null
                                : () async {
                                    await state.verifyCode(_code.text);
                                    _code.clear();
                                  },
                            child: const Text('Comprobar código'),
                          ),
                          TextButton(
                            onPressed: state.busy || state.resendSeconds > 0
                                ? null
                                : () => state.sendCode(state.email),
                            child: Text(
                              state.resendSeconds > 0
                                  ? 'Reenviar en ${state.resendSeconds} s'
                                  : 'Reenviar código',
                            ),
                          ),
                        ],
                        if (state.step == RecoveryStep.password) ...[
                          const Text(
                            'Elige una contraseña exclusiva de al menos 12 caracteres. Tendrás que iniciar sesión nuevamente.',
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _password,
                            enabled: !state.busy,
                            obscureText: _obscure,
                            autocorrect: false,
                            enableSuggestions: false,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: InputDecoration(
                              labelText: 'Nueva contraseña',
                              suffixIcon: IconButton(
                                tooltip: _obscure
                                    ? 'Mostrar contraseña'
                                    : 'Ocultar contraseña',
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _confirmation,
                            enabled: !state.busy,
                            obscureText: true,
                            autocorrect: false,
                            enableSuggestions: false,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: const InputDecoration(
                              labelText: 'Repite la contraseña',
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: state.busy ? null : _save,
                            child: const Text('Guardar contraseña'),
                          ),
                        ],
                        if (complete) ...[
                          const Text(
                            'Ya puedes entrar con tu nueva contraseña.',
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: widget.onExit,
                            child: const Text('Ir a iniciar sesión'),
                          ),
                        ],
                        if (state.busy) ...[
                          const SizedBox(height: 18),
                          const Center(child: CircularProgressIndicator()),
                        ],
                        if (state.error != null) ...[
                          const SizedBox(height: 18),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              state.error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
