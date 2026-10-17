import 'guardian_game_screen.dart';
import 'art_game_screen.dart';
import '../../widgets/animated_game_cover.dart';
import '../../widgets/twohearts_ui.dart';
import '../../widgets/rewarded_gold_card.dart';
import 'package:flutter/material.dart';
import '../../services/game_service.dart';
import '../../services/inventory_service.dart';
import '../shop_screen/shop_screen.dart';
import 'pebble_runner_test.dart';
import 'duo_game_screen.dart';

class GameHubScreen extends StatefulWidget {
  final bool previewMode;
  const GameHubScreen({super.key, this.previewMode = false});
  @override
  State<GameHubScreen> createState() => _GameHubScreenState();
}

class _GameHubScreenState extends State<GameHubScreen> {
  InventoryService get inventory => InventoryService.instance;
  @override
  void initState() {
    super.initState();
    if (!widget.previewMode) inventory.addListener(_changed);
    _load();
  }

  @override
  void dispose() {
    if (!widget.previewMode) inventory.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    if (widget.previewMode) return;
    await GameService.instance.retryPendingRunnerRewards();
    await inventory.refresh().catchError((Object _) {});
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) await _load();
  }

  Future<void> _choosePlayers(String game) async {
    final mode = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFFFFF9FA),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('¿Con quién quieres jugar?')),
            for (final option in const [
              ('partner', 'Con mi pareja', Icons.favorite_outline),
              (
                'train',
                'Entrenar con Nube · Bot de práctica',
                Icons.smart_toy_outlined,
              ),
              ('create', 'Crear sala para amigos', Icons.add_circle_outline),
              ('join', 'Entrar con código de sala', Icons.key_outlined),
              ('random', 'Buscar rival online', Icons.public),
            ])
              ListTile(
                leading: Icon(option.$3),
                title: Text(option.$2),
                onTap: () => Navigator.pop(context, option.$1),
              ),
          ],
        ),
      ),
    );
    if (mode == null || !mounted) return;
    String code = '';
    if (mode == 'join') {
      final input = TextEditingController();
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Código de sala'),
          content: TextField(
            controller: input,
            maxLength: 8,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'Código de 8 caracteres',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, input.text.trim().toUpperCase()),
              child: const Text('Entrar'),
            ),
          ],
        ),
      );
      // Dialog exit transitions finish before disposing the text controller.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      input.dispose();
      if (result == null || result.length != 8 || !mounted) return;
      code = result;
    }
    await _open(DuoGameScreen(game: game, mode: mode, roomCode: code));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFF7F5),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _featuredForest(),
          const SizedBox(height: 16),
          _guardianAdventure(),
          const SizedBox(height: 16),
          _paintingGame(),
          const SizedBox(height: 20),
          const Text(
            'Todos los juegos',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _tile('Ping pong en pareja', 1, () => _choosePlayers('pong')),
          const SizedBox(height: 16),
          _tile('¿Quién nos conoce mejor?', 2, () => _choosePlayers('quiz')),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () => _open(const ShopScreen()),
            icon: const Icon(Icons.checkroom),
            label: const Text('Personalizar · Tienda e inventario'),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const AlertDialog(
                title: Text('Recompensas'),
                content: Text(
                  'En los juegos en pareja, quien gana recibe 20 LoveCoins y su pareja 8, hasta 300 al día. En el bosque, cada 20 puntos recogidos se convierten en 1 moneda al terminar una carrera validada.',
                ),
              ),
            ),
            icon: const Icon(Icons.info_outline, size: 16),
            label: const Text('Cómo se ganan monedas'),
          ),
          const SizedBox(height: 12),
          RewardedGoldCard(previewMode: widget.previewMode),
        ],
      ),
    ),
  );
  Widget _paintingGame() =>
      _tile('Pincel en pareja', 4, () => _open(const ArtGameScreen()));
  Widget _guardianAdventure() =>
      _tile('Guardianes del Alba', 3, () => _open(const GuardianGameScreen()));
  Widget _tile(String title, int panel, VoidCallback action) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: SizedBox(
      height: 292,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedGameCover(panel: panel),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x63000000),
                  Color(0x00000000),
                  Color(0x53000000),
                ],
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: 12,
            right: 12,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                height: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: HeartButton(label: 'Jugar', onPressed: action),
          ),
        ],
      ),
    ),
  );
  Widget _featuredForest() =>
      _tile('Corre con tu mascota', 0, () => _open(const PebbleRunnerTest()));
}
