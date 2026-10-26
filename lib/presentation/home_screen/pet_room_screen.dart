import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../core/store_packages.dart';
import '../../core/pet_model_catalog.dart';
import '../../services/inventory_service.dart';
import '../../services/shared_pet_service.dart';
import '../../widgets/pet_3d_viewer.dart';
import '../../widgets/pet_family_sheet.dart';
import '../../widgets/pet_adoption_welcome.dart';
import '../../widgets/rose_ui.dart';
import '../../widgets/twohearts_ui.dart';
import '../shop_screen/inventory_screen.dart';

/// Room and pet share one real 3D scene; controls occupy dedicated safe areas.
class PetRoomScreen extends StatefulWidget {
  final bool previewMode, embedded;
  final Widget? roomScene;
  const PetRoomScreen({
    super.key,
    this.previewMode = false,
    this.embedded = false,
    this.roomScene,
  });
  @override
  State<PetRoomScreen> createState() => _PetRoomScreenState();
}

class _PetRoomScreenState extends State<PetRoomScreen>
    with WidgetsBindingObserver {
  final inventory = InventoryService.instance, pet = SharedPetService.instance;
  int reaction = 0;
  String? openPanel;
  bool get decorating => openPanel != null;
  void _toggle(String key) =>
      setState(() => openPanel = openPanel == key ? null : key);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    inventory.addListener(_changed);
    pet.addListener(_changed);
    if (!widget.previewMode) {
      inventory.refresh().catchError((Object _) {});
      pet.refresh().catchError((Object _) {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !widget.previewMode) {
      pet.refresh().catchError((Object _) {});
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    inventory.removeListener(_changed);
    pet.removeListener(_changed);
    super.dispose();
  }

  void _chest() => _toggle('chest');
  Future<void> _family() => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFFFF9FA),
    barrierColor: const Color(0x55756672),
    showDragHandle: true,
    builder: (_) => PointerInterceptor(child: const PetFamilySheet()),
  );
  Widget _roomIcon(
    IconData icon,
    String label,
    Color color,
    VoidCallback action,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: PointerInterceptor(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, color.withAlpha(45)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withAlpha(90)),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(40),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IconButton(
          tooltip: label,
          color: color,
          onPressed: action,
          icon: Icon(icon, size: 29),
          padding: const EdgeInsets.all(12),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFF9FA),
    body:
        !widget.previewMode &&
            (!pet.ready ||
                !pet.selectionConfirmed ||
                pet.data['arrival_pending'] == true)
        ? const SafeArea(child: PetAdoptionWelcome())
        : LayoutBuilder(
            builder: (context, constraints) => SizedBox.expand(
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 360),
                    curve: Curves.easeInOutCubic,
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: decorating ? constraints.maxHeight / 2 : 0,
                    child:
                        widget.roomScene ??
                        Pet3DViewer(
                          modelPath: PetModelCatalog.modelPathFor(pet.species),
                          petLevel: pet.level,
                          room: true,
                          roomEditing: openPanel == 'decorate',
                          previewLoadout: inventory.loadout,
                          petReaction: reaction,
                          onPetStroke: () => setState(() => reaction++),
                          autoPlay: true,
                          cameraControls: false,
                          animationName: 'Natural_Rest',
                          altText: '${pet.displayName} en su habitación',
                        ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 0, 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _roomIcon(
                              Icons.inventory_2_rounded,
                              'Nuestro cofre',
                              const Color(0xFFD78A28),
                              _chest,
                            ),
                            _roomIcon(
                              Icons.pets_rounded,
                              'Nuestras mascotas',
                              const Color(0xFF9474CF),
                              _family,
                            ),
                            _roomIcon(
                              Icons.chair_rounded,
                              'Personalizar habitación',
                              const Color(0xFF4B9D80),
                              () => _toggle('decorate'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 360),
                    curve: Curves.easeInOutCubic,
                    left: 0,
                    right: 0,
                    top: decorating
                        ? constraints.maxHeight / 2
                        : constraints.maxHeight,
                    height: constraints.maxHeight / 2,
                    child: PointerInterceptor(
                      child: RepaintBoundary(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          child: ColoredBox(
                            color: const Color(0xFFFFF9FA),
                            child: openPanel == 'chest'
                                ? PetChest(
                                    previewMode: widget.previewMode,
                                    embedded: true,
                                    onClose: () =>
                                        setState(() => openPanel = null),
                                  )
                                : RoomDecorationPanel(
                                    previewMode: widget.previewMode,
                                    onClose: () =>
                                        setState(() => openPanel = null),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
  );
}

class RoomDecorationPanel extends StatefulWidget {
  const RoomDecorationPanel({
    super.key,
    required this.onClose,
    this.previewMode = false,
  });
  final VoidCallback onClose;
  final bool previewMode;
  @override
  State<RoomDecorationPanel> createState() => _RoomDecorationPanelState();
}

class _RoomDecorationPanelState extends State<RoomDecorationPanel> {
  String category = 'Todos';
  String? busy;
  Future<void> _apply(InventoryItem item) async {
    if (busy != null) return;
    final inventory = InventoryService.instance;
    if (!inventory.owns(item.key)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFFFFF9FA),
          title: Text('Comprar ${item.name}'),
          content: Text(
            'Se descontarán ${item.price} de oro. El artículo quedará en vuestro cofre.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Comprar'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() => busy = item.key);
    try {
      if (!inventory.owns(item.key)) await inventory.purchase(item);
      if (['room_wall', 'room_floor', 'room_ceiling'].contains(item.slot)) {
        await inventory.equip(item, !inventory.equipped(item.key));
      } else {
        await inventory.placeRoomItem(item);
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se guardó el cambio. Revisa tu oro y tu conexión.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => busy = null);
    }
  }

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFFFF9FA),
    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
    clipBehavior: Clip.antiAlias,
    child: SafeArea(
      top: false,
      child: Column(
        children: [
          ListTile(
            title: const Text(
              'Decorar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Coloca, mueve y gira los muebles en tu habitación',
            ),
            trailing: IconButton(
              onPressed: widget.onClose,
              tooltip: 'Cerrar decoración',
              icon: const Icon(Icons.close),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final label in [
                  'Todos',
                  'Techo',
                  'Pared',
                  'Suelo',
                  'Muebles',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: category == label,
                      onSelected: (_) => setState(() => category = label),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: InventoryService.instance,
              builder: (context, _) {
                final inventory = InventoryService.instance;
                final items = inventory.catalog
                    .where(
                      (i) =>
                          i.visible &&
                          i.scope == 'room' &&
                          (category == 'Todos' || i.roomCategory == category),
                    )
                    .toList();
                if (items.isEmpty)
                  return const Center(
                    child: Text(
                      'Los artículos aparecerán al cargar el catálogo.',
                    ),
                  );
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 190,
                    mainAxisExtent: 184,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      child: Column(
                        children: [
                          Expanded(child: ProductThumbnail(item: item)),
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          TextButton(
                            onPressed:
                                widget.previewMode ||
                                    busy != null ||
                                    item.previewOnly
                                ? null
                                : () => _apply(item),
                            child: Text(
                              busy == item.key
                                  ? 'Guardando…'
                                  : item.previewOnly
                                  ? 'Próximamente'
                                  : (inventory.roomPlaced(item.key) ||
                                        inventory.equipped(item.key))
                                  ? 'Quitar'
                                  : inventory.owns(item.key)
                                  ? 'Colocar'
                                  : '${item.price} de oro',
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class PetChest extends StatelessWidget {
  final bool previewMode, embedded;
  final VoidCallback? onClose;
  const PetChest({
    super.key,
    this.previewMode = false,
    this.embedded = false,
    this.onClose,
  });
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: InventoryService.instance,
    builder: (context, _) {
      final inventory = InventoryService.instance;
      final owned = inventory.catalog
          .where(
            (i) => inventory.owns(i.key) && ['pet', 'room'].contains(i.scope),
          )
          .toList();
      return SafeArea(
        child: SizedBox(
          height: embedded ? null : MediaQuery.sizeOf(context).height * .76,
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 12, 10),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_rounded, color: Color(0xFFF05280)),
                      SizedBox(width: 10),
                      Text(
                        'Nuestro cofre',
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onClose != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Cerrar cofre',
                      onPressed: onClose,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                const TabBar(
                  tabs: [
                    Tab(text: 'Mis artículos'),
                    Tab(text: 'Tienda y promociones'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      owned.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(28),
                                child: Text(
                                  'Tus compras aparecerán aquí. Prueba los artículos de la tienda para encontrar vuestros favoritos.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: owned.length,
                              itemBuilder: (context, index) {
                                final item = owned[index];
                                return ListTile(
                                  leading: SizedBox(
                                    width: 58,
                                    height: 58,
                                    child: ProductThumbnail(
                                      item: item,
                                      species:
                                          SharedPetService.instance.species,
                                    ),
                                  ),
                                  title: Text(item.name),
                                  subtitle: Text(
                                    inventory.equipped(item.key)
                                        ? 'Equipado'
                                        : InventoryItem.slots[item.slot] ??
                                              item.slot,
                                  ),
                                  trailing: IconButton(
                                    tooltip: inventory.equipped(item.key)
                                        ? 'Quitar'
                                        : 'Equipar',
                                    icon: Icon(
                                      inventory.equipped(item.key)
                                          ? Icons.check_circle_rounded
                                          : Icons.add_circle_outline_rounded,
                                    ),
                                    onPressed: previewMode
                                        ? null
                                        : () async {
                                            try {
                                              await inventory.equip(
                                                item,
                                                !inventory.equipped(item.key),
                                              );
                                            } catch (_) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'No se guardó el cambio. Reintenta.',
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                  ),
                                );
                              },
                            ),
                      ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          const Text(
                            'Encuentra vuestro estilo',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Prendas desde 50 de oro, colores por 10 y pequeños cuadros desde 60.',
                          ),
                          const SizedBox(height: 18),
                          HeartButton(
                            label: 'Explorar la tienda',
                            icon: Icons.storefront_rounded,
                            onPressed: () =>
                                Navigator.of(context, rootNavigator: true).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        ShopScreen(previewMode: previewMode),
                                  ),
                                ),
                          ),
                          for (final pack in storePackages)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.monetization_on_rounded,
                                color: Color(0xFFD49B23),
                              ),
                              title: Text('${pack.gold} de oro'),
                              subtitle: Text(pack.name),
                              trailing: Text(pack.price),
                              onTap: () =>
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ShopScreen(
                                        previewMode: previewMode,
                                        initialCoins: true,
                                      ),
                                    ),
                                  ),
                            ),
                          const SizedBox(height: 12),
                          const Text(
                            'Aquí encontrarás los próximos lanzamientos y las promociones disponibles.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF716B78),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
