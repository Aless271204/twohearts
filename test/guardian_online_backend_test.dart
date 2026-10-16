import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:twohearts/widgets/guardian_bridge.dart';

void main() {
  test(
    'two authenticated accounts exchange private game packets; outsider and forged host are rejected',
    () async {
      final env = jsonDecode(File('env.json').readAsStringSync()) as Map;
      final users =
          jsonDecode(File('outputs/guardian-qa-users.json').readAsStringSync())
              as List;
      final clients = <SupabaseClient>[];
      final bridges = <GuardianBridge>[];
      Future<Map<String, dynamic>> call(
        GuardianBridge bridge,
        String action,
        Map<String, dynamic> payload,
      ) async {
        final r = await bridge.handle(
          jsonEncode({
            'type': 'guardian-request',
            'id': 1,
            'action': action,
            'payload': payload,
          }),
        );
        expect(r['ok'], true, reason: r['error']?.toString());
        return Map<String, dynamic>.from(
          r['result'] is Map ? r['result'] as Map : {'ok': r['result']},
        );
      }

      try {
        for (final u in users) {
          final c = SupabaseClient(
            env['SUPABASE_URL'] as String,
            env['SUPABASE_ANON_KEY'] as String,
          );
          clients.add(c);
          await c.auth.signInWithPassword(
            email: u['email'] as String,
            password: u['password'] as String,
          );
          bridges.add(GuardianBridge(clientOverride: c));
        }
        final h = bridges[0], g = bridges[1], outsider = bridges[2];
        final profile = await call(h, 'room', {'p_action': 'profile'});
        expect(profile['loadout'], isA<List>());
        final locked = await h.handle(
          jsonEncode({
            'type': 'guardian-request',
            'id': 3,
            'action': 'room',
            'payload': {
              'p_action': 'solo',
              'p_species': 'bear',
              'p_difficulty': 'easy',
            },
          }),
        );
        expect(locked['ok'], false);
        final room = await call(h, 'room', {
          'p_action': 'create',
          'p_difficulty': 'easy',
          'p_species': 'penguin',
        });
        expect((room['loadouts'] as List).first, profile['loadout']);
        final joined = await call(g, 'room', {
          'p_action': 'join',
          'p_code': room['code'],
          'p_species': 'penguin',
        });
        expect(joined['role'], 1);
        final hostPacket = Completer<Map<String, dynamic>>(),
            guestPacket = Completer<Map<String, dynamic>>();
        h.emit = (m) async {
          if (!hostPacket.isCompleted) hostPacket.complete(m);
        };
        g.emit = (m) async {
          if (!guestPacket.isCompleted) guestPacket.complete(m);
        };
        await call(h, 'watch', {'room': room['id']});
        await call(g, 'watch', {'room': room['id']});
        await call(h, 'room', {'p_action': 'ready', 'p_id': room['id']});
        final running = await call(g, 'room', {
          'p_action': 'ready',
          'p_id': room['id'],
        });
        expect(running['status'], 'running');
        await call(g, 'send', {
          'data': {
            'kind': 'input',
            'packets': [
              [1, 18],
            ],
          },
        });
        final p = await hostPacket.future.timeout(const Duration(seconds: 12));
        final data = Map<String, dynamic>.from(p['data'] as Map);
        expect((data['payload'] as Map? ?? data)['kind'], 'input');
        await call(h, 'send', {
          'data': {'kind': 'qa-state', 'frame': 60},
        });
        final q = await guestPacket.future.timeout(const Duration(seconds: 12));
        final data2 = Map<String, dynamic>.from(q['data'] as Map);
        expect((data2['payload'] as Map? ?? data2)['kind'], 'qa-state');
        for (final b in [h, g])
          await call(b, 'room', {
            'p_action': 'inputs',
            'p_id': room['id'],
            'p_packets': [
              [1, 18],
            ],
          });
        final denied = await outsider.handle(
          jsonEncode({
            'type': 'guardian-request',
            'id': 2,
            'action': 'watch',
            'payload': {'room': room['id']},
          }),
        );
        expect(denied['ok'], false);
        final privateHost = clients[1].getChannels().firstWhere(
          (c) => c.topic.endsWith(':host'),
        );
        final forged = await privateHost
            .sendBroadcastMessage(
              event: 'frame',
              payload: {'kind': 'forged-host'},
            )
            .timeout(const Duration(seconds: 12));
        expect(forged, isNot(ChannelResponse.ok));
        final read = await call(h, 'room', {
          'p_action': 'status',
          'p_id': room['id'],
        });
        File(
          'outputs/guardian-backend-room.json',
        ).writeAsStringSync(jsonEncode(read));
      } finally {
        for (final b in bridges) await b.dispose(cancelRoom: false);
        for (final c in clients) await c.dispose();
      }
    },
    skip: !const bool.fromEnvironment('GUARDIAN_LIVE_QA'),
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
