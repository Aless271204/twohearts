import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/inventory_service.dart';
import '../../widgets/inventory_scene.dart';
import '../../widgets/pet_3d_viewer.dart';
import '../../core/pet_model_catalog.dart';
import '../../services/shared_pet_service.dart';
import '../../widgets/scene_status.dart';
import '../../widgets/rose_ui.dart';
import '../../theme/app_theme.dart';

class ShopScreen extends StatefulWidget {
  final String initialScope;
  const ShopScreen({super.key, this.initialScope = 'pet'});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final inventory = InventoryService.instance;
  bool loading = true, busy = false, onlyOwned = false;
  String scope = 'pet', query = '';
  String? error;
  String? slot;
  InventoryItem? preview;
  bool showPreview = false;
  bool showCoins = false;
  @override
  void initState() {
    super.initState();
    scope = widget.initialScope;
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

  Future<void> _viewItem(InventoryItem item) async {
    await showModalBottomSheet<void>(context: context, useRootNavigator: true, isScrollControlled: true, showDragHandle: true, builder: (context) => SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        InventoryPreview(scope: item.scope, loadout: {...inventory.loadout, item.slot: item}),
        const SizedBox(height: 12), Text(item.description),
        const SizedBox(height: 8), Text('Vista real del objeto · ${InventoryItem.slots[item.slot] ?? item.slot}'),
        const SizedBox(height: 16),
        FilledButton(onPressed: busy ? null : () { Navigator.pop(context); _action(item); }, child: Text(inventory.equipped(item.key) ? 'Quitar' : inventory.owns(item.key) ? 'Equipar' : 'Comprar por ${item.price} LoveCoins')),
      ]),
    )));
  }

  @override
  Widget build(BuildContext context) {
    final items = inventory.catalog.where((i) => i.scope == scope && (slot == null || i.slot == slot) && (!onlyOwned || inventory.owns(i.key)) && (query.isEmpty || '${i.name} ${i.collection} ${i.description}'.toLowerCase().contains(query.toLowerCase()))).toList();
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(title: const Text('Tienda e inventario'), actions: [TextButton.icon(onPressed: () => setState(() => showCoins = true), icon: const Icon(Icons.monetization_on_rounded, color: Color(0xFFD49B23)), label: Text('${inventory.coins}'))]),
      body: AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: loading
        ? const RoseLoading(key: ValueKey('loading'), label: 'Preparamos tu colección…')
        : error != null
          ? SceneStatus(key: const ValueKey('error'), title: 'Tu colección', message: error!, loading: false, onRetry: _load)
          : RefreshIndicator(key: const ValueKey('catalog'), onRefresh: _load, child: ListView(padding: const EdgeInsets.all(20), children: [
            SegmentedButton<bool>(showSelectedIcon: false, segments: const [ButtonSegment(value: false, label: Text('Catálogo')), ButtonSegment(value: true, label: Text('Mis objetos'))], selected: {onlyOwned}, onSelectionChanged: (v) => setState(() { onlyOwned = v.first; showCoins = false; })),
            const SizedBox(height: 12),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
              for (final e in InventoryItem.destinations.entries) Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(showCheckmark: false, label: Text(e.value), selected: !showCoins && scope == e.key, onSelected: (_) => setState(() { scope = e.key; slot = null; showCoins = false; preview = null; }))),
              ChoiceChip(showCheckmark: false, label: const Text('Comprar monedas'), selected: showCoins, onSelected: (_) => setState(() => showCoins = true)),
            ])),
            const SizedBox(height: 16),
            if (showCoins) _coinsPanel() else ...[
              TextField(onChanged: (v) => setState(() => query = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Buscar objeto o colección')),
              const SizedBox(height: 12),
              SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
                ChoiceChip(showCheckmark: false, label: const Text('Todo'), selected: slot == null, onSelected: (_) => setState(() => slot = null)),
                for (final e in InventoryItem.slots.entries.where((e) => e.key.startsWith('${scope}_'))) Padding(padding: const EdgeInsets.only(left: 6), child: ChoiceChip(showCheckmark: false, label: Text(e.value), selected: slot == e.key, onSelected: (_) => setState(() => slot = e.key))),
              ])),
              const SizedBox(height: 16),
              if (busy) const Padding(padding: EdgeInsets.only(bottom: 12), child: LinearProgressIndicator()),
              if (items.isEmpty) const SceneStatus(title: 'Un lugar para tus favoritos', message: 'No hay objetos con estos filtros. Prueba otra categoría.', loading: false),
              LayoutBuilder(builder: (context, constraints) => Wrap(spacing: 12, runSpacing: 12, children: [for (final item in items) SizedBox(width: (constraints.maxWidth - 12) / 2, child: _productCard(item))])),
              const SizedBox(height: 20),
              const Text('Cada objeto se prueba sobre tu mascota o habitación antes de comprarlo. Las compras con LoveCoins se conservan en tu inventario.', style: TextStyle(fontSize: 12, color: Color(0xFF716B78))),
            ],
            const SizedBox(height: 20),
          ])),
      ),
    );
  }

  Widget _coinsPanel() => RoseEntrance(child: Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Icon(Icons.monetization_on_rounded, size: 54, color: Color(0xFFD49B23)),
    const SizedBox(height: 16), const Text('Comprar LoveCoins', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
    const SizedBox(height: 8), Text('Tu saldo: ${inventory.coins} LoveCoins'),
    const SizedBox(height: 12), const Text('Aquí podrás elegir paquetes de monedas para personalizar tu mascota y su habitación. Estamos preparando los paquetes y precios.'),
    const SizedBox(height: 20), const FilledButton(onPressed: null, child: Text('Próximamente')),
    const SizedBox(height: 12), const Text('Por ahora puedes ganar monedas jugando.', style: TextStyle(color: Color(0xFF716B78))),
  ]))));

  Widget _productCard(InventoryItem item) {
    int? panel;
    if (item.slot == 'pet_head' && item.style == 'bow') panel = 0;
    if (item.slot == 'pet_eyes') panel = 1;
    if (item.slot == 'room_bed') panel = 2;
    if (item.slot == 'room_plant') panel = 3;
    if (item.slot == 'pet_head' && item.style == 'cap') panel = 4;
    if (item.slot == 'pet_body') panel = 5;
    return Card(clipBehavior: Clip.antiAlias, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(borderRadius: BorderRadius.circular(16), child: SizedBox(height: 120, width: double.infinity, child: panel != null ? ProductArt(panel: panel) : ColoredBox(color: item.color.withAlpha(40), child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 44)))))),
      const SizedBox(height: 12), Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4), Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF716B78))),
      const SizedBox(height: 8), Text(inventory.equipped(item.key) ? '✓ Equipado' : inventory.owns(item.key) ? '✓ En tu inventario' : '🪙 ${item.price}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8), SizedBox(width: double.infinity, child: FilledButton(onPressed: busy ? null : () => _viewItem(item), child: const Text('Ver'))),
    ])));
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
            Positioned.fill(
              child: Pet3DViewer(
                previewLoadout: loadout,
                modelPath: PetModelCatalog.modelPathFor(SharedPetService.instance.species),
                petLevel: SharedPetService.instance.level,
                animationName: 'Natural_Rest',
                autoPlay: true,
                cameraControls: false,
                cameraOrbit: '0deg 75deg 105%',
              ),
            ),
            const Positioned(
              bottom: 8,
              left: 12,
              child: Text(
                'Vista previa · Sin guardar',
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
