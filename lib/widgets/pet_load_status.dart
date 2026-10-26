import 'dart:async';
import 'package:flutter/material.dart';

/// A failed request must offer recovery instead of an endless loading spinner.
class PetLoadStatus extends StatefulWidget {
  final String? message;
  final VoidCallback onRetry;
  const PetLoadStatus({super.key, this.message, required this.onRetry});

  @override
  State<PetLoadStatus> createState() => _PetLoadStatusState();
}

class _PetLoadStatusState extends State<PetLoadStatus> {
  Timer? _timer;
  bool _timedOut = false;

  void _startTimer() {
    _timer?.cancel();
    if (widget.message == null) {
      _timer = Timer(const Duration(seconds: 20), () {
        if (mounted) setState(() => _timedOut = true);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant PetLoadStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) {
      _timedOut = false;
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _retry() {
    setState(() => _timedOut = false);
    _startTimer();
    widget.onRetry();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: widget.message == null && !_timedOut
          ? const CircularProgressIndicator()
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pets_rounded, size: 48),
                const SizedBox(height: 16),
                Text(
                  widget.message ??
                      'La carga está tardando más de lo esperado. Puedes volver a intentarlo.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Volver a cargar'),
                ),
              ],
            ),
    ),
  );
}
