import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'shared_pet_service.dart';
import '../core/pet_accessory_catalog.dart';
import '../core/room_catalog.dart';
import '../core/shop_economy_v2.dart';
import '../core/store_economy.dart';

class InventoryItem {
  final Map<String, dynamic> data;
  const InventoryItem(this.data);
  bool get previewOnly => data['preview_only'] == true;
  bool get visible => data['visible'] != false;
  String get roomCategory =>
      data['room_category'] as String? ??
      appearance['room_category'] as String? ??
      (slot == 'room_ceiling'
          ? 'Techo'
          : [
              'room_wall',
              'room_decor',
              'room_mirror',
              'room_shelf',
            ].contains(slot)
          ? 'Pared'
          : ['room_floor', 'room_rug'].contains(slot)
          ? 'Suelo'
          : 'Muebles');
  String get key => data['item_key'] as String;
  // Older catalog rows can contain UTF-8 text decoded as Latin-1.
  static String readableText(String value) {
    if (!value.contains('Ã') && !value.contains('Â')) return value;
    try {
      return utf8.decode(latin1.encode(value));
    } catch (_) {
      return value;
    }
  }

  String get name => readableText(data['name'] as String);
  String get emoji => data['emoji'] as String? ?? '🎁';
  String get scope => data['scope'] as String? ?? '';
  String get slot => data['equip_slot'] as String? ?? '';
  String get description => readableText(data['description'] as String? ?? '');
  String get collection => data['collection'] as String? ?? 'Clásica';
  String get rarity => readableText(data['rarity'] as String? ?? 'Común');
  int get price => data['price_coins'] as int? ?? 0;
  Map<String, dynamic> get appearance =>
      Map<String, dynamic>.from(data['appearance'] as Map? ?? {});
  String get style => appearance['style'] as String? ?? '';
  Color get color => parseColor(appearance['color']);
  static Color parseColor(dynamic value) {
    if (value is! String || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value)) {
      return const Color(0xFF92BDA7);
    }
    return Color(0xFF000000 | int.parse(value.substring(1), radix: 16));
  }

  static const destinations = {
    'pet': 'Mascota',
    'room': 'Habitación',
    'pong': 'Ping pong',
    'quiz': 'Preguntas',
  };
  static const slots = {
    'pet_head': 'Cabeza',
    'pet_eyes': 'Ojos',
    'pet_neck': 'Cuello',
    'pet_body': 'Cuerpo',
    'pet_feet': 'Patas',
    'pet_back': 'Mochila',
    'room_wall': 'Pared',
    'room_ceiling': 'Techo',
    'room_rug': 'Alfombra',
    'room_mirror': 'Espejo',
    'room_shelf': 'Repisa',
    'room_chair': 'Sillón',
    'room_table': 'Mesa',
    'room_dresser': 'Cómoda',
    'room_floor': 'Suelo',
    'room_bed': 'Cama',
    'room_plant': 'Planta',
    'room_lamp': 'Lámpara',
    'room_decor': 'Cuadro',
    'pong_paddle': 'Paleta',
    'pong_ball': 'Pelota',
    'pong_court': 'Cancha',
    'quiz_card': 'Cartas',
    'quiz_table': 'Mesa',
    'quiz_badge': 'Insignia',
  };
}

/// The account owns its inventory; all mutations and prices are checked by SQL.
class InventoryService extends ChangeNotifier {
  static final instance = InventoryService._();
  InventoryService._() {
    _db.auth.onAuthStateChange.listen((_) {
      if (_account != _uid) {
        _clear();
        if (_uid != null) refresh().catchError((Object _) {});
      }
    });
  }
  SupabaseClient get _db => SupabaseService.instance.client;
  String? get _uid => _db.auth.currentUser?.id;
  String? _account;
  int coins = 0;
  List<InventoryItem> catalog = [];
  List<Map<String, dynamic>> bundles = [];
  Map<String, Map<String, dynamic>> owned = {};
  Map<String, dynamic> roomLayout = {};
  bool roomPlaced(String key) => (roomLayout['items'] as List? ?? []).any(
    (item) => item is Map && item['item_key'] == key,
  );
  int _generation = 0;
  RealtimeChannel? _wardrobeChannel;
  String? _watchingUser;
  Timer? _wardrobeDebounce;
  void _watchWardrobe(String uid) {
    if (_watchingUser == uid) return;
    final old = _wardrobeChannel;
    if (old != null) unawaited(_db.removeChannel(old));
    _watchingUser = uid;
    _wardrobeChannel =
        _db
            .channel(
              'nido-wardrobe:$uid',
              opts: const RealtimeChannelConfig(private: true),
            )
            .onBroadcast(
              event: 'wardrobe',
              callback: (_) {
                if (_uid != uid) return;
                _wardrobeDebounce?.cancel();
                _wardrobeDebounce = Timer(
                  const Duration(milliseconds: 140),
                  () {
                    if (_uid == uid) {
                      unawaited(refresh().catchError((Object _) {}));
                    }
                  },
                );
              },
            )
          ..subscribe();
  }

