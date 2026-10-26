import 'dart:async';

import '../core/feature_flags.dart';

import 'package:flutter/foundation.dart';

import 'supabase_service.dart';
import '../core/pet_model_catalog.dart';

class SharedPetService extends ChangeNotifier {
  static final instance = SharedPetService._();
  SharedPetService._() {
    SupabaseService.instance.client.auth.onAuthStateChange.listen((_) {
      if (_account != SupabaseService.instance.currentUser?.id) {
        _generation++;
        data = {};
        loadError = null;
        _account = SupabaseService.instance.currentUser?.id;
        notifyListeners();
      }
    });
  }
  Map<String, dynamic> data = {};
  String? _account;
  int _generation = 0;
  bool _changing = false;
  String? loadError;
  Future<void>? _refreshing;
  String? _refreshingUser;
  int get revision => _generation;
  void acceptSnapshot(Map<String, dynamic> snapshot, int revision) {
    if (_changing ||
        revision != _generation ||
        SupabaseService.instance.currentUser?.id == null)
      return;
    loadError = null;
    data = snapshot;
    _account = SupabaseService.instance.currentUser?.id;
    notifyListeners();
  }

  bool get ready => data.isNotEmpty;
  int get hunger => data['hunger'] as int? ?? 0;
  int get energy => data['energy'] as int? ?? 0;
  int get joy => data['joy'] as int? ?? 0;
  int get level => data['level'] as int? ?? 1;
  bool get paired => (data['members'] as List? ?? []).length == 2;
  String? get activePetId => data['active_pet_id'] as String?;
  String get species => PetModelCatalog.speciesFor(data['species']);
  String get name => (data['name'] as String? ?? '').trim();
  String get displayName => name.isEmpty ? 'Nuestra mascota' : name;
  int get familyLevel => data['family_level'] as int? ?? level;
  int get careDays => data['care_days'] as int? ?? 0;
  bool get selectionConfirmed => data['selection_confirmed'] == true;
  List<Map<String, dynamic>> get pets => (data['pets'] as List? ?? [])
      .map((p) => Map<String, dynamic>.from(p as Map))
      .toList();
  Future<void> change(
    String action,
    String species,
    String name, {
    String? petId,
  }) async {
    if (_changing) throw StateError('Cambio en curso');
    _changing = true;
    try {
      final uid = SupabaseService.instance.currentUser?.id;
      final generation = ++_generation;
      final result = await SupabaseService.instance.client.rpc(
        petId == null ? 'shared_pet_change' : 'shared_pet_change_by_id',
        params: {
          'p_action': action,
          if (petId == null) 'p_species': species else 'p_pet_id': petId,
          'p_name': name.trim(),
        },
      );
      if (SupabaseService.instance.currentUser?.id != uid ||
          generation != _generation)
        return;
      data = Map<String, dynamic>.from(result as Map);
      _generation++;
      notifyListeners();
    } finally {
      _changing = false;
    }
  }

  Future<void> refresh() {
    final uid = SupabaseService.instance.currentUser?.id;
    if (_refreshing != null && _refreshingUser == uid) return _refreshing!;
    _refreshingUser = uid;
    final future = _loadSnapshot(uid);
    _refreshing = future;
    return future.whenComplete(() {
      if (identical(_refreshing, future)) _refreshing = null;
    });
  }

  Future<void> _loadSnapshot(String? uid) async {
    if (_changing) return;
    if (uid == null) {
      data = {};
      loadError = 'Inicia sesión para ver tu mascota.';
      notifyListeners();
      return;
    }
    final generation = ++_generation;
    loadError = null;
    notifyListeners();
    try {
      final result = await SupabaseService.instance.client
          .rpc('shared_pet_snapshot')
          .timeout(const Duration(seconds: 20));
      if (generation != _generation ||
          SupabaseService.instance.currentUser?.id != uid)
        return;
      _account = uid;
      data = Map<String, dynamic>.from(result as Map);
    } catch (_) {
      if (generation != _generation ||
          SupabaseService.instance.currentUser?.id != uid)
        return;
      loadError =
          'No pudimos cargar tu mascota. Revisa la conexión e inténtalo de nuevo.';
    }
    notifyListeners();
  }

  Future<void> care(String action) async {
    if (!FeatureFlags.petCare) return;
    final uid = SupabaseService.instance.currentUser?.id;
    final result = await SupabaseService.instance.client.rpc(
      'shared_pet_care',
      params: {'p_action': action},
    );
    if (SupabaseService.instance.currentUser?.id != uid) return;
    data = Map<String, dynamic>.from(result as Map);
    notifyListeners();
  }
}
