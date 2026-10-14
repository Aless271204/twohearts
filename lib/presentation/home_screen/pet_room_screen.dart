import 'package:flutter/material.dart';
import '../../core/store_packages.dart';
import '../../core/pet_model_catalog.dart';
import '../../services/inventory_service.dart';
import '../../services/shared_pet_service.dart';
import '../../widgets/pet_3d_viewer.dart';
import '../../widgets/pet_family_sheet.dart';
import '../../widgets/rose_ui.dart';
import '../../widgets/twohearts_ui.dart';
import '../shop_screen/inventory_screen.dart';

/// Room and pet share one real 3D scene; controls occupy dedicated safe areas.
class PetRoomScreen extends StatefulWidget {
  final bool previewMode, embedded;
  const PetRoomScreen({
    super.key,
    this.previewMode = false,
    this.embedded = false,
  });
  @override
  State<PetRoomScreen> createState() => _PetRoomScreenState();
}

class _PetRoomScreenState extends State<PetRoomScreen> {
  final inventory = InventoryService.instance, pet = SharedPetService.instance;
  int reaction = 0;
  @override
  void initState() {
    super.initState();
    inventory.addListener(_changed);
    pet.addListener(_changed);
    if (!widget.previewMode) {
      inventory.refresh().catchError((Object _) {});
      pet.refresh().catchError((Object _) {});
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    inventory.removeListener(_changed);
    pet.removeListener(_changed);
    super.dispose();
  }

  Future<void> _shop({bool owned = false}) async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => ShopScreen(
          initialScope: 'room',
          initialOwned: owned,
          previewMode: widget.previewMode,
        ),
      ),
    );
  }

  Future<void> _chest() => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => PetChest(previewMode: widget.previewMode),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFF9FA),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                if (!widget.embedded)
                  IconButton(
                    tooltip: 'Volver',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                Expanded(
                  child: InkWell(
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      useRootNavigator: true,
                      isScrollControlled: true,
                      builder: (_) => const PetFamilySheet(),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pet.displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'Un rincón para los dos',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF716B78),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.embedded)
                  IconButton(
                    tooltip: 'Habitación a pantalla completa',
                    icon: const Icon(Icons.open_in_full_rounded),
                    onPressed: () =>
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                PetRoomScreen(previewMode: widget.previewMode),
                          ),
                        ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Pet3DViewer(
              modelPath: PetModelCatalog.modelPathFor(pet.species),
              petLevel: pet.level,
              room: true,
              previewLoadout: inventory.loadout,
              petReaction: reaction,
              onPetStroke: () {
                setState(() => reaction++);
              },
              autoPlay: true,
              cameraControls: false,
              animationName: 'Natural_Rest',
              altText: '${pet.displayName} en su habitación',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: HeartButton(
                    label: 'Mi cofre',
                    icon: Icons.inventory_2_outlined,
                    onPressed: _chest,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: HeartButton(
                    label: 'Decorar',
                    icon: Icons.chair_outlined,
                    outlined: true,
                    onPressed: _shop,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class PetChest extends StatelessWidget {
  final bool previewMode;
  const PetChest({super.key, this.previewMode = false});
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
          height: MediaQuery.sizeOf(context).height * .76,
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_rounded, color: Color(0xFFF05280)),
                      SizedBox(width: 10),
                      Text(
                        'Nuestro cofre',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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
