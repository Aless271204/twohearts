import '../services/inventory_service.dart';
import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

/// Tokens remain in Flutter. Each broadcast direction has its own RLS policy.
class GuardianBridge {
  final SupabaseClient? clientOverride;
  GuardianBridge({this.clientOverride});
  SupabaseClient get client =>
      clientOverride ?? SupabaseService.instance.client;
  final List<RealtimeChannel> _channels = [];
  RealtimeChannel? _outgoing;
  String? _room;
  bool _disposed = false;
  Future<void> Function(Map<String, dynamic>)? emit;

  Future<Map<String, dynamic>> handle(String raw) async {
    final m = jsonDecode(raw) as Map<String, dynamic>;
    if (m['type'] != 'guardian-request') throw const FormatException();
    final response = <String, dynamic>{
      'type': 'guardian-response',
      'id': m['id'],
    };
    try {
      if (client.auth.currentUser == null)
        throw StateError('Inicia sesión para jugar online y guardar oro.');
      final p = Map<String, dynamic>.from(m['payload'] as Map? ?? {});
      switch (m['action']) {
        case 'room':
          if (![
            'profile',
            'create',
            'solo',
            'join',
            'status',
            'ready',
            'start',
            'inputs',
            'confirm',
            'cancel',
          ].contains(p['p_action']))
            throw const FormatException();
          final data = Map<String, dynamic>.from(
            await client.rpc('guardian_room', params: p) as Map,
          );
          if (data['error'] != null) throw StateError(data['error'].toString());
          response['result'] = data;
          if (data['status'] == 'finished') {
            unawaited(InventoryService.instance.refresh().catchError((_) {}));
          }
          break;
        case 'watch':
          await _watch(p['room'] as String);
          response['result'] = true;
          break;
        case 'send':
          final payload = Map<String, dynamic>.from(p['data'] as Map);
          if (_outgoing == null || jsonEncode(payload).length > 24000)
            throw const FormatException();
          final result = await _outgoing!.sendBroadcastMessage(
            event: 'frame',
            payload: payload,
          );
          if (result != ChannelResponse.ok)
            throw StateError('No se pudo enviar la actualización.');
          response['result'] = true;
          break;
        case 'finish':
          final r = await client.functions.invoke(
            'guardian-adventure',
            body: p,
          );
          if (r.status != 200)
            throw StateError('No pudimos guardar la partida.');
          if (r.data is! Map || (r.data as Map)['saved'] != true) {
            throw StateError(
              'La partida sigue pendiente de validación. Vuelve a guardar.',
            );
          }
          // Settlement already succeeded. A refresh failure must not report
          // that the verified reward was lost or ask for a second award.
          unawaited(InventoryService.instance.refresh().catchError((_) {}));
          response['result'] = r.data;
          break;
        case 'close':
          await _close();
          response['result'] = true;
          break;
        default:
          throw const FormatException();
      }
      response['ok'] = true;
    } catch (e) {
      response['ok'] = false;
      response['error'] = e is StateError
          ? e.message.toString()
          : 'No pudimos conectar. Comprueba tu conexión y el código de sala.';
    }
    return response;
  }

  Future<void> _watch(String id) async {
    if (_room == id && _channels.length == 2) return;
    await _close();
    final info = Map<String, dynamic>.from(
      await client.rpc(
            'guardian_room',
            params: {'p_action': 'status', 'p_id': id},
          )
          as Map,
    );
    final role = info['role'] as int;
    _room = id;
    for (final direction in ['host', 'guest']) {
      final channel = client.channel(
        'guardian:$id:$direction',
        opts: const RealtimeChannelConfig(private: true, ack: true),
      );
      _channels.add(channel);
      if ((role == 0 && direction == 'host') ||
          (role == 1 && direction == 'guest')) {
        _outgoing = channel;
      } else {
        channel.onBroadcast(
          event: 'frame',
          callback: (payload) {
            if (!_disposed)
              unawaited(
                emit?.call({'type': 'guardian-event', 'data': payload}) ??
                    Future.value(),
              );
          },
        );
      }
      final ready = Completer<void>();
      channel.subscribe((status, error) {
        if (status == RealtimeSubscribeStatus.subscribed && !ready.isCompleted)
          ready.complete();
        if (status == RealtimeSubscribeStatus.channelError &&
            !ready.isCompleted)
          ready.completeError(StateError('No pudimos abrir la sala privada.'));
      });
      await ready.future.timeout(const Duration(seconds: 15));
    }
  }

  Future<void> _close() async {
    for (final c in List<RealtimeChannel>.of(_channels)) {
      await client.removeChannel(c);
    }
    _channels.clear();
    _outgoing = null;
    _room = null;
  }

  Future<void> dispose({bool cancelRoom = true}) async {
    final room = _room;
    _disposed = true;
    if (cancelRoom && room != null) {
      try {
        await _outgoing
            ?.sendBroadcastMessage(event: 'frame', payload: {'kind': 'leave'})
            .timeout(const Duration(seconds: 2));
      } catch (_) {}
      try {
        await client
            .rpc('guardian_room', params: {'p_action': 'cancel', 'p_id': room})
            .timeout(const Duration(seconds: 4));
      } catch (_) {}
    }
    emit = null;
    await _close();
  }
}
