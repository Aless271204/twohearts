import 'dart:convert';
import '../services/supabase_service.dart';
import '../services/game_service.dart';
import '../services/inventory_service.dart';

class RunnerBridge {
  final Set<String> _settledPenaltyRounds = {};
  Future<Map<String, dynamic>> handle(String raw) async {
    final message = jsonDecode(raw) as Map<String, dynamic>;
    if (message['type'] != 'runner-request')
      throw const FormatException('Unknown runner message');
    final response = <String, dynamic>{
      'type': 'runner-response',
      'id': message['id'],
    };
    try {
      final payload = message['payload'] as Map<String, dynamic>? ?? {};
      switch (message['action']) {
        case 'maze':
          final result = await SupabaseService.instance.client.functions.invoke(
            'maze-adventure',
            body: payload,
          );
          if (result.status != 200 ||
              result.data is! Map ||
              (result.data as Map)['error'] != null) {
            throw StateError('No pudimos actualizar el laberinto.');
          }
          response['result'] = result.data;
          final mazeData = result.data as Map;
          if (mazeData['status'] == 'finished' &&
              _settledPenaltyRounds.add(
                'maze:${mazeData['id']}:${mazeData['generation']}',
              )) {
            InventoryService.instance.refresh().catchError((Object _) {});
          }
          break;
        case 'penalties':
          final data = await SupabaseService.instance.client.rpc(
            'penalty_room',
            params: payload,
          );
          response['result'] = data;
          if (data is Map &&
              data['status'] == 'finished' &&
              _settledPenaltyRounds.add(
                '${data['id']}:${data['generation']}',
              )) {
            InventoryService.instance.refresh().catchError((Object _) {});
          }
          break;
        case 'cosmetics':
          await InventoryService.instance.refresh();
          response['result'] = {
            for (final e in InventoryService.instance.loadout.entries)
              e.key: e.value.appearance,
          };
        case 'start':
          response['result'] = await GameService.instance.startRunnerSession();
        case 'checkpoint':
          response['result'] = await GameService.instance
              .checkpointRunnerSession(payload);
        case 'finish':
          response['result'] = await GameService.instance.finishRunnerSession(
            payload,
          );
        default:
          throw const FormatException('Unknown runner action');
      }
      response['ok'] = true;
    } catch (_) {
      response['ok'] = false;
      response['error'] =
          'No pudimos guardar la partida. Comprueba tu conexión y vuelve a intentarlo.';
    }
    return response;
  }
}
