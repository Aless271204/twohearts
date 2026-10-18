import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import '../services/profile_change_notifier.dart';

class CoupleCareSettings extends StatefulWidget {
  const CoupleCareSettings({super.key});
  @override
  State<CoupleCareSettings> createState() => _CoupleCareSettingsState();
}

class _CoupleCareSettingsState extends State<CoupleCareSettings> {
  static const channel = MethodChannel('nido/reminders');
  bool daily = false, moods = false, sharing = false, busy = false;
  String? mood, start;
  TimeOfDay time = const TimeOfDay(hour: 19, minute: 0);
  static const labels = {
    'happy': '😊 Feliz',
    'calm': '🌿 En calma',
    'tired': '😴 Cansancio',
    'sad': '💙 Triste',
    'stressed': '🌧 Estrés',
    'affectionate': '💕 Cariño',
  };
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    try {
      final state =
          await SupabaseService.instance.client.rpc('couple_state') as Map;
      if (!mounted) return;
      setState(() {
        mood = state['mine']?['mood'] as String?;
        sharing = state['mine']?['sharing'] == true;
        start = state['start']?.toString();
      });
    } catch (_) {}
    if (mounted)
      setState(() {
        daily = p.getBool('care_daily') ?? false;
        moods = p.getBool('care_moods') ?? false;
        time = TimeOfDay(
          hour: p.getInt('care_hour') ?? 19,
          minute: p.getInt('care_minute') ?? 0,
        );
      });
  }

  void problem(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> alerts(bool d, bool m) async {
    try {
      if (kIsWeb) {
        problem('Activa los avisos desde la app instalada.');
        return;
      }
      if ((d || m) && !(await Permission.notification.request()).isGranted) {
        problem(
          'Activa el permiso de notificaciones en los ajustes del teléfono.',
        );
        return;
      }
      await channel.invokeMethod('configure', {
        'daily': d,
        'moods': m,
        'hour': time.hour,
        'minute': time.minute,
      });
      final p = await SharedPreferences.getInstance();
      await p.setBool('care_daily', d);
      await p.setBool('care_moods', m);
      await p.setInt('care_hour', time.hour);
      await p.setInt('care_minute', time.minute);
      if (mounted)
        setState(() {
          daily = d;
          moods = m;
        });
    } catch (_) {
      problem('No pudimos activar los avisos en este dispositivo.');
    }
  }

  Future<void> saveMood(String value, bool share) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await SupabaseService.instance.client.rpc(
        'couple_state',
        params: {
          'p_action': 'mood',
          'p_data': {'mood': value, 'sharing': share},
        },
      );
      if (mounted)
        setState(() {
          mood = value;
          sharing = share;
        });
    } catch (_) {
      problem('No se guardó el estado de ánimo. Vuelve a intentar.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> anniversary() async {
    final now = DateTime.now();
    final current = DateTime.tryParse(start ?? '');
    final picked = await showDatePicker(
      context: context,
      initialDate: current != null && !current.isAfter(now) ? current : now,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null) return;
    try {
      await SupabaseService.instance.client.rpc(
        'couple_state',
        params: {
          'p_action': 'anniversary',
          'p_data': {'start': picked.toIso8601String().split('T').first},
        },
      );
      ProfileChangeNotifier.instance.notify();
      await load();
    } catch (_) {
      problem('No se pudo guardar su fecha. Vuelve a intentar.');
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.favorite_outline,
              color: Color(0xFFF05280),
            ),
            title: const Text('Nuestra fecha'),
            subtitle: Text(start ?? 'Añadan el día en que comenzó su historia'),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: anniversary,
          ),
          const Text(
            '¿Cómo te sientes hoy?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Wrap(
            spacing: 5,
            children: [
              for (final entry in labels.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: mood == entry.key,
                  onSelected: busy ? null : (_) => saveMood(entry.key, sharing),
                ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Compartir mi ánimo con mi pareja'),
            value: sharing,
            onChanged: mood == null || busy ? null : (v) => saveMood(mood!, v),
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Un recordatorio para compartir'),
            subtitle: Text('Cada día · ${time.format(context)}'),
            value: daily,
            onChanged: (v) => alerts(v, moods),
          ),
          if (daily)
            TextButton.icon(
              onPressed: () async {
                final chosen = await showTimePicker(
                  context: context,
                  initialTime: time,
                );
                if (chosen != null) {
                  setState(() => time = chosen);
                  await alerts(daily, moods);
                }
              },
              icon: const Icon(Icons.schedule),
              label: const Text('Cambiar hora'),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Avisarme del ánimo de mi pareja'),
            subtitle: const Text('Solo cuando decida compartirlo'),
            value: moods,
            onChanged: (v) => alerts(daily, v),
          ),
        ],
      ),
    ),
  );
}
