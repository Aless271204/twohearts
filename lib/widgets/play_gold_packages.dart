import 'package:flutter/material.dart';
import '../core/store_packages.dart';
import '../services/play_billing_service.dart';
import 'twohearts_ui.dart';

class PlayGoldPackages extends StatelessWidget {
  final bool previewMode;
  const PlayGoldPackages({super.key, this.previewMode = false});
  @override
  Widget build(BuildContext context) {
    final billing = PlayBillingService.instance;
    return ListenableBuilder(
      listenable: billing,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final pack in storePackages)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pack.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${pack.gold} monedas de oro',
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(pack.description),
                    const SizedBox(height: 12),
                    HeartButton(
                      label: billing.products.containsKey(pack.id)
                          ? 'Comprar · ${billing.products[pack.id]!.price}'
                          : '${pack.price} · Próximamente',
                      onPressed:
                          !previewMode &&
                              billing.ready &&
                              !billing.busy &&
                              billing.products.containsKey(pack.id)
                          ? () => billing.buy(pack.id)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          if (billing.message != null && !previewMode)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(billing.message!),
            ),
          if (billing.supported && !previewMode)
            TextButton.icon(
              onPressed: billing.loading || billing.busy ? null : billing.retry,
              icon: const Icon(Icons.refresh),
              label: Text(
                billing.loading
                    ? 'Conectando…'
                    : 'Reintentar compras pendientes',
              ),
            ),
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Google Play muestra el precio final en tu moneda antes de confirmar. El oro es una moneda virtual para usar en Nido.',
            ),
          ),
        ],
      ),
    );
  }
}
