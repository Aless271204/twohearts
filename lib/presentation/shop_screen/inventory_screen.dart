import '../../core/boutique_thumbnails.dart';
import '../../theme/app_theme.dart';
import '../../core/store_packages.dart';
import '../../core/store_economy.dart';
import '../../widgets/garment_color_picker.dart';
import '../../widgets/rewarded_gold_card.dart';
import '../../widgets/twohearts_ui.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/inventory_service.dart';
import '../../widgets/pet_3d_viewer.dart';
import '../../core/pet_model_catalog.dart';
import '../../services/shared_pet_service.dart';
import '../../widgets/scene_status.dart';
import '../../widgets/rose_ui.dart';
import '../../core/room_catalog.dart';

class ShopScreen extends StatefulWidget {
  final String initialScope;
  final bool previewMode;
  final bool initialOwned;
  final bool initialCoins;
  const ShopScreen({
    super.key,
    this.initialScope = 'pet',
    this.previewMode = false,
    this.initialOwned = false,
    this.initialCoins = false,
  });
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final inventory = InventoryService.instance;
  bool loading = true, busy = false, onlyOwned = false;
  String scope = 'pet', query = '';
  String? error;
  String? slot;
  String? roomCategory;
  String? rarity;
  String? collection;
  int page = 0;
  InventoryItem? preview;
  bool showPreview = false;
  bool showCoins = false;
  @override
  void initState() {
    super.initState();
    scope = widget.initialScope;
    onlyOwned = widget.initialOwned;
    showCoins = widget.initialCoins;
    inventory.addListener(_changed);
    SharedPetService.instance.addListener(_changed);
    _load();
  }

