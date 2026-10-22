import 'package:flutter/material.dart';
import 'animated_game_cover.dart';

/// Shared forest palette, chapter art and clear actions used by the minigame launchers.
class GameMenuHero extends StatelessWidget {
  final String title, subtitle;
  final int panel;
  const GameMenuHero({
    super.key,
    required this.title,
    required this.subtitle,
    required this.panel,
  });
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: SizedBox(
      height: 190,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedGameCover(panel: panel),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0xCE172D2A)],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 17,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'NidoSerif',
                    fontSize: 29,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFFFE9BD),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class GameLaunchMenu extends StatelessWidget {
  final String game;
  const GameLaunchMenu({super.key, required this.game});
  @override
  Widget build(BuildContext context) {
    final pong = game == 'pong';
    return Dialog.fullscreen(
      backgroundColor: const Color(0xFF173D33),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(22),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'NIDO · JUGAMOS JUNTOS',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          color: Color(0xFFDCE9D3),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Volver',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFFFFF6DF),
                      ),
                    ),
                  ],
                ),
                GameMenuHero(
                  title: pong ? 'Ping pong' : '¿Cuánto nos conocemos?',
                  subtitle: pong
                      ? 'Regalos, efectos y una partida más'
                      : 'Una pregunta, dos miradas',
                  panel: pong ? 1 : 2,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Elige cómo jugar',
                  style: TextStyle(
                    fontFamily: 'NidoSerif',
                    fontSize: 23,
                    color: Color(0xFFFFF6DF),
                  ),
                ),
                const SizedBox(height: 14),
                for (final option in const [
                  ('partner', 'Con mi pareja', Icons.favorite_rounded),
                  ('create', 'Crear sala', Icons.add_circle_outline_rounded),
                  ('join', 'Unirme con código', Icons.key_rounded),
                  ('train', 'Entrenar a solas', Icons.sports_esports_rounded),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context, option.$1),
                      style: FilledButton.styleFrom(
                        backgroundColor: option.$1 == 'partner'
                            ? const Color(0xFFDFC076)
                            : const Color(0xFFF0E8DA),
                        foregroundColor: const Color(0xFF304535),
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      icon: Icon(option.$3),
                      label: Text(option.$2),
                    ),
                  ),
                TextButton.icon(
                  onPressed: () => Navigator.pop(context, 'random'),
                  icon: const Icon(Icons.public),
                  label: const Text('Buscar rival online'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFDCE9D3),
                  ),
                ),
                const ExpansionTile(
                  textColor: Color(0xFFFFF6DF),
                  collapsedTextColor: Color(0xFFFFF6DF),
                  iconColor: Color(0xFFFFF6DF),
                  collapsedIconColor: Color(0xFFFFF6DF),
                  title: Text('Cómo jugar', style: TextStyle(fontSize: 13)),
                  leading: Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFDCE9D3),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(14),
                      child: Text(
                        'Crea una sala o entra con su código para jugar juntos. El entrenamiento es una práctica con Nube y no entrega monedas.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFDCE9D3),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
