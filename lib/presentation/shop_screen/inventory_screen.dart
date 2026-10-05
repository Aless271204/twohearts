import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/inventory_service.dart';
import '../../widgets/inventory_scene.dart';
import '../../widgets/pet_3d_viewer.dart';
import '../../core/pet_model_catalog.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final inventory = InventoryService.instance;
  bool loading = true, busy = false, onlyOwned = false;
  String scope = 'pet', query = '';
  String? error;
  @override
  void initState() {
    super.initState();
    inventory.addListener(_changed);
    _load();
  }

  @override
  void dispose() {
    inventory.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    try {
      await inventory.refresh();
      if (mounted) {
        setState(() {
          loading = false;
          error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          error =
              'No pudimos abrir tu inventario. Comprueba tu conexión e inicia sesión.';
        });
      }
    }
  }

  Future<void> _action(InventoryItem item) async {
    if (busy) return;
    if (!inventory.owns(item.key)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Adquirir ${item.name}'),
          content: Text(
            '${item.description}\n\n${item.price} LoveCoins · Saldo ${inventory.coins}\nEl objeto queda en tu cuenta y puedes equiparlo cuando quieras.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: inventory.coins >= item.price
                  ? () => Navigator.pop(context, true)
                  : null,
              child: const Text('Comprar'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() => busy = true);
    try {
      if (!inventory.owns(item.key)) {
        await inventory.purchase(item);
      } else {
        await inventory.equip(item, !inventory.equipped(item.key));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is PostgrestException
                  ? e.message
                  : 'No se guardó el cambio. Reintenta cuando tengas conexión.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = inventory.catalog
        .where(
          (i) =>
              i.scope == scope &&
              (!onlyOwned || inventory.owns(i.key)) &&
              (query.isEmpty ||
                  '${i.name} ${i.collection} ${i.description}'
                      .toLowerCase()
                      .contains(query.toLowerCase())),
        )
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('Tienda e inventario'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '🪙 ${inventory.coins}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(error!, textAlign: TextAlign.center),
                  ),
                  FilledButton(
                    onPressed: _load,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Catálogo')),
                      ButtonSegment(value: true, label: Text('Mis objetos')),
                    ],
                    selected: {onlyOwned},
                    onSelectionChanged: (s) =>
                        setState(() => onlyOwned = s.first),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final e in InventoryItem.destinations.entries)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(e.value),
                              selected: scope == e.key,
                              onSelected: (_) => setState(() => scope = e.key),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  InventoryPreview(scope: scope, loadout: inventory.loadout),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (s) => setState(() => query = s),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Buscar objeto o colección',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Gana LoveCoins jugando. Cada compra es permanente; cambiar o quitar un objeto es gratis. Los estilos conservan las mismas reglas de juego.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  if (busy) const LinearProgressIndicator(),
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Todavía no hay objetos aquí. Encuentra tu favorito en el catálogo.',
                      ),
                    ),
                  for (final item in items)
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 7),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: item.color.withAlpha(60),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    item.emoji,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${item.rarity} · ${item.collection}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(item.description),
                            const SizedBox(height: 5),
                            Text(
                              'Se equipa en: ${InventoryItem.destinations[item.scope]} / ${InventoryItem.slots[item.slot]}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    inventory.equipped(item.key)
                                        ? '✓ Equipado'
                                        : inventory.owns(item.key)
                                        ? '✓ En tu inventario'
                                        : '🪙 ${item.price} LoveCoins',
                                  ),
                                ),
                                FilledButton.tonal(
                                  onPressed: busy ? null : () => _action(item),
                                  child: Text(
                                    inventory.equipped(item.key)
                                        ? 'Quitar'
                                        : inventory.owns(item.key)
                                        ? 'Equipar'
                                        : 'Comprar',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}

class InventoryPreview extends StatelessWidget {
  final String scope;
  final Map<String, InventoryItem> loadout;
  const InventoryPreview({
    super.key,
    required this.scope,
    required this.loadout,
  });
  @override
  Widget build(BuildContext context) {
    if (scope == 'pet' || scope == 'room') {
      return Container(
        height: 210,
        decoration: BoxDecoration(
          color: const Color(0xFFF3EBDD),
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(child: InventoryScene(loadout: loadout)),
            const Positioned.fill(
              child: Pet3DViewer(
                modelPath: PetModelCatalog.penguinModelPath,
                animationName: 'Idle_9',
                autoPlay: true,
                cameraControls: false,
                cameraOrbit: '0deg 75deg 105%',
              ),
            ),
            if (scope == 'pet')
              Positioned.fill(
                child: InventoryScene(loadout: loadout, accessories: true),
              ),
            const Positioned(
              bottom: 8,
              left: 12,
              child: Text(
                'Vista de tus objetos equipados',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
      );
    }
    if (scope == 'pong') {
      return Container(
        height: 180,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF090E1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: loadout['pong_court']?.color ?? const Color(0xFFE2A4C9),
            width: 3,
          ),
        ),
        child: Column(
          children: [
            Container(width: 85, height: 10, color: const Color(0xFFF09972)),
            Expanded(
              child: Center(
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: loadout['pong_ball']?.color ?? Colors.pink,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Container(
              width: 85,
              height: 10,
              color: loadout['pong_paddle']?.color ?? Colors.blue,
            ),
            const SizedBox(height: 12),
            const Text(
              'Tu paleta, pelota y cancha',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            loadout['quiz_table']?.color.withAlpha(90) ??
            const Color(0xFFF3E3F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            '${loadout['quiz_badge']?.emoji ?? '💌'} ¿Cuál es mi destino soñado?',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          for (final answer in ['Inglaterra', 'Francia', 'Japón'])
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 7),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: loadout['quiz_card']?.color ?? Colors.pink.shade100,
                ),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(answer),
            ),
        ],
      ),
    );
  }
}
