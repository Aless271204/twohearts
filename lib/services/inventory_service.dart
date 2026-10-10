import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../core/pet_accessory_catalog.dart';
import '../core/room_catalog.dart';

class InventoryItem {
  final Map<String, dynamic> data;
  const InventoryItem(this.data);
  bool get previewOnly => data['preview_only']==true;
  String get roomCategory => data['room_category'] as String? ?? (slot == 'room_ceiling' ? 'Techo' : ['room_wall','room_decor','room_mirror','room_shelf'].contains(slot) ? 'Pared' : ['room_floor','room_rug'].contains(slot) ? 'Suelo' : 'Muebles');
  String get key => data['item_key'] as String;
  String get name => data['name'] as String;
  String get emoji => data['emoji'] as String? ?? '🎁';
  String get scope => data['scope'] as String? ?? '';
  String get slot => data['equip_slot'] as String? ?? '';
  String get description => data['description'] as String? ?? '';
  String get collection => data['collection'] as String? ?? 'Clásica';
  String get rarity => data['rarity'] as String? ?? 'Común';
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
  Map<String, Map<String, dynamic>> owned = {};
  int _generation = 0;
  Map<String, InventoryItem>? _sharedLoadout;
  final Map<String, InventoryItem> roomDraft = {};
  void previewRoomItem(InventoryItem item) {
    if(item.scope!='room'||!item.previewOnly)return;
    roomDraft[item.slot]=item;notifyListeners();
  }
  void clearRoomDraft() {roomDraft.clear();notifyListeners();}
  bool owns(String key) => owned.containsKey(key);
  bool equipped(String key) {
    final item = catalog.where((i) => i.key == key).firstOrNull;
    if (_sharedLoadout != null && item != null && ['pet','room'].contains(item.scope)) return _sharedLoadout![item.slot]?.key == key;
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
      if (equipped(i.key) && (_sharedLoadout == null || !['pet','room'].contains(i.scope))) i.slot: i,
    ...?_sharedLoadout,
    ...roomDraft,
  };
  void _clear() {
    _generation++;
    _account = _uid;
    coins = 0;
    _sharedLoadout = null;
    roomDraft.clear();
    catalog = [];
    catalog=mergeAccessoryConcepts(catalog);
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
      await _db.rpc('inventory_snapshot') as Map,
    );
    if (_uid != uid || generation != _generation || raw['user_id'] != uid) {
      return;
    }
    Map<String, InventoryItem>? shared = _sharedLoadout;
    try {
      final pet = Map<String, dynamic>.from(await _db.rpc('shared_pet_snapshot') as Map);
      shared = {for (final item in pet['equipment'] as List) (item as Map)['equip_slot'] as String: InventoryItem(Map<String, dynamic>.from(item))};
    } catch (_) { /* Older servers retain personal equipment until migration. */ }
    if (_uid != uid || generation != _generation) return;
    _sharedLoadout = shared;
    _account = uid;
    coins = raw['coins'] as int;
    catalog = (raw['catalog'] as List)
        .map((r) => InventoryItem(Map<String, dynamic>.from(r as Map)))
        .toList();
    catalog=mergeAccessoryConcepts(catalog);
    owned = {
      for (final r in raw['owned'] as List)
        r['item_key'] as String: Map<String, dynamic>.from(r as Map),
    };
    notifyListeners();
  }

  static List<InventoryItem> mergeAccessoryConcepts(List<InventoryItem> published)=>[
    ...published.where((item)=>!petAccessoryConcepts.any((local)=>local['item_key']==item.key&&local['visible']==false)),
    for(final data in [...petAccessoryConcepts,...roomConcepts])if(data['visible']!=false&&!published.any((i)=>i.key==data['item_key']))InventoryItem(data),
  ];

  Future<void> purchase(InventoryItem item) async {
    if(item.previewOnly)throw StateError('Este accesorio aun esta en preparacion.');
    await _db.rpc('inventory_purchase', params: {'p_item_key': item.key});
    await refresh();
  }

  Future<void> equip(InventoryItem item, bool enabled) async {
    await _db.rpc(
      ['pet','room'].contains(item.scope) ? 'shared_pet_equip' : 'inventory_equip',
      params: {'p_item_key': item.key, 'p_equipped': enabled},
    );
    await refresh();
  }
}
