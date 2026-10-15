import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'supabase_service.dart';

class SharedLocationPoint {
  final LatLng? point;
  final bool sharing;
  final DateTime? at;
  const SharedLocationPoint(this.point, this.sharing, this.at);
  static SharedLocationPoint? parse(dynamic raw) {
    if (raw is! Map) return null;
    final lat = raw['lat'], lon = raw['lon'];
    final valid =
        lat is num &&
        lon is num &&
        lat.isFinite &&
        lon.isFinite &&
        lat.abs() <= 90 &&
        lon.abs() <= 180;
    return SharedLocationPoint(
      valid ? LatLng((lat as num).toDouble(), (lon as num).toDouble()) : null,
      raw['sharing'] == true,
      DateTime.tryParse(raw['located_at']?.toString() ?? '')?.toLocal(),
    );
  }

  bool get live =>
      sharing &&
      at != null &&
      DateTime.now().difference(at!) < const Duration(seconds: 60);
  String get caption {
    if (point == null) return 'Aún no comparte su ubicación';
    final time = at == null
        ? ''
        : ' · ${at!.day}/${at!.month} ${at!.hour.toString().padLeft(2, '0')}:${at!.minute.toString().padLeft(2, '0')}';
    return live ? 'En directo$time' : 'Última ubicación$time';
  }
}

/// Foreground-only, mutual-partner sharing. Turning off keeps the last point.
class CoupleLocationService extends ChangeNotifier with WidgetsBindingObserver {
  SharedLocationPoint? mine, partner;
  String? error;
  bool busy = false,
      _disposed = false,
      _refreshing = false,
      _publishing = false;
  bool _active = true;
  int _generation = 0;
  StreamSubscription<Position>? _positions;
  Timer? _poll, _fixTimer;
  DateTime _lastPublish = DateTime.fromMillisecondsSinceEpoch(0);
  bool get sharing => mine?.sharing == true;
  static String? _account() {
    try {
      return SupabaseService.instance.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  final String? _uid = _account();
  bool get _valid => !_disposed && _uid != null && _account() == _uid;
  Future<dynamic> _request(String action, {Position? position}) =>
      SupabaseService.instance.client.rpc(
        'couple_location',
        params: {
          'p_action': action,
          if (position != null) ...{
            'p_lat': position.latitude,
            'p_lon': position.longitude,
          },
        },
      );
  void _accept(dynamic value) {
    if (!_valid) return;
    mine = SharedLocationPoint.parse(value['mine']);
    partner = SharedLocationPoint.parse(value['partner']);
    notifyListeners();
  }

  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);
    await refresh();
    if (!_valid) return;
    if (sharing) await _track(prompt: false);
    _fixTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!_valid || !_active || !sharing || busy || _publishing) return;
      final generation = _generation;
      try {
        final fix = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        );
        await _publish(fix, generation, force: true);
      } catch (_) {}
    });
    _poll = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_active) refresh();
    });
  }

  Future<void> refresh() async {
    if (!_valid || _refreshing || busy) return;
    _refreshing = true;
    final generation = _generation;
    try {
      final raw = await _request('snapshot');
      if (!busy && generation == _generation) _accept(raw);
    } catch (_) {
      if (_valid) {
        error = 'No pudimos actualizar las ubicaciones.';
        notifyListeners();
      }
    } finally {
      _refreshing = false;
    }
  }

  Future<bool> _permission(bool prompt) async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && prompt)
      permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> setSharing(bool enabled) async {
    if (!_valid || busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      if (enabled && !await _permission(true))
        throw StateError('Activa el permiso de ubicación para compartirla.');
      ++_generation;
      await _positions?.cancel();
      _positions = null;
      _accept(await _request(enabled ? 'enable' : 'disable'));
      if (enabled && _valid) await _track(prompt: false);
    } catch (_) {
      if (_valid)
        error =
            'Revisa el permiso de ubicación y la conexión e inténtalo de nuevo.';
    } finally {
      if (_valid) {
        busy = false;
        notifyListeners();
      }
    }
  }

  Future<void> _track({required bool prompt}) async {
    if (!_valid || !sharing || !_active) return;
    final generation = ++_generation;
    await _positions?.cancel();
    if (!await _permission(prompt) || !_valid || generation != _generation)
      return;
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15,
      timeLimit: Duration(seconds: 20),
    );
    try {
      final first = await Geolocator.getCurrentPosition(
        locationSettings: settings,
      );
      if (_valid && generation == _generation && sharing)
        await _publish(first, generation, force: true);
      if (!_valid || generation != _generation || !sharing) return;
      _positions =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 15,
            ),
          ).listen(
            (p) => _publish(p, generation),
            onError: (_) {
              if (_valid) {
                error =
                    'Se interrumpió la ubicación; mostramos el último punto.';
                notifyListeners();
              }
            },
          );
    } catch (_) {
      if (_valid) {
        error = 'No pudimos localizarte; conservamos el último punto.';
        notifyListeners();
      }
    }
  }

  Future<void> _publish(
    Position p,
    int generation, {
    bool force = false,
  }) async {
    if (!_valid ||
        !_active ||
        !sharing ||
        generation != _generation ||
        _publishing)
      return;
    if (!force &&
        DateTime.now().difference(_lastPublish) < const Duration(seconds: 5))
      return;
    _publishing = true;
    try {
      final raw = await _request('publish', position: p);
      if (_valid && generation == _generation) {
        error = null;
        _lastPublish = DateTime.now();
        _accept(raw);
      }
    } catch (_) {
      if (_valid) {
        error = 'Sin conexión: mostramos el último punto compartido.';
        notifyListeners();
      }
    } finally {
      _publishing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (!_active) {
      ++_generation;
      _positions?.cancel();
      _positions = null;
    } else {
      refresh();
      if (sharing) _track(prompt: false);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    _poll?.cancel();
    _fixTimer?.cancel();
    _positions?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
