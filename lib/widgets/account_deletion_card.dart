import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

/// Records an authenticated request; never claims that erasure is immediate.
class AccountDeletionCard extends StatefulWidget {
  const AccountDeletionCard({super.key});
  @override
  State<AccountDeletionCard> createState() => _AccountDeletionCardState();
}

class _AccountDeletionCardState extends State<AccountDeletionCard> {
  bool _sending = false;
  bool _requested = false;
  Future<void> _request() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar eliminación de cuenta'),
        content: const Text(
          'Solicitaremos eliminar tu cuenta y los datos asociados. '
          'El equipo revisará la solicitud; enviarla no borra los datos de inmediato. '
          'La información compartida con otras personas requiere revisión para proteger sus datos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar solicitud'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _sending = true);
    try {
      await SupabaseService.instance.client.rpc('request_account_deletion');
      if (mounted) setState(() => _requested = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No pudimos enviar la solicitud. Inténtalo de nuevo.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu cuenta y tus datos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _requested
                ? 'Solicitud recibida. Queda pendiente de revisión.'
                : 'Puedes solicitar la eliminación de tu cuenta y de los datos asociados.',
          ),
          TextButton.icon(
            onPressed: _sending || _requested ? null : _request,
            icon: const Icon(Icons.person_remove_outlined),
            label: Text(
              _sending
                  ? 'Enviando…'
                  : _requested
                  ? 'Solicitud enviada'
                  : 'Solicitar eliminación',
            ),
          ),
        ],
      ),
    ),
  );
}
