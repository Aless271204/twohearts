import 'package:flutter/material.dart';

/// A failed request must offer recovery instead of an endless loading spinner.
class PetLoadStatus extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  const PetLoadStatus({super.key, this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: message == null
          ? const CircularProgressIndicator()
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pets_rounded, size: 48),
                const SizedBox(height: 16),
                Text(message!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Volver a cargar'),
                ),
              ],
            ),
    ),
  );
}
