import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'verified cooperative replay pays both accounts once and rejects guest/forged claims',
    () async {
      final env = jsonDecode(File('env.json').readAsStringSync()) as Map;
      final users =
          jsonDecode(File('outputs/guardian-qa-users.json').readAsStringSync())
              as List;
      final data =
          jsonDecode(
                File('outputs/guardian-qa-victory.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final clients = <SupabaseClient>[];
      try {
        for (final u in users.take(2)) {
          final c = SupabaseClient(
            env['SUPABASE_URL'] as String,
            env['SUPABASE_ANON_KEY'] as String,
          );
          clients.add(c);
          await c.auth.signInWithPassword(
            email: u['email'] as String,
            password: u['password'] as String,
          );
        }
        final h = clients[0], g = clients[1];
        for (var player = 0; player < 2; player++) {
          final packets = (data['packets'] as List)[player] as List;
          for (var i = 0; i < packets.length; i += 128) {
            await clients[player].rpc(
              'guardian_room',
              params: {
                'p_action': 'inputs',
                'p_id': data['room'],
                'p_packets': packets.sublist(
                  i,
                  (i + 128).clamp(0, packets.length),
                ),
              },
            );
          }
        }
        final info = Map<String, dynamic>.from(
          await h.rpc(
                'guardian_room',
                params: {'p_action': 'status', 'p_id': data['room']},
              )
              as Map,
        );
        final elapsed =
            DateTime.parse(info['server_time'] as String)
                .difference(DateTime.parse(info['started_at'] as String))
                .inMilliseconds /
            1000;
        final required = (data['frames'] as int) / 60;
        if (elapsed < required)
          await Future<void>.delayed(
            Duration(milliseconds: ((required - elapsed + 1) * 1000).ceil()),
          );
        await g.rpc(
          'guardian_room',
          params: {
            'p_action': 'confirm',
            'p_id': data['room'],
            'p_packets': {'hash': data['hash']},
          },
        );
        Future<int> balance(SupabaseClient c) async {
          final row = await c
              .from('game_stats')
              .select('love_coins')
              .eq('user_id', c.auth.currentUser!.id)
              .maybeSingle();
          return row?['love_coins'] as int? ?? 0;
        }

        final before = await Future.wait(clients.map(balance));
        final payload = {
          for (final key in ['room', 'frames', 'events', 'refs'])
            key: data[key],
        };
        final result = await h.functions.invoke(
          'guardian-adventure',
          body: payload,
        );
        expect(result.status, 200);
        expect(result.data['saved'], true);
        final reward = result.data['reward'] as int;
        expect(reward, greaterThan(0));
        final after = await Future.wait(clients.map(balance));
        for (var i = 0; i < 2; i++) expect(after[i] - before[i], reward);
        final repeat = await h.functions.invoke(
          'guardian-adventure',
          body: payload,
        );
        expect(repeat.data['reward'], reward);
        expect(await Future.wait(clients.map(balance)), after);
        await expectLater(
          g.functions.invoke('guardian-adventure', body: payload),
          throwsA(isA<FunctionException>()),
        );
        final bad = Map<String, dynamic>.from(payload);
        bad['refs'] = [
          for (var i = 0; i < (data['refs'] as List).length; i++) 1,
        ];
        await expectLater(
          h.functions.invoke('guardian-adventure', body: bad),
          throwsA(isA<FunctionException>()),
        );
        expect(await Future.wait(clients.map(balance)), after);
        File('outputs/guardian-reward-live-result.json').writeAsStringSync(
          jsonEncode({
            'saved': true,
            'reward_per_player': reward,
            'idempotent': true,
            'guest_claim_rejected': true,
            'forged_replay_rejected': true,
          }),
        );
      } finally {
        for (final c in clients) await c.dispose();
      }
    },
    skip: !const bool.fromEnvironment('GUARDIAN_LIVE_QA'),
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
