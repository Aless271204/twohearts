import 'package:flutter/material.dart';
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
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFF7F5),
    appBar: AppBar(
      title: const Text('Jugar juntos'),
      actions: [
        TextButton.icon(
          onPressed: () => _open(const ShopScreen()),
          icon: const Icon(Icons.inventory_2_outlined),
          label: Text('🪙 ${inventory.coins}'),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Un ratito para ustedes',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vinculen sus cuentas y abran el mismo juego desde sus celulares. Pip también puede acompañarte cuando juegues a solas.',
          ),
          const SizedBox(height: 20),
          _card(
            '🐧',
            'Corre en pareja · Bosque',
            'Corre con Pip, salta y recoge monedas. Tu mochila y accesorios te acompañan.',
            const Color(0xFFD5E7DA),
            () => _open(const PebbleRunnerTest()),
          ),
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
    color: color,
    margin: const EdgeInsets.only(bottom: 16),
    child: InkWell(
      onTap: action,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 14),
            const Row(
              children: [
                Text('Jugar', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
