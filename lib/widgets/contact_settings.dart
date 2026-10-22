import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactSettings extends StatefulWidget {
  final Future<bool> Function(Uri)? openMail;
  const ContactSettings({super.key, this.openMail});
  static const email = 'alessandroproyectos@gmail.com';

  @override
  State<ContactSettings> createState() => _ContactSettingsState();
}

class _ContactSettingsState extends State<ContactSettings> {
  final _suggestion = TextEditingController();
  bool _opening = false;

  @override
  void dispose() {
    _suggestion.dispose();
    super.dispose();
  }

  Future<void> _compose(String subject, String body) async {
    if (_opening) return;
    setState(() => _opening = true);
    // Encode mailto spaces as %20 for compatibility with native mail clients.
    final uri = Uri(
      scheme: 'mailto',
      path: ContactSettings.email,
      query:
          'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
    bool opened;
    try {
      opened = await (widget.openMail?.call(uri) ?? launchUrl(uri));
    } catch (_) {
      opened = false;
    }
    if (!mounted) return;
    setState(() => _opening = false);
    if (opened) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abre tu correo'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No pudimos abrir una aplicación de correo. Puedes escribirnos a:',
            ),
            SizedBox(height: 12),
            SelectableText(ContactSettings.email),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Clipboard.setData(
              const ClipboardData(text: ContactSettings.email),
            ),
            child: const Text('Copiar correo'),
          ),
          TextButton(
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: '$subject\n\n$body')),
            child: const Text('Copiar mensaje'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          leading: const Icon(Icons.lightbulb_outline_rounded),
          title: const Text('Recomendación'),
          subtitle: const Text('Tus ideas hacen crecer Nido'),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            TextField(
              controller: _suggestion,
              minLines: 3,
              maxLines: 5,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Tu sugerencia',
                hintText: '¿Qué te gustaría mejorar o encontrar en Nido?',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _suggestion,
              builder: (context, value, _) => FilledButton.icon(
                onPressed: _opening || value.text.trim().isEmpty
                    ? null
                    : () => _compose('Sugerencia para Nido', value.text.trim()),
                icon: const Icon(Icons.mail_outline_rounded),
                label: const Text('Enviar sugerencia por correo'),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Card(
        elevation: 0,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 5,
          ),
          leading: const Icon(Icons.work_outline_rounded),
          title: const Text('Trabaja con nosotros'),
          subtitle: const Text('Abre tu correo y adjunta tu CV'),
          trailing: const Icon(Icons.open_in_new_rounded, size: 19),
          onTap: _opening
              ? null
              : () => _compose(
                  'Trabaja con nosotros · Nido',
                  'Hola, equipo de Nido:\n\nMe gustaría trabajar con ustedes.\n\n'
                      'Mi nombre:\nÁrea en la que me gustaría colaborar:\n\n'
                      'Adjunto mi CV a este correo.\n\nSaludos.',
                ),
        ),
      ),
    ],
  );
}
