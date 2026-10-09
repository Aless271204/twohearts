import 'package:flutter/material.dart';
import '../../widgets/rose_ui.dart';
import '../../theme/app_theme.dart';
import '../../services/game_service.dart';
import '../../services/inventory_service.dart';
import '../shop_screen/shop_screen.dart';
import 'pebble_runner_test.dart';
import 'duo_game_screen.dart';

class GameHubScreen extends StatefulWidget {
  const GameHubScreen({super.key});
  @override
  State<GameHubScreen> createState() => _GameHubScreenState();
}

class _GameHubScreenState extends State<GameHubScreen> {
  final inventory = InventoryService.instance;
  @override
  void initState() {
    super.initState();
    inventory.addListener(_changed);
    _load();
  }

  @override
  void dispose() {
    inventory.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    await GameService.instance.retryPendingRunnerRewards();
    await inventory.refresh().catchError((Object _) {});
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.backgroundLight,
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _featuredForest(),
          const SizedBox(height: 20),
          const Text('Todos los juegos', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _card(
            '🏓',
            'Ping pong en pareja',
            'Cancha vertical y una paleta por celular. Rondas de 7 puntos; el primero en ganar 2 rondas gana.',
            const Color(0xFFEBD5EB),
            () => _open(const DuoGameScreen(game: 'pong')),
          ),
          _card(
            '💌',
            '¿Quién conoce mejor al otro?',
            'Elige en secreto, adivina a tu pareja y descubre sus respuestas. 3 opciones, cuenta regresiva y mejor de 3 rondas.',
            const Color(0xFFF7DECC),
            () => _open(const DuoGameScreen(game: 'quiz')),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () => _open(const ShopScreen()),
            icon: const Icon(Icons.checkroom),
            label: const Text('Personalizar · Tienda e inventario'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Los juegos en pareja entregan 20 LoveCoins al ganador y 8 a su pareja, hasta 300 al día. Las partidas canceladas no entregan monedas. En el bosque, las monedas se guardan al terminar una carrera validada.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    ),
  );
  Widget _card(
    String emoji,
    String title,
    String description,
    Color color,
    VoidCallback action,
  ) => Card(
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 10),
    child: InkWell(
      onTap: action,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(16), child: SizedBox(width: 86, height: 100, child: GameArt(panel: emoji == '🏓' ? 1 : 2))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF786C74), height: 1.4)),
            const SizedBox(height: 8),
            FilledButton(onPressed: action, child: const Text('Jugar')),
            ])),
            const Icon(Icons.chevron_right, color: Color(0xFF9C8991)),
          ],
        ),
      ),
    ),
  );
  Widget _featuredForest() => SizedBox(height: 320, child: ClipRRect(borderRadius: BorderRadius.circular(26), child: Stack(fit: StackFit.expand, children: [
    const GameArt(panel: 0),
    const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x08000000), Color(0xB5223B2E)]))),
    Positioned(top: 16, left: 16, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)), child: const Text('DESTACADO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)))),
    Positioned(left: 20, right: 20, bottom: 20, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Corre con tu mascota', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      const Text('Un bosque lleno de vida. Salta, recoge corazones y supera tu récord.', style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
      const SizedBox(height: 12),
      FilledButton(onPressed: () => _open(const PebbleRunnerTest()), child: const Text('Jugar ahora')),
    ])),
  ])));
}
