import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

const rankingGames = {
  'pebble_runner': 'Senderos del Nido', 'guardian': 'Guardianes del Alba',
  'pong': 'Peloteo con amor', 'quiz': '¿Cuánto nos conocemos?',
  'art': 'Pincel en pareja', 'penalties': 'Goles y abrazos', 'maze': 'Farolitos del Nido',
};
Map<String, String> rankingScopes(String game) {
  const levels = {'easy': 'Fácil', 'medium': 'Medio', 'hard': 'Difícil'};
  if (game == 'pebble_runner') return {'distance': 'Mayor distancia'};
  if (game == 'art') return {'wins:0': 'Fácil · Racha', 'wins:1': 'Medio · Racha', 'wins:2': 'Difícil · Racha'};
  if (game == 'guardian' || game == 'maze') return {
    for (final level in levels.entries)
      for (final mode in ['solo', 'partner'])
        if (game == 'guardian')
          for (final chapter in ['forest', 'river'])
            '${level.key}:$mode:$chapter': '${level.value} · ${mode == 'solo' ? 'Solo' : 'Pareja'} · ${chapter == 'forest' ? 'Bosque' : 'Río'}'
        else '${level.key}:$mode': '${level.value} · ${mode == 'solo' ? 'Solo' : 'Pareja'}',
  };
  return {'wins': 'Mejor racha de victorias'};
}

String rankingScore(String game, num value) {
  final score = value.toInt();
  if (game == 'pebble_runner') return '$score m';
  if (game == 'guardian') {
    final seconds = ((21601 - score).clamp(0, 21600) / 60).round();
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
  if (game == 'maze') return '${(1000000 - score).clamp(0, 1000000)} pasos';
  return '$score ${score == 1 ? 'victoria' : 'victorias'}';
}

typedef RankingLoader = Future<Map<String, dynamic>> Function(String game, String audience, String scope, bool? visible);

class NidoRanking extends StatefulWidget {
  final bool previewMode;
  final RankingLoader? loader;
  const NidoRanking({super.key, this.previewMode = false, this.loader});
  @override
  State<NidoRanking> createState() => _NidoRankingState();
}

class _NidoRankingState extends State<NidoRanking> {
  String game = 'pebble_runner', scope = 'distance', audience = 'friends';
  Map<String, dynamic>? data;
  bool loading = true;
  String? error;
  int generation = 0;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load({bool? visible}) async {
    final request = ++generation;
    setState(() { loading = true; error = null; });
    try {
      final result = widget.loader != null
        ? await widget.loader!(game, audience, scope, visible)
        : widget.previewMode ? <String, dynamic>{'rows': [], 'global_visible': false}
        : Map<String, dynamic>.from(await SupabaseService.instance.client.rpc('social_weekly_ranking', params: {
          'p_game': game, 'p_audience': audience, 'p_scope': scope,
          if (visible != null) 'p_visible': visible,
        }) as Map);
      if (mounted && request == generation) setState(() { data = result; loading = false; });
    } catch (_) {
      if (mounted && request == generation) setState(() { loading = false; error = 'No pudimos cargar el ranking. Inténtalo nuevamente.'; });
    }
  }
  @override
  void dispose() { generation++; super.dispose(); }
  String _date(dynamic raw) {
    final date = DateTime.tryParse(raw?.toString() ?? '')?.toUtc().subtract(const Duration(hours: 5));
    return date == null ? '' : '${date.day}/${date.month}';
  }
  @override
  Widget build(BuildContext context) {
    final rows = (data?['rows'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final mine = data?['mine'] as Map?;
    return RefreshIndicator(onRefresh: _load, child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SegmentedButton<String>(showSelectedIcon: false, segments: const [
          ButtonSegment(value: 'friends', label: Text('Amigos')),
          ButtonSegment(value: 'global', label: Text('Global')),
        ], selected: {audience}, onSelectionChanged: (s) {
          setState(() { audience = s.first; data = null; }); _load();
        }),
        const SizedBox(height: 18),
        Row(children: [const Icon(Icons.emoji_events_rounded, color: Color(0xFFB88633)), const SizedBox(width: 8),
          const Expanded(child: Text('Esta semana', style: TextStyle(fontSize: 25, fontFamily: 'Georgia', fontWeight: FontWeight.bold))),
          if (data?['week_start'] != null) Text('${_date(data!['week_start'])} – ${_date(data!['week_end'])}', style: const TextStyle(fontSize: 12, color: Color(0xFF75636B))),
        ]),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: game, isExpanded: true,
          decoration: const InputDecoration(labelText: 'Juego', border: OutlineInputBorder()),
          items: [for (final entry in rankingGames.entries) DropdownMenuItem(value: entry.key, child: Text(entry.value))],
          onChanged: (value) { if (value == null) return; setState(() { game = value; scope = rankingScopes(game).keys.first; data = null; }); _load(); }),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(key: ValueKey(game), value: scope, isExpanded: true,
          decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
          items: [for (final entry in rankingScopes(game).entries) DropdownMenuItem(value: entry.key, child: Text(entry.value, overflow: TextOverflow.ellipsis))],
          onChanged: (value) { if (value == null) return; setState(() { scope = value; data = null; }); _load(); }),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: const Color(0xFFFFE9DB), borderRadius: BorderRadius.circular(20)),
          child: Row(children: [const Icon(Icons.stars_rounded, color: Color(0xFFBD7651), size: 34), const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Tu récord semanal', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF684A40))),
              const SizedBox(height: 4),
              Text(loading ? 'Cargando…' : mine == null ? 'Aún no hay una partida guardada' : rankingScore(game, mine['score'] as num),
                style: const TextStyle(fontSize: 18, color: Color(0xFF4B3C38))),
              if (!loading && mine?['rank'] != null) Text('Puesto ${mine!['rank']}', style: const TextStyle(color: Color(0xFF705D51))),
            ])),
          ])),
        if (audience == 'global' && !widget.previewMode) SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero, title: const Text('Aparecer en Global', style: TextStyle(fontSize: 14)),
          subtitle: const Text('Comparte tu nombre y récord, sin datos de tu pareja.', style: TextStyle(fontSize: 11)),
          value: data?['global_visible'] == true,
          onChanged: loading || data == null ? null : (v) => _load(visible: v)),
        const SizedBox(height: 12),
        if (loading) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else if (error != null) Column(children: [Text(error!, textAlign: TextAlign.center), TextButton(onPressed: _load, child: const Text('Reintentar'))])
        else if (rows.isEmpty) const Padding(padding: EdgeInsets.all(22), child: Text('Una nueva semana para brillar.\nLos resultados aparecerán al guardar partidas verificadas.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF75636B), height: 1.6)))
        else for (final row in rows) Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: row['is_me'] == true ? const Color(0xFFFFE0EA) : Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [SizedBox(width: 36, child: Text('#${row['rank']}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF976B44)))),
            Expanded(child: Text(row['is_me'] == true ? '${row['name']} · Tú' : row['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8), Text(rankingScore(game, row['score'] as num), style: const TextStyle(color: Color(0xFF755465), fontWeight: FontWeight.w700)),
          ])),
        const SizedBox(height: 10),
        Text(audience == 'friends' ? 'Tú, tu pareja y amistades que se siguen mutuamente. Reinicio los lunes · hora de Ecuador continental.' : 'Solo aparecen quienes activan su participación. Reinicio los lunes · hora de Ecuador continental.',
          textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Color(0xFF75636B), height: 1.5)),
      ],
    ));
  }
}