  Map<String, InventoryItem>? _sharedLoadout;
  Map<String, Set<String>> colorUnlocks = {};
  final Map<String, InventoryItem> roomDraft = {};
  void previewRoomItem(InventoryItem item) {
    if (item.scope != 'room' || !item.previewOnly) return;
    roomDraft[item.slot] = item;
    notifyListeners();
  }

  void clearRoomDraft() {
    roomDraft.clear();
    roomLayout = {};
    notifyListeners();
  }

  bool owns(String key) => owned.containsKey(key);
  bool equipped(String key) {
    final item = catalog.where((i) => i.key == key).firstOrNull;
    if (_sharedLoadout != null &&
        item != null &&
        ['pet', 'room'].contains(item.scope)) {
      return _sharedLoadout![item.slot]?.key == key;
    }
    return owned[key]?['equipped'] == true;
  }

  InventoryItem? at(String slot) {
    for (final item in catalog) {
      if (item.slot == slot && equipped(item.key)) return item;
    }
    return null;
  }

  Map<String, InventoryItem> get loadout => {
    for (final i in catalog)
      if (equipped(i.key) &&
          (_sharedLoadout == null || !['pet', 'room'].contains(i.scope)))
        i.slot: i,
    if (_sharedLoadout != null)
      for (final entry in _sharedLoadout!.entries)
        entry.key: _withLocalAppearance(entry.value),
    ...roomDraft,
  };
  void _clear() {
    _wardrobeDebounce?.cancel();
    final channel = _wardrobeChannel;
    _wardrobeChannel = null;
    _watchingUser = null;
    if (channel != null) unawaited(_db.removeChannel(channel));
    _generation++;
    _account = _uid;
    coins = 0;
    bundles = [];
    _sharedLoadout = null;
    roomDraft.clear();
    colorUnlocks.clear();
    catalog = [];
    catalog = mergeAccessoryConcepts(catalog);
    owned = {};
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadPetAccessoryCatalog();
    final uid = _uid;
    if (uid == null) {
      _clear();
      return;
    }
    final generation = ++_generation;
    final raw = Map<String, dynamic>.from(
      await _db.rpc('shop_v2', params: {'p_action': 'status'}) as Map,
    );
    if (_uid != uid || generation != _generation || raw['user_id'] != uid) {
      return;
    }
    Map<String, InventoryItem>? shared = _sharedLoadout;
    final petRevision = SharedPetService.instance.revision;
    try {
      final pet = Map<String, dynamic>.from(
        await _db.rpc('shared_pet_snapshot') as Map,
      );
      if (_uid == uid && generation == _generation) {
        SharedPetService.instance.acceptSnapshot(pet, petRevision);
      }
      shared = {
        for (final item in pet['equipment'] as List)
          (item as Map)['equip_slot'] as String: InventoryItem(
            Map<String, dynamic>.from(item),
          ),
      };
    } catch (_) {
      /* Older servers retain personal equipment until migration. */
    }
    Map<String, dynamic> layout = {};
    try {
      layout = Map<String, dynamic>.from(
        await _db.rpc('room_layout', params: {'p_action': 'status'}) as Map,
      );
    } catch (_) {
      // The ordinary room remains usable when layout storage is unavailable.
      if (_account == uid) layout = roomLayout;
    }
    if (_uid != uid || generation != _generation) return;
    roomLayout = layout;
    _sharedLoadout = shared;
    _account = uid;
    _watchWardrobe(uid);
    coins = raw['coins'] as int;
    bundles = (raw['bundles'] as List? ?? [])
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    colorUnlocks = {};
    for (final r in raw['colors'] as List? ?? []) {
      colorUnlocks
          .putIfAbsent(r['item_key'] as String, () => {})
          .add(r['color_key'] as String);
    }
    catalog = (raw['catalog'] as List)
        .map((r) => InventoryItem(Map<String, dynamic>.from(r as Map)))
        .toList();
    catalog = mergeAccessoryConcepts(catalog);
    owned = {
      for (final r in raw['owned'] as List)
        r['item_key'] as String: Map<String, dynamic>.from(r as Map),
    };
    notifyListeners();
  }

