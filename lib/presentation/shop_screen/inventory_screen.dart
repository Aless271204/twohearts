import '../../core/shop_showcase.dart';
import '../../core/boutique_thumbnails.dart';
import '../../theme/app_theme.dart';
import '../../widgets/play_gold_packages.dart';
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
  final _showcaseController = PageController();
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
    _showcaseController.dispose();
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

  final Map<String, int> _showcasePages = {};
  Widget _bundleOffers({bool general = false}) {
    final offers = inventory.bundles
        .where((b) => general || b['scope'] == scope)
        .toList();
    if (offers.isEmpty || onlyOwned) return const SizedBox.shrink();
    final selected = (_showcasePages[general ? 'all' : scope] ?? 0).clamp(
      0,
      offers.length - 1,
    );
    final bundle = offers[selected];
    final showcaseScope = bundle['scope'] as String;
    final keys = (bundle['items'] as List? ?? [])
        .map((e) => (e as Map)['item_key'])
        .toSet();
    final products = inventory.catalog
        .where((i) => keys.contains(i.key) && i.visible)
        .toList();
    final look = <String, InventoryItem>{for (final i in products) i.slot: i};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          showcaseScope == 'room'
              ? 'Un mundo para su Nido'
              : 'Descubre su próximo look',
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF352E35),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: showcaseScope == 'room' ? 350 : 310,
          child: PageView.builder(
            controller: _showcaseController,
            key: ValueKey('showcase-${general ? 'all' : scope}'),
            itemCount: offers.length,
            onPageChanged: (value) =>
                setState(() => _showcasePages[general ? 'all' : scope] = value),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/products/showcases-v2/${offers[index]['bundle_key']}.webp',
                        key: ValueKey(
                          'showcase-image-${offers[index]['bundle_key']}',
                        ),
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Chip(
                        label: Text('${index + 1} / ${offers.length}'),
                        backgroundColor: const Color(0xFFFFFAF1),
                      ),
                    ),
                    const Positioned(
                      top: 15,
                      right: 14,
                      child: Icon(
                        Icons.swipe_rounded,
                        color: Color(0xFF493344),
                      ),
                    ),
                    for (final direction in [-1, 1])
                      Positioned(
                        left: direction < 0 ? 10 : null,
                        right: direction > 0 ? 10 : null,
                        bottom: 24,
                        child: IconButton.filledTonal(
                          tooltip: direction < 0
                              ? 'Conjunto anterior'
                              : 'Siguiente conjunto',
                          onPressed:
                              index + direction < 0 ||
                                  index + direction >= offers.length
                              ? null
                              : () => _showcaseController.animateToPage(
                                  index + direction,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                ),
                          icon: Icon(
                            direction < 0
                                ? Icons.chevron_left_rounded
                                : Icons.chevron_right_rounded,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              offers.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: i == selected ? 22 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == selected
                      ? const Color(0xFFF05280)
                      : const Color(0xFFE5CCD3),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ),
        if (showcaseScope != 'room')
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.view_in_ar_rounded),
              label: Text('Probar conjunto'),
              onPressed: look.isEmpty
                  ? null
                  : () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (context) => SafeArea(
                        child: SizedBox(
                          height: MediaQuery.sizeOf(context).height * .7,
                          child: InventoryPreview(
                            scope: showcaseScope,
                            loadout: look,
                            roomLayout: showcaseScope == 'room'
                                ? showcaseRoomLayout(products)
                                : null,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        Text(
          bundle['name'] as String,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Color(0xFF352E35),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          showcaseScope == 'room'
              ? 'Los artículos de esta habitación'
              : 'Completa el conjunto',
          style: const TextStyle(color: Color(0xFF65515C)),
        ),
        SizedBox(
          height: 189,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 9),
            itemCount: products.length,
            separatorBuilder: (_, index) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final item = products[index];
              return SizedBox(
                width: 140,
                child: Card(
                  elevation: 0,
                  color: const Color(0xFFFFFBF6),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _openShowcaseProduct(item),
                    child: Padding(
                      padding: const EdgeInsets.all(9),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ProductThumbnail(
                              item: item,
                              species: SharedPetService.instance.species,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            inventory.owns(item.key)
                                ? 'En tu cofre'
                                : '${item.price} de oro',
                            style: const TextStyle(
                              color: Color(0xFF775226),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Card(
          color: const Color(0xFFFFEDE5),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    bundle['missing_count'] == 0
                        ? 'Ya es vuestro'
                        : '${bundle['price_coins']} de oro · −${bundle['discount_percent']} %',
                    style: const TextStyle(
                      color: Color(0xFF493B37),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: busy || bundle['missing_count'] == 0
                      ? null
                      : () => _buyBundle(bundle),
                  child: const Text('Ver conjunto'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  void _openShowcaseProduct(InventoryItem item) {
    _viewItem(item);
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
                    if (!onlyOwned && !showCoins) _bundleOffers(general: true),
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
                      for (final category
                          in items
                              .map(
                                (i) =>
                                    InventoryItem.slots[i.slot] ?? i.collection,
                              )
                              .toSet()) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  category,
                                  style: const TextStyle(
                                    fontFamily: 'Georgia',
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF352E35),
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.swipe_rounded,
                                size: 20,
                                color: Color(0xFF86646E),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 365,
                          child: ListView.separated(
                            key: PageStorageKey('products-$scope-$category'),
                            scrollDirection: Axis.horizontal,
                            itemCount: items
                                .where(
                                  (i) =>
                                      (InventoryItem.slots[i.slot] ??
                                          i.collection) ==
                                      category,
                                )
                                .length,
                            separatorBuilder: (_, index) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, index) => SizedBox(
                              width: 185,
                              child: _productCard(
                                items
                                    .where(
                                      (i) =>
                                          (InventoryItem.slots[i.slot] ??
                                              i.collection) ==
                                          category,
                                    )
                                    .elementAt(index),
                              ),
                            ),
                          ),
                        ),
                      ],
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
        'Gana oro jugando y comparte su cofre. En juegos con dificultad, solo Difícil cuenta para los récords y su bonificación del 10 %.',
      ),
      const SizedBox(height: 12),
      RewardedGoldCard(previewMode: widget.previewMode),
      PlayGoldPackages(previewMode: widget.previewMode),
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
  final Map<String, dynamic>? roomLayout;
  const InventoryPreview({
    super.key,
    required this.scope,
    required this.loadout,
    this.roomLayout,
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
        previewRoomLayout: roomLayout,
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
