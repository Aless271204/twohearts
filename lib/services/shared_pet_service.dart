import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class SharedPetService extends ChangeNotifier {
  static final instance = SharedPetService._();
  SharedPetService._() {
    SupabaseService.instance.client.auth.onAuthStateChange.listen((_) {
      if (_account != SupabaseService.instance.currentUser?.id) {
        _generation++;
        data = {};
        _account = SupabaseService.instance.currentUser?.id;
        notifyListeners();
      }
    });
  }
  Map<String, dynamic> data = {};
  String? _account;
  int _generation = 0;
  bool get ready => data.isNotEmpty;
  int get hunger => data['hunger'] as int? ?? 0;
  int get energy => data['energy'] as int? ?? 0;
  int get joy => data['joy'] as int? ?? 0;
  int get level => data['level'] as int? ?? 1;
  bool get paired => (data['members'] as List? ?? []).length == 2;
  Future<void> refresh() async {
    final uid = SupabaseService.instance.currentUser?.id;
    if (uid == null) { data = {}; notifyListeners(); return; }
    final generation = ++_generation;
    final result = await SupabaseService.instance.client.rpc('shared_pet_snapshot');
    if (generation != _generation || SupabaseService.instance.currentUser?.id != uid) return;
    _account = uid;
    data = Map<String, dynamic>.from(result as Map);
    notifyListeners();
  }
  Future<void> care(String action) async {
    final uid = SupabaseService.instance.currentUser?.id;
    final result = await SupabaseService.instance.client.rpc('shared_pet_care', params: {'p_action': action});
    if (SupabaseService.instance.currentUser?.id != uid) return;
    data = Map<String, dynamic>.from(result as Map);
    notifyListeners();
  }
}