  @override
  void dispose() {
    inventory.removeListener(_changed);
    SharedPetService.instance.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    if (widget.previewMode) {
      setState(() => loading = false);
      return;
    }
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
    if (item.previewOnly) return;
    if (widget.previewMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vista de diseño · Las compras están desactivadas"),
        ),
      );
      return;
    }
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
    var colorKey =
        inventory.owned[item.key]?['color_key'] as String? ?? 'original';
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFF9FA),
      barrierColor: const Color(0x55756672),
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, updateColor) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                InventoryPreview(
                  scope: item.scope,
                  loadout: {
                    ...inventory.loadout,
                    item.slot: InventoryItem({
                      ...item.data,
                      'appearance': {
                        ...item.appearance,
                        'garment_color': colorKey == 'original'
                            ? null
                            : StoreEconomy.colors[colorKey],
                      },
                    }),
                  },
                ),
                const SizedBox(height: 12),
                Text(item.description),
                if (item.appearance['color_materials'] is List)
                  GarmentColorPicker(
                    item: item,
                    selected: colorKey,
                    previewMode: widget.previewMode,
                    onPreview: (key) => updateColor(() => colorKey = key),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Vista real del objeto · ${InventoryItem.slots[item.slot] ?? item.slot}',
                ),
                const SizedBox(height: 16),
                if (item.previewOnly && item.scope == 'room')
                  HeartButton(
                    label: 'Probar en mi habitación',
                    icon: Icons.home_outlined,
                    onPressed: () {
                      inventory.previewRoomItem(item);
                      Navigator.pop(context);
                    },
                  ),
                if (item.previewOnly && item.scope == 'room')
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Prueba temporal en este dispositivo. No compra el objeto ni modifica la habitación compartida.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF716B78)),
                    ),
                  ),
                if (!(item.previewOnly && item.scope == 'room'))
                  FilledButton(
                    onPressed: busy || item.previewOnly
                        ? null
                        : () {
                            Navigator.pop(context);
                            _action(item);
                          },
                    child: Text(
                      item.previewOnly
                          ? (item.price > 0
                                ? '${item.price} monedas · Próximamente'
                                : 'En preparación')
                          : inventory.equipped(item.key)
                          ? 'Quitar'
                          : inventory.owns(item.key)
                          ? 'Equipar'
                          : 'Comprar por ${item.price} LoveCoins',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _buyBundle(Map<String, dynamic> bundle) async {
    if (busy || widget.previewMode) return;
    setState(() => busy = true);
    try {
      final quote = await inventory.quoteBundle(bundle['bundle_key'] as String);
      if (!mounted || quote['missing_count'] == 0) return;
      final price = quote['price_coins'] as int;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(quote['name'] as String),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${quote['missing_count']} objetos · $price de oro'),
                const SizedBox(height: 8),
                Text(
                  '${quote['discount_percent']} % de descuento sobre los objetos que te faltan. Los que ya tienes no se cobran de nuevo.',
                ),
                const SizedBox(height: 12),
                for (final row in quote['items'] as List)
                  if (row['owned'] != true)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        '• ${InventoryItem.readableText(row['name'] as String)}',
                      ),
                    ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: inventory.coins >= price
                  ? () => Navigator.pop(context, true)
                  : null,
              child: Text('Comprar · $price'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await inventory.purchaseBundle(quote['bundle_key'] as String, price);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is PostgrestException
                  ? e.message
                  : 'No se pudo comprar el conjunto. Reintenta.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget _bundleOffers() {
    final offers = inventory.bundles.where((b) => b['scope'] == scope).toList();
    if (offers.isEmpty || onlyOwned) return const SizedBox.shrink();
    return Card(
      color: const Color(0xFFFFF0EA),
      elevation: 0,
      child: ExpansionTile(
        textColor: const Color(0xFF493B37),
        collapsedTextColor: const Color(0xFF493B37),
        title: const Text(
          'Conjuntos para combinar',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          scope == 'room'
              ? 'Ahorra un 25 % · solo pagas lo que te falta'
              : 'Ahorra un 10 % · solo pagas lo que te falta',
        ),
        children: [
          for (final bundle in offers)
            ListTile(
              leading: Image.asset(
                bundle['thumbnail_asset'] as String,
                width: 48,
                height: 48,
                fit: BoxFit.contain,
              ),
              title: Text(
                bundle['name'] as String,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                bundle['missing_count'] == 0
                    ? 'Ya tienes el conjunto completo'
                    : '${bundle['missing_count']} objetos · ${bundle['price_coins']} de oro',
              ),
              trailing: IconButton(
                tooltip: 'Ver conjunto',
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: busy || bundle['missing_count'] == 0
                    ? null
                    : () => _buyBundle(bundle),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = inventory.catalog
        .where(
          (i) =>
              (scope == 'interface'
                  ? !['pet', 'room'].contains(i.scope)
                  : i.scope == scope) &&
              (i.visible || onlyOwned) &&
              (scope != 'room' ||
                  roomCategory == null ||
                  i.roomCategory == roomCategory) &&
              (slot == null || i.slot == slot) &&
              (rarity == null || i.rarity == rarity) &&
              (scope != 'room' ||
                  collection == null ||
                  i.collection == collection) &&
              (!onlyOwned || inventory.owns(i.key)) &&
              (query.isEmpty ||
                  '${i.name} ${i.collection} ${i.description}'
                      .toLowerCase()
                      .contains(query.toLowerCase())),
        )
        .toList();
    if (scope == 'room') {
      items.sort((a, b) {
        final priority = (a.collection == 'Nuestro rincón' ? 0 : 1).compareTo(
          b.collection == 'Nuestro rincón' ? 0 : 1,
        );
        return priority != 0
            ? priority
            : inventory.catalog
                  .indexOf(a)
                  .compareTo(inventory.catalog.indexOf(b));
      });
    }
    final safePage = items.isEmpty
        ? 0
        : page.clamp(0, (items.length - 1) ~/ 16).toInt();
    final pageItems = items.skip(safePage * 16).take(16);
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FA),
      appBar: AppBar(
        toolbarHeight: 76,
        titleSpacing: 20,
        title: const Text(
          'Tienda',
          style: TextStyle(
            fontFamily: AppTheme.displayFont,
            fontSize: 29,
            color: AppTheme.ink,
            fontWeight: FontWeight.w700,
            letterSpacing: -.7,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: HeartButton(
              label: '${inventory.coins}',
              icon: Icons.monetization_on_rounded,
              outlined: true,
              onPressed: () => setState(() => showCoins = true),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: loading
            ? const RoseLoading(
                key: ValueKey('loading'),
                label: 'Preparamos tu colección…',
              )
            : error != null
            ? SceneStatus(
                key: const ValueKey('error'),
                title: 'Tu colección',
                message: error!,
                loading: false,
                onRetry: _load,
              )
            : RefreshIndicator(
                key: const ValueKey('catalog'),
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    SegmentedButton<bool>(
                      style: const ButtonStyle(
                        foregroundColor: WidgetStatePropertyAll(
                          Color(0xFF202027),
                        ),
                      ),
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: false, label: Text('Catálogo')),
                        ButtonSegment(value: true, label: Text('Mis objetos')),
                      ],
                      selected: {onlyOwned},
                      onSelectionChanged: (v) => setState(() {
                        onlyOwned = v.first;
                        showCoins = false;
                      }),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final e in const {
                            'pet': 'Mascota',
                            'room': 'Habitación',
                            'interface': 'Interfaz',
                          }.entries)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                labelStyle: const TextStyle(
                                  color: Color(0xFF202027),
                                ),
                                showCheckmark: false,
                                label: Text(e.value),
                                selected:
                                    !showCoins &&
                                    (scope == e.key ||
                                        (e.key == 'interface' &&
                                            !['pet', 'room'].contains(scope))),
                                onSelected: (_) => setState(() {
                                  scope = e.key;
                                  slot = null;
                                  showCoins = false;
                                  preview = null;
                                }),
                              ),
                            ),
                          ChoiceChip(
                            labelStyle: const TextStyle(
                              color: Color(0xFF202027),
                            ),
                            showCheckmark: false,
                            label: const Text('Comprar monedas'),
                            selected: showCoins,
                            onSelected: (_) => setState(() => showCoins = true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (showCoins)
                      _coinsPanel()
                    else ...[
                      _bundleOffers(),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final tier in [
                              'Todo',
                              ...StoreEconomy.rarities,
                            ])
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(tier),
                                  labelStyle: const TextStyle(
                                    color: Color(0xFF302B35),
                                  ),
                                  selected: (rarity ?? 'Todo') == tier,
                                  showCheckmark: false,
                                  onSelected: (_) => setState(
                                    () => rarity = tier == 'Todo' ? null : tier,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (scope == 'room') ...[
                        DropdownButtonFormField<String>(
                          initialValue: collection ?? '',
                          decoration: const InputDecoration(
                            labelText: 'Colección',
                          ),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('Todas las colecciones'),
                            ),
                            for (final name
                                in inventory.catalog
                                    .where(
                                      (i) => i.scope == 'room' && i.visible,
                                    )
                                    .map((i) => i.collection)
                                    .toSet())
                              DropdownMenuItem(
                                value: name,
                                child: Text(
                                  name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) => setState(() {
                            collection = value == '' ? null : value;
                            page = 0;
                          }),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final category in [
                                'Todo',
                                ...roomCategories,
                              ])
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: ChoiceChip(
                                    showCheckmark: false,
                                    label: Text(category),
                                    labelStyle: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF202027),
                                    ),
                                    selected:
                                        (roomCategory ?? 'Todo') == category,
                                    onSelected: (_) => setState(() {
                                      roomCategory = category == 'Todo'
                                          ? null
                                          : category;
                                      slot = null;
                                    }),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (inventory.roomDraft.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: InventoryPreview(
                              scope: 'room',
                              loadout: inventory.loadout,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: inventory.clearRoomDraft,
                            icon: const Icon(Icons.undo_rounded),
                            label: const Text('Restaurar mi habitación'),
                          ),
                        ],
                      ],
                      TextField(
                        style: const TextStyle(color: Color(0xFF202027)),
                        onChanged: (v) => setState(() => query = v),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search_rounded),
                          hintText: 'Buscar objeto o colección',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: PopupMenuButton<String>(
                          tooltip: 'Filtrar objetos',
                          initialValue: slot ?? 'all',
                          onSelected: (v) =>
                              setState(() => slot = v == 'all' ? null : v),
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'all',
                              child: Text('Todos los objetos'),
                            ),
                            for (final e in InventoryItem.slots.entries.where(
                              (e) => scope == 'interface'
                                  ? !e.key.startsWith('pet_') &&
                                        !e.key.startsWith('room_')
                                  : e.key.startsWith('${scope}_'),
                            ))
                              PopupMenuItem(value: e.key, child: Text(e.value)),
                          ],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  slot == null
                                      ? 'Todos los objetos'
                                      : InventoryItem.slots[slot] ?? 'Filtro',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF746874),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Icon(Icons.tune_rounded, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (busy)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: LinearProgressIndicator(),
                        ),
                      if (items.isEmpty)
                        const SceneStatus(
                          title: 'Un lugar para tus favoritos',
                          message:
                              'No hay objetos con estos filtros. Prueba otra categoría.',
                          loading: false,
                        ),
                      LayoutBuilder(
                        builder: (context, constraints) => Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final item in pageItems)
                              SizedBox(
                                width: (constraints.maxWidth - 12) / 2,
                                child: _productCard(item),
                              ),
                          ],
                        ),
                      ),
                      if (items.length > 16)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: safePage > 0
                                  ? () => setState(() => page = safePage - 1)
                                  : null,
                              child: const Text('Anterior'),
                            ),
                            Text(
                              '${safePage + 1} / ${(items.length / 16).ceil()}',
                            ),
                            TextButton(
                              onPressed: (safePage + 1) * 16 < items.length
                                  ? () => setState(() => page = safePage + 1)
                                  : null,
                              child: const Text('Siguiente'),
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),
                      const Text(
                        'Cada objeto se prueba sobre tu mascota o habitación antes de comprarlo. Las compras con LoveCoins se conservan en tu inventario.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF716B78),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _coinsPanel() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Oro para su nido', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      const Text(
        'Correr: 50 puntos = 1 moneda. Guardianes: 10 puntos de botín restante = 1 moneda en pareja; en solitario, la mitad. Superar un récord anterior da un 10 % extra dentro del límite diario.',
      ),
      const SizedBox(height: 12),
      RewardedGoldCard(previewMode: widget.previewMode),
      for (final pack in storePackages)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.monetization_on_rounded,
                      color: Color(0xFFD49B23),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pack.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      pack.price,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${pack.gold} monedas de oro',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(pack.description),
                const SizedBox(height: 12),
                const HeartButton(label: 'Disponible cuando activemos pagos'),
              ],
            ),
          ),
        ),
      const Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          'Precios de referencia en USD. Crecimiento pendiente de los modelos por etapas. No se realizan cobros todavía.',
          style: TextStyle(fontSize: 12, color: Color(0xFF716B78)),
        ),
      ),
    ],
  );

  Widget _productCard(InventoryItem item) {
    return Card(
      color: const Color(0xFFFFFBF5),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFF2DCD6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: ProductThumbnail(
                  item: item,
                  species: SharedPetService.instance.species,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              item.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF202027),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.rarity,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: switch (item.rarity) {
                  'Legendario' => const Color(0xFF8D591A),
                  'Exclusivo' => const Color(0xFF75448B),
                  'Especial' => const Color(0xFF2C6677),
                  _ => const Color(0xFF4F6855),
                },
              ),
            ),
            Text(
              boutiqueDescriptions[item.key] ?? item.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF716B78),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.previewOnly
                  ? (item.price > 0
                        ? '${item.price} monedas · Próximamente'
                        : 'En preparación')
                  : inventory.equipped(item.key)
                  ? '✓ Equipado'
                  : inventory.owns(item.key)
                  ? '✓ En tu inventario'
                  : '🪙 ${item.price}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: HeartButton(
                onPressed: busy ? null : () => _viewItem(item),
                label: 'Probar',
              ),
            ),
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
      final pet = Pet3DViewer(
        previewLoadout: loadout,
        modelPath: PetModelCatalog.modelPathFor(
          SharedPetService.instance.species,
        ),
        petLevel: SharedPetService.instance.level,
        animationName: 'Natural_Rest',
        isolatedRoomPreview: scope == 'room',
        autoPlay: true,
        cameraControls: false,
        cameraOrbit: '0deg 75deg 105%',
      );
      return Container(
        width: 360,
        height: scope == 'room' ? 360 : 310,
        decoration: BoxDecoration(
          color: scope == 'pet'
              ? const Color(0xFFFFF5F7)
              : const Color(0xFFF3EBDD),
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: scope == 'room'
                  ? PetRoomStage(loadout: loadout, pet: pet)
                  : Padding(padding: const EdgeInsets.all(12), child: pet),
            ),
            const Positioned(
              bottom: 8,
              left: 12,
              child: Text(
                'Vista previa · Sin guardar',
                style: TextStyle(fontSize: 11, color: Color(0xFF202027)),
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
          color: const Color(0xFFFFF9FA),
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
              style: TextStyle(color: Color(0xFF202027), fontSize: 11),
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
              child: Text(
                answer,
                style: const TextStyle(color: Color(0xFF202027)),
              ),
            ),
        ],
      ),
    );
  }
}
