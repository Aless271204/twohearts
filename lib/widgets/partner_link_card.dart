import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_routes.dart';

/// Shared entry to the existing authenticated account-linking flow.
class PartnerLinkCard extends StatelessWidget {
  const PartnerLinkCard({super.key, this.onOpen});
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFFFFF1F4),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: const Icon(Icons.favorite_outline, color: Color(0xFFF05280)),
      title: const Text(
        'Código de pareja',
        style: TextStyle(color: Color(0xFF242129), fontWeight: FontWeight.w700),
      ),
      subtitle: const Text(
        'Ver y copiar mi código · Enlazar cuentas',
        style: TextStyle(color: Color(0xFF625761)),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF625761)),
      onTap: onOpen ?? () => context.push(AppRoutes.pairingScreen),
    ),
  );
}
