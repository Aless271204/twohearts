import 'package:flutter/material.dart';
import '../services/pet_voice_service.dart';

class PetMessagesSheet extends StatefulWidget {
  const PetMessagesSheet({super.key});
  @override State<PetMessagesSheet> createState() => _PetMessagesSheetState();
}
class _PetMessagesSheetState extends State<PetMessagesSheet> {
  final _text = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _busy = false;
  String? _notice;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { final result = await PetVoiceService.instance.messages(); if (mounted) setState(() => _messages = result); }
    catch (_) { if (mounted) setState(() => _notice = 'No pudimos cargar los mensajes. Comprueba tu conexión.'); }
  }
  Future<void> _action(Future<void> Function() action) async {
    if (_busy) return;
    setState(() { _busy = true; _notice = null; });
    try { await action(); }
    catch (_) { if (mounted) setState(() => _notice = 'No se completó. Comprueba tu conexión y que Android tenga voz y dictado en español disponibles.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override void dispose() { PetVoiceService.instance.stop(); _text.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => SafeArea(child: Padding(
    padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
    child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Pip tiene algo que decir', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Escribe o dicta y revisa el mensaje. Pip lo dirá con su voz. Tu pareja podrá escucharlo hasta 5 veces; después se elimina.'),
      const SizedBox(height: 12),
      TextField(controller: _text, maxLength: 500, maxLines: 3, enabled: !_busy, decoration: const InputDecoration(labelText: 'Mensaje para tu pareja', border: OutlineInputBorder())),
      Wrap(spacing: 8, children: [
        TextButton.icon(onPressed: _busy ? null : () => _action(() async { final text = await PetVoiceService.instance.dictate(); if (mounted) _text.text = text; }), icon: const Icon(Icons.mic), label: const Text('Dictar')),
        TextButton.icon(onPressed: _busy ? null : () => _action(() async { if (_text.text.trim().isEmpty) return; await PetVoiceService.instance.prepare(); await PetVoiceService.instance.speak(_text.text.trim()); }), icon: const Icon(Icons.volume_up), label: const Text('Probar voz')),
        FilledButton(onPressed: _busy ? null : () => _action(() async { if (_text.text.trim().isEmpty) return; await PetVoiceService.instance.send(_text.text); if (mounted) { _text.clear(); setState(() => _notice = 'Pip entregará tu mensaje a tu pareja.'); } }), child: const Text('Enviar')),
      ]),
      if (_busy) const LinearProgressIndicator(),
      if (_notice != null) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(_notice!)),
      const Divider(),
      Row(children: [const Expanded(child: Text('Mensajes para ti', style: TextStyle(fontWeight: FontWeight.bold))), IconButton(onPressed: _busy ? null : _load, icon: const Icon(Icons.refresh))]),
      if (_messages.isEmpty) const Text('Todavía no tienes mensajes pendientes.'),
      for (final message in _messages) ListTile(leading: const Icon(Icons.pets), title: const Text('Un mensaje de tu pareja'), subtitle: Text('${message['remaining']} escuchas disponibles'), trailing: IconButton(icon: const Icon(Icons.play_arrow), onPressed: _busy ? null : () => _action(() async { await PetVoiceService.instance.play(message['id'] as String); await _load(); }))),
      const SizedBox(height: 8),
      const Text('Prueba de voz de Pip: el timbre depende de la voz española instalada en Android. El dictado requiere reconocimiento local compatible.', style: TextStyle(fontSize: 12)),
    ])),
  ));
}
