import 'dart:convert';
import '../services/game_service.dart';
import '../services/inventory_service.dart';

class RunnerBridge {
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
        case 'cosmetics':
          await InventoryService.instance.refresh();
          response['result'] = {
            for (final e in InventoryService.instance.loadout.entries)
              e.key: e.value.appearance,
          };
        case 'start':
          response['result'] = await GameService.instance.startRunnerSession();
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
