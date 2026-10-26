import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneWidgetSettings extends StatelessWidget {
  const PhoneWidgetSettings({super.key});
  @override
  Widget build(BuildContext context) {
    final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return Card(
      color: const Color(0xfff1f4e9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: const Icon(Icons.widgets_rounded, color: Color(0xff64765b)),
        title: const Text('Widgets del teléfono'),
        subtitle: Text(
          android
              ? 'Tu marco, sus mascotas y un pedacito de nosotros. Personalízalos cuando quieras.'
              : 'Disponibles en Android: notas, días juntos, aniversario, frase diaria y distancia.',
        ),
        trailing: android ? const Icon(Icons.chevron_right_rounded) : null,
        onTap: android
            ? () async {
                try {
                  await const MethodChannel(
                    'nido/art',
                  ).invokeMethod('openWidgetSettings');
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Actualiza NIDO para usar el personalizador. También puedes añadir widgets desde la pantalla de inicio.',
                        ),
                      ),
                    );
                  }
                }
              }
            : null,
      ),
    );
  }
}
