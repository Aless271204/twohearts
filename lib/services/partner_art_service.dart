import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class PartnerArtService extends ChangeNotifier with WidgetsBindingObserver {
  PartnerArtService._();
  static final instance = PartnerArtService._();
  static const channel = MethodChannel('nido/art');
  Map<String, dynamic> latest = {};
  Timer? _timer;
  StreamSubscription<AuthState>? _auth;
  String? _configuredFor;
  bool _loading = false;
  bool _foreground = true;
  SupabaseClient get client => SupabaseService.instance.client;
  void start() {
    if (_timer != null) return;
    WidgetsBinding.instance.addObserver(this);
    _auth = client.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.signedOut) {
        _configuredFor = null;
        latest = {};
        notifyListeners();
        if (!kIsWeb)
          channel.invokeMethod('clearWidget').catchError((Object _) => null);
      } else
        refresh();
    });
    _timer = Timer.periodic(const Duration(seconds: 12), (_) => refresh());
    refresh();
  }

  Future<void> refresh() async {
    if (_loading || !_foreground || client.auth.currentUser == null) return;
    _loading = true;
    final uid = client.auth.currentUser!.id;
    try {
      final value = Map<String, dynamic>.from(
        await client.rpc('art_action', params: {'p_action': 'inbox'}) as Map,
      );
      if (client.auth.currentUser?.id != uid) return;
      if (jsonEncode(value) != jsonEncode(latest)) {
        latest = value;
        notifyListeners();
      }
      if (!kIsWeb) {
        if (_configuredFor != uid) {
          final result =
              await client.rpc(
                    'art_action',
                    params: {'p_action': 'widget_token'},
                  )
                  as Map;
          if (client.auth.currentUser?.id != uid) return;
          await channel.invokeMethod('configureWidget', {
            'url': SupabaseService.supabaseUrl,
            'apiKey': SupabaseService.supabaseAnonKey,
            'token': result['token'],
            'user': uid,
          });
          _configuredFor = uid;
        }
        await channel.invokeMethod('updateNote', value);
      }
    } on PostgrestException catch (e) {
      if (e.message.contains('Vincula')) {
        latest = {};
        _configuredFor = null;
        notifyListeners();
        if (!kIsWeb)
          await channel
              .invokeMethod('clearWidget')
              .catchError((Object _) => null);
      }
    } catch (_) {
      /* Keep last private note while offline. */
    } finally {
      _loading = false;
    }
  }

  Future<void> send(String kind, String content) async {
    await client.rpc(
      'art_action',
      params: {
        'p_action': 'note',
        'p_data': {'kind': kind, 'content': content},
      },
    );
  }

  Future<bool> pin() async {
    await refresh();
    if (kIsWeb) return false;
    return await channel.invokeMethod<bool>('pinWidget') ?? false;
  }

  void pause() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timer = null;
    _auth?.cancel();
    _auth = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) refresh();
  }
}
