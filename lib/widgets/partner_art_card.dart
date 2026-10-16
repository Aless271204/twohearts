import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/partner_art_service.dart';
import '../presentation/games/art_game_screen.dart';

class PartnerArtCard extends StatefulWidget {
  final bool preview;
  const PartnerArtCard({super.key, this.preview = false});
  @override
  State<PartnerArtCard> createState() => _PartnerArtCardState();
}

class _PartnerArtCardState extends State<PartnerArtCard> {
  bool busy = false;
  void _message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _send(String kind, String value) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await PartnerArtService.instance.send(kind, value);
      _message('Enviado a tu pareja 💗');
    } catch (_) {
      _message(
        'No se pudo enviar. Comprueba internet y que sus cuentas estén enlazadas.',
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _write() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Una nota para tu amor'),
        content: TextField(
          controller: ctrl,
          maxLength: 500,
          maxLines: 5,
          minLines: 2,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Hoy quería decirte…'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    ctrl.dispose();
    if (result != null && result.isNotEmpty) await _send('text', result);
  }

  Future<void> _photo(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file == null) return;
      final data = await file.readAsBytes(),
          codec = await ui.instantiateImageCodec(data, targetWidth: 512);
      final image = (await codec.getNextFrame()).image;
      codec.dispose();
      final rec = ui.PictureRecorder(), canvas = Canvas(rec);
      canvas.drawColor(Colors.white, BlendMode.src);
      final fit = applyBoxFit(
        BoxFit.contain,
        Size(image.width.toDouble(), image.height.toDouble()),
        const Size.square(512),
      );
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Alignment.center.inscribe(
          fit.destination,
          const Rect.fromLTWH(0, 0, 512, 512),
        ),
        Paint()..filterQuality = FilterQuality.high,
      );
      final pic = rec.endRecording(), output = await pic.toImage(512, 512);
      final png = (await output.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List();
      image.dispose();
      output.dispose();
      pic.dispose();
      if (!mounted) return;
      final send = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('¿Enviar esta foto a tu pareja?'),
          content: Image.memory(png),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enviar'),
            ),
          ],
        ),
      );
      if (send == true) await _send('image', base64Encode(png));
    } catch (_) {
      _message(
        'No pudimos abrir la foto. Revisa el permiso de cámara o prueba desde tu galería.',
      );
    }
  }

  Uint8List? _image(Map<String, dynamic> note) {
    try {
      return note['kind'] == 'image'
          ? base64Decode(note['content'] as String)
          : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: PartnerArtService.instance,
    builder: (context, _) {
      final note = PartnerArtService.instance.latest, image = _image(note);
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFF4D8DF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.favorite, color: Color(0xFFDF7094)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Un pedacito de tu día',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  image,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              )
            else
              Text(
                note['content'] as String? ??
                    'Una foto, una nota o un dibujo: algo tuyo para acompañar a tu pareja.',
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            if (note['sent_at'] != null)
              const Padding(
                padding: EdgeInsets.only(top: 5),
                child: Text(
                  'Lo último que te envió tu pareja',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _action(
                  'Tomar foto',
                  Icons.camera_alt,
                  () => _photo(ImageSource.camera),
                ),
                _action('Escribir', Icons.edit_note, _write),
                _action(
                  'Dibujar',
                  Icons.palette,
                  () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ArtGameScreen(freeDraw: true),
                    ),
                  ),
                ),
                _action(
                  'Galería',
                  Icons.photo_library,
                  () => _photo(ImageSource.gallery),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: widget.preview
                  ? null
                  : () async {
                      try {
                        final ok = await PartnerArtService.instance.pin();
                        _message(
                          ok
                              ? 'Confirma añadir el widget en tu pantalla de inicio'
                              : 'Mantén pulsado el inicio de tu teléfono → Widgets → NIDO',
                        );
                      } catch (_) {
                        _message(
                          'Añádelo desde Widgets → NIDO en la pantalla de inicio de tu teléfono.',
                        );
                      }
                    },
              icon: const Icon(Icons.widgets_outlined),
              label: const Text('Widget de fotos y mensajes'),
            ),
            TextButton.icon(
              onPressed: widget.preview
                  ? null
                  : () async {
                      try {
                        final ok = await PartnerArtService.instance.pin(
                          history: true,
                        );
                        _message(
                          ok
                              ? 'Confirma añadir Nuestra historia'
                              : 'Mantén pulsado el inicio → Widgets → NIDO → Nuestra historia',
                        );
                      } catch (_) {
                        _message(
                          'Añade Nuestra historia desde Widgets → NIDO.',
                        );
                      }
                    },
              icon: const Icon(Icons.favorite_outline),
              label: const Text('Widget de aniversario y distancia'),
            ),
            const Text(
              'En teléfonos compatibles puedes añadirlos también a la pantalla de bloqueo desde los ajustes de Android. La distancia muestra la última ubicación compartida; toca el widget para abrir NIDO y actualizarla.',
            ),
            const Text(
              'Tu pareja añade el widget en su teléfono. Se actualiza al abrir NIDO y periódicamente en segundo plano; Android puede retrasarlo para ahorrar batería.',
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: Colors.black54,
              ),
            ),
            if (busy) const LinearProgressIndicator(),
          ],
        ),
      );
    },
  );
  Widget _action(String title, IconData icon, VoidCallback onTap) =>
      FilledButton.tonalIcon(
        onPressed: busy || widget.preview ? null : onTap,
        icon: Icon(icon, size: 18),
        label: Text(title),
      );
}
