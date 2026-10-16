import 'guardian_game_screen.dart';
import '../../widgets/twohearts_ui.dart';
import '../../widgets/rewarded_gold_card.dart';
import 'package:flutter/material.dart';
import '../../widgets/rose_ui.dart';
import '../../theme/app_theme.dart';
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
    backgroundColor: Colors.transparent,
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _featuredForest(),
          const SizedBox(height: 16),
          _guardianAdventure(),
          const SizedBox(height: 20),
          const Text(
            'Todos los juegos',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _tile(
                  'Ping pong\nen pareja',
                  1,
                  () => _choosePlayers('pong'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _tile(
                  '¿Quién nos\nconoce mejor?',
                  2,
                  () => _choosePlayers('quiz'),
                ),
              ),
            ],
          ),
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
  Widget _guardianAdventure() => Semantics(
    label:
        'Guardianes del Alba. Aventura pixel art. Solitario o pareja online. Jugar.',
    button: true,
    child: InkWell(
      onTap: () => _open(const GuardianGameScreen()),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: ColoredBox(
          color: const Color(0xFFFFF9FA),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/images/ui/guardian-coming-soon.png',
                height: 145,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Guardianes del Alba',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF292633),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Aventura pixel art · Solo o en pareja',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF716B78),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3ED),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Jugar',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3D7259),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget _tile(String title, int panel, VoidCallback action) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: SizedBox(
      height: 224,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GameArt(panel: panel),
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
                fontSize: 15,
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
  Widget _featuredForest() => SizedBox(
    height: 326,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const GameArt(panel: 0),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x08000000), Color(0xB5223B2E)],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Corre con tu mascota',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Un bosque lleno de vida. Salta, recoge corazones y supera tu récord.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                HeartButton(
                  label: 'Jugar',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => _open(const PebbleRunnerTest()),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
