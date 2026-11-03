import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/inventory_service.dart';
import '../services/shared_pet_service.dart';
import '../services/profile_change_notifier.dart';

class SharedWalletSettings extends StatefulWidget {
  final VoidCallback onUnlinked;
  const SharedWalletSettings({super.key, required this.onUnlinked});
  @override
  State<SharedWalletSettings> createState() => _SharedWalletSettingsState();
}

class _SharedWalletSettingsState extends State<SharedWalletSettings> {
  bool busy = false;
  Future<void> separate() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final db = SupabaseService.instance.client;
      final value = Map<String, dynamic>.from(
        await db.rpc('wallet_snapshot') as Map,
      );
      if (!mounted || value['shared'] != true) return;
      if (value['separation_policy'] != 'half_v1') {
        throw StateError('El reparto seguro todavía no está disponible');
      }
      final total = (value['coins'] as num).toInt();
      final ownShare = (value['separation_own_share'] as num).toInt();
      final partnerShare = (value['separation_partner_share'] as num).toInt();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Separar nuestros Nidos'),
          content: Text(
            'Tienen $total de oro compartido. Tú conservarás $ownShare y la otra persona $partnerShare. El oro se reparte por mitades, sin perder monedas. Si el total es impar, una persona conserva una moneda adicional.\n\nLos objetos no se duplican. ¿Quieres separar las cuentas con este reparto?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Conservar el Nido'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Separar y aplicar reparto'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await db.rpc(
        'wallet_unlink',
        params: {'p_expected_balance': total, 'p_confirm': true},
      );
      // The transaction has committed. A connection failure while refreshing
      // must not invite the user to repeat a completed separation.
      await Future.wait([
        InventoryService.instance.refresh().catchError((_) {}),
        SharedPetService.instance.refresh().catchError((_) {}),
      ]);
      ProfileChangeNotifier.instance.notify();
      widget.onUnlinked();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se completó la separación. Revisa el saldo y vuelve a intentar.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: busy ? null : separate,
    icon: const Icon(Icons.link_off_rounded),
    label: Text(busy ? 'Consultando saldo…' : 'Separar nuestros Nidos'),
  );
}
