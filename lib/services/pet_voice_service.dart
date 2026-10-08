import 'package:flutter/services.dart';
import 'supabase_service.dart';

/// Pilot voice: one Spanish mascot preset, synthesized from text on Android.
/// No original recording or rendered audio is stored by NIDO.
class PetVoiceService {
  static const _channel = MethodChannel('nido/pet_voice');
  static final instance = PetVoiceService();
  Future<void> prepare() async {
    final ready = await _channel.invokeMethod<bool>('prepare').timeout(const Duration(seconds: 15));
    if (ready != true) throw StateError('Instala una voz en español en los ajustes de voz de Android.');
  }
  Future<void> speak(String text) async {
    try { await _channel.invokeMethod('speak', {'text': text}).timeout(const Duration(seconds: 60)); } catch (_) { await stop(); rethrow; }
  }
  Future<String> dictate() async {
    try { return await _channel.invokeMethod<String>('dictate').timeout(const Duration(seconds: 30)) ?? ''; } catch (_) { await stop(); rethrow; }
  }
  Future<void> stop() async { try { await _channel.invokeMethod('stop'); } catch (_) {} }
  Future<List<Map<String, dynamic>>> messages() async {
    final result = await SupabaseService.instance.client.rpc('pet_message_list');
    return (result as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  Future<void> send(String text) async {
    await SupabaseService.instance.client.rpc('pet_message_send', params: {'p_content': text.trim()});
  }
  Future<int> play(String id) async {
    await prepare(); // Check the voice before consuming a playback.
    final result = Map<String, dynamic>.from(await SupabaseService.instance.client.rpc('pet_message_play', params: {'p_id': id}) as Map);
    final text = result.remove('content') as String;
    await speak(text);
    return result['remaining'] as int;
  }
}
