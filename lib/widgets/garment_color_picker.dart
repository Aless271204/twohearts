import 'package:flutter/material.dart';
import '../core/store_economy.dart';
import '../services/inventory_service.dart';
import 'twohearts_ui.dart';

class GarmentColorPicker extends StatelessWidget {
  final InventoryItem item;
  final String selected;
  final ValueChanged<String> onPreview;
  final bool previewMode;
  const GarmentColorPicker({
    super.key,
    required this.item,
    required this.selected,
    required this.onPreview,
    this.previewMode = false,
  });
  @override
  Widget build(BuildContext context) {
    final inventory = InventoryService.instance;
    final unlocked =
        selected == 'original' ||
        (inventory.colorUnlocks[item.key]?.contains(selected) ?? false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Dale tu color',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Original'),
              selected: selected == 'original',
              onSelected: (_) => onPreview('original'),
            ),
            for (final entry in StoreEconomy.colors.entries)
              ChoiceChip(
                avatar: CircleAvatar(
                  radius: 9,
                  backgroundColor: InventoryItem.parseColor(entry.value),
                ),
                label: Text(StoreEconomy.colorNames[entry.key]!),
                selected: selected == entry.key,
                onSelected: (_) => onPreview(entry.key),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Vista previa gratuita. Cada nuevo color cuesta 10 de oro una sola vez por prenda; después puedes volver a usarlo.',
          style: TextStyle(fontSize: 12, color: Color(0xFF716B78)),
        ),
        if (inventory.owns(item.key) && !item.previewOnly)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: HeartButton(
              label: unlocked
                  ? 'Usar este color'
                  : 'Desbloquear color · ${StoreEconomy.colorPrice} oro',
              onPressed: previewMode
                  ? null
                  : () async {
                      if (!unlocked) {
                        final accepted = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Un nuevo color'),
                            content: Text(
                              '${StoreEconomy.colorNames[selected]} para ${item.name}: ${StoreEconomy.colorPrice} de oro. Se guarda en tu cofre.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Volver'),
                              ),
                              FilledButton(
                                onPressed:
                                    inventory.coins >= StoreEconomy.colorPrice
                                    ? () => Navigator.pop(context, true)
                                    : null,
                                child: const Text('Desbloquear'),
                              ),
                            ],
                          ),
                        );
                        if (accepted != true) return;
                      }
                      try {
                        await inventory.selectColor(item, selected);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Color guardado')),
                          );
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'No pudimos guardar el color. Revisa tu saldo y conexión.',
                              ),
                            ),
                          );
                        }
                      }
                    },
            ),
          ),
        if (!inventory.owns(item.key))
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Adquiere primero la prenda para guardar un color.',
              style: TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }
}