  static InventoryItem _withLocalAppearance(InventoryItem item) {
    final local = petAccessoryConcepts
        .where((row) => row['item_key'] == item.key)
        .firstOrNull;
    if (local == null ||
        (local['appearance'] as Map?)?['fitted_model_space'] != true) {
      return item;
    }
    final original = item.appearance;
    return InventoryItem({
      ...item.data,
      'appearance': {
        ...Map<String, dynamic>.from(local['appearance'] as Map),
        if (original['garment_color'] != null)
          'garment_color': original['garment_color'],
      },
    });
  }

  static List<InventoryItem> mergeAccessoryConcepts(
    List<InventoryItem> published,
  ) {
    final concepts = <String, Map<String, dynamic>>{
      for (final row in [
        ...roomConcepts,
        ...roomShopV2,
        ...petAccessoryConcepts,
      ])
        row['item_key'] as String: row,
    };
    final hiddenKeys = {...roomConcepts, ...petAccessoryConcepts}
        .where((row) => row['visible'] == false)
        .map((row) => row['item_key'])
        .toSet();
    return [
      for (final item in published)
        hiddenKeys.contains(item.key)
            ? InventoryItem({...item.data, 'visible': false})
            : _withLocalAppearance(item),
      for (final data in concepts.values)
        if (data['visible'] != false &&
            !hiddenKeys.contains(data['item_key']) &&
            !published.any((i) => i.key == data['item_key']))
          InventoryItem({
            ...data,
            'price_coins': StoreEconomy.price(
              data['item_key'] as String,
              data['equip_slot'] as String,
            ),
            'rarity': StoreEconomy.rarity(data['item_key'] as String),
          }),
    ];
  }

  Future<void> purchase(InventoryItem item) async {
    if (item.previewOnly) {
      throw StateError('Este accesorio aun esta en preparacion.');
    }
    await _db.rpc(
      'shop_v2',
      params: {
        'p_action': 'purchase',
        'p_key': item.key,
        'p_expected_price': item.price,
      },
    );
    await refresh();
  }

  Future<Map<String, dynamic>> quoteBundle(String key) async =>
      Map<String, dynamic>.from(
        await _db.rpc('shop_v2', params: {'p_action': 'quote', 'p_key': key})
            as Map,
      );

  Future<void> purchaseBundle(String key, int expectedPrice) async {
    await _db.rpc(
      'shop_v2',
      params: {
        'p_action': 'bundle',
        'p_key': key,
        'p_expected_price': expectedPrice,
      },
    );
    await refresh();
  }

  Future<void> equip(InventoryItem item, bool enabled) async {
    if (item.scope == 'room' &&
        !['room_wall', 'room_floor', 'room_ceiling'].contains(item.slot)) {
      return placeRoomItem(item, enabled: enabled);
    }
    await _db.rpc(
      ['pet', 'room'].contains(item.scope)
          ? 'shared_pet_equip'
          : 'inventory_equip',
      params: {'p_item_key': item.key, 'p_equipped': enabled},
    );
    await refresh();
  }

  Future<void> placeRoomItem(InventoryItem item, {bool? enabled}) async {
    if (item.scope != 'room' || item.previewOnly) {
      throw StateError('Este objeto no está disponible para colocar.');
    }
    final placed =
        roomPlaced(item.key) ||
        (roomLayout['items'] == null && equipped(item.key));
    final shouldPlace = enabled ?? !placed;
    await _db.rpc(
      'room_layout',
      params: {
        'p_action': shouldPlace ? 'place' : 'remove',
        'p_data': {
          'item_key': item.key,
          'id': item.key,
          'revision': roomLayout['revision'] ?? 0,
        },
      },
    );
    await refresh();
  }

  Future<void> selectColor(InventoryItem item, String colorKey) async {
    if (!owns(item.key) || item.previewOnly) {
      throw StateError('Primero adquiere la prenda.');
    }
    await _db.rpc(
      'inventory_color_select',
      params: {'p_item_key': item.key, 'p_color_key': colorKey},
    );
    await refresh();
  }
}
