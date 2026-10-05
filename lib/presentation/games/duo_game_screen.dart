import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../services/inventory_service.dart';
import '../../core/duo_pong.dart';

class DuoGameScreen extends StatefulWidget {
  final String game;
  const DuoGameScreen({super.key, required this.game});
  @override
  State<DuoGameScreen> createState() => _DuoGameScreenState();
}

class _DuoGameScreenState extends State<DuoGameScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final inventory = InventoryService.instance;
  Timer? poll;
  late final AnimationController frames;
  Map<String, dynamic>? match;
  Map<String, dynamic> get state =>
      Map<String, dynamic>.from(match?['state'] as Map? ?? {});
  bool get sideB => match?['side'] == 'b';
  bool inFlight = false, active = true, answerBusy = false;
  String? failure;
  double paddle = .5;
  int? pendingChoice;
  DateTime received = DateTime.now();
  final Stopwatch elapsed = Stopwatch()..start();
  int receivedAt = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    frames = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    inventory.addListener(_changed);
    _join();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    inventory.removeListener(_changed);
    poll?.cancel();
    frames.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    active = lifecycle == AppLifecycleState.resumed;
    if (active) _tick();
  }

  void _accept(dynamic raw) {
    if (!mounted) return;
    final next = Map<String, dynamic>.from(raw as Map);
    if (next['state']['question_no'] != match?['state']?['question_no'] ||
        next['state']['phase'] != match?['state']?['phase']) {
      pendingChoice = null;
    }
    setState(() {
      match = next;
      received = DateTime.now();
      receivedAt = elapsed.elapsedMilliseconds;
      failure = null;
      answerBusy = false;
    });
    if (next['status'] == 'finished' || next['status'] == 'cancelled') {
      poll?.cancel();
      inventory.refresh().catchError((Object _) {});
    }
  }

  Future<void> _join() async {
    try {
      inventory.refresh().catchError((Object _) {});
      _accept(
        await SupabaseService.instance.client.rpc(
          'duo_join',
          params: {'p_game': widget.game},
        ),
      );
      poll?.cancel();
      poll = Timer.periodic(
        Duration(milliseconds: widget.game == 'pong' ? 120 : 650),
        (_) => _tick(),
      );
    } catch (e) {
      if (mounted) {
        setState(
          () => failure = e is PostgrestException
              ? e.message
              : 'No pudimos conectar. Revisa tu conexión y vuelve a intentarlo.',
        );
      }
    }
  }

  Future<void> _tick({int? choice}) async {
    if (!mounted || !active || inFlight || match == null) return;
    inFlight = true;
    try {
      _accept(
        await SupabaseService.instance.client.rpc(
          'duo_tick',
          params: {
            'p_match_id': match!['id'],
            if (widget.game == 'pong') 'p_paddle': pongToServerX(paddle, sideB),
            if (choice != null) ...{
              'p_choice': choice,
              'p_question_no': state['question_no'],
              'p_phase': state['phase'],
            },
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          failure = e is PostgrestException
              ? e.message
              : 'Se perdió la conexión. Intentando volver a conectar…';
          answerBusy = false;
          pendingChoice = null;
        });
      }
    } finally {
      inFlight = false;
    }
  }

  Future<void> _choose(int value) async {
    if (inFlight ||
        answerBusy ||
        state['my_choice'] != null ||
        pendingChoice != null) {
      return;
    }
    setState(() {
      pendingChoice = value;
      answerBusy = true;
    });
    await _tick(choice: value);
  }

  Future<bool> _leave() async {
    if (match == null || ['finished', 'cancelled'].contains(match!['status'])) {
      return true;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Salir de la partida?'),
        content: const Text('La partida de ambos terminará sin recompensa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Seguir jugando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirm != true) return false;
    try {
      await SupabaseService.instance.client.rpc(
        'duo_leave',
        params: {'p_match_id': match!['id']},
      );
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No pudimos cerrar la partida. Reintenta cuando tengas conexión.',
            ),
          ),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = state;
    final mine = sideB ? 'b' : 'a';
    final other = sideB ? 'a' : 'b';
    final status = match?['status'];
    final dark = widget.game == 'pong';
    return PopScope(
      canPop: match == null || ['finished', 'cancelled'].contains(status),
      onPopInvokedWithResult: (popped, result) async {
        if (!popped && await _leave() && context.mounted)
          Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: dark
            ? const Color(0xFF090E1A)
            : inventory.at('quiz_table')?.color.withAlpha(80) ??
                  const Color(0xFFFFF4F7),
        appBar: AppBar(
          title: Text(
            dark ? 'Ping pong en pareja' : '¿Quién conoce mejor al otro?',
          ),
        ),
        body: match == null
            ? Center(
                child: failure == null
                    ? const CircularProgressIndicator()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(failure!, textAlign: TextAlign.center),
                          ),
                          FilledButton(
                            onPressed: _join,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
              )
            : Column(
                children: [
                  if (failure != null)
                    MaterialBanner(
                      content: Text(failure!),
                      actions: [
                        TextButton(
                          onPressed: () => _tick(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      'Tú ${s['score_$mine'] ?? 0}  ·  ${s['score_$other'] ?? 0} Tu pareja\nRondas ${s['wins_$mine'] ?? 0} – ${s['wins_$other'] ?? 0} · Gana quien consiga 2',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: dark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (status == 'finished' || status == 'cancelled')
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              status == 'cancelled'
                                  ? 'Partida terminada'
                                  : match!['winner'] ==
                                        SupabaseService.instance.currentUser?.id
                                  ? '¡Ganaste la partida!'
                                  : '¡Tu pareja ganó!',
                              style: TextStyle(
                                color: dark ? Colors.white : Colors.black87,
                                fontSize: 24,
                              ),
                            ),
                            if (status == 'finished')
                              Text(
                                '+${match!['reward'] ?? 0} LoveCoins',
                                style: TextStyle(
                                  color: dark ? Colors.amber : Colors.pink,
                                ),
                              ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () {
                                match = null;
                                _join();
                                setState(() {});
                              },
                              child: const Text('Otra partida'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (status == 'waiting')
                    const Expanded(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Esperando a tu pareja…\nAbre este mismo juego desde su celular con la cuenta vinculada.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 18),
                          ),
                        ),
                      ),
                    )
                  else if (dark)
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, box) => GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanDown: (d) => setState(
                            () => paddle = (d.localPosition.dx / box.maxWidth)
                                .clamp(.11, .89)
                                .toDouble(),
                          ),
                          onPanUpdate: (d) => setState(
                            () => paddle = (d.localPosition.dx / box.maxWidth)
                                .clamp(.11, .89)
                                .toDouble(),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: AnimatedBuilder(
                                  animation: frames,
                                  builder: (context, _) => CustomPaint(
                                    painter: _PongPainter(
                                      s,
                                      sideB,
                                      paddle,
                                      (elapsed.elapsedMilliseconds -
                                              receivedAt) /
                                          1000,
                                      inventory.loadout,
                                    ),
                                  ),
                                ),
                              ),
                              if (s['paused'] == true ||
                                  s['phase'] == 'countdown')
                                Center(
                                  child: Text(
                                    s['paused'] == true
                                        ? 'Esperando la conexión\nde tu pareja…'
                                        : '¡Prepárate!',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(child: _quiz(s, mine, other)),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      dark
                          ? 'Desliza tu paleta · 7 puntos por ronda'
                          : 'Responde sobre ti en secreto, luego adivina la respuesta de tu pareja.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: dark ? Colors.white60 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _quiz(Map<String, dynamic> s, String mine, String other) {
    final q = Map<String, dynamic>.from(s['question'] as Map? ?? {});
    final options = List<String>.from(q['options'] as List? ?? []);
    final phase = s['phase'];
    String label(dynamic i) =>
        i is int && i >= 0 && i < options.length ? options[i] : 'Sin respuesta';
    final border = inventory.at('quiz_card')?.color ?? const Color(0xFFE69FBB);
    if (s['paused'] == true) {
      return const Center(child: Text('Esperando la conexión de tu pareja…'));
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AnimatedBuilder(
          animation: frames,
          builder: (_, __) {
            final secs =
                ((s['deadline'] as num? ?? 0) -
                        (match!['server_time'] as num) -
                        (DateTime.now().difference(received).inMilliseconds /
                            1000))
                    .ceil()
                    .clamp(0, 15);
            return Text(
              'Ronda ${s['round']} · ${q['category'] ?? ''} · ${secs}s',
              textAlign: TextAlign.center,
            );
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: inventory.at('quiz_badge')?.color.withAlpha(80),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            '${inventory.at('quiz_badge')?.emoji ?? '💌'} ${phase == 'self'
                ? 'Elige tu respuesta secreta'
                : phase == 'guess'
                ? '¿Qué crees que eligió tu pareja?'
                : phase == 'reveal'
                ? '¡Así nos conocemos!'
                : '¡Prepárense!'}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
        ),
        if ((s['round_questions'] as int? ?? 0) >= 5)
          const Text(
            'Desempate: seguimos hasta que alguien tome la ventaja.',
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 20),
        Text(
          q['prompt'] as String? ?? '',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < options.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(18),
                backgroundColor: (s['my_choice'] ?? pendingChoice) == i
                    ? border.withAlpha(65)
                    : Colors.white,
                side: BorderSide(color: border, width: 2),
              ),
              onPressed:
                  ['self', 'guess'].contains(phase) &&
                      s['my_choice'] == null &&
                      pendingChoice == null &&
                      !answerBusy &&
                      !inFlight
                  ? () => _choose(i)
                  : null,
              child: Text(
                options[i],
                style: const TextStyle(fontSize: 17, color: Colors.black87),
              ),
            ),
          ),
        if (s['my_choice'] != null || pendingChoice != null)
          const Text(
            'Respuesta guardada. Esperando a tu pareja…',
            textAlign: TextAlign.center,
          ),
        if (phase == 'reveal')
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Text(
                    'Tu pareja eligió: ${label(s['answer_$other'])}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Tú pensaste: ${label(s['guess_$mine'])}'),
                  Text(
                    s['guess_$mine'] != null &&
                            s['guess_$mine'] == s['answer_$other']
                        ? '¡Me conoces! +1 acierto'
                        : '¡Ahora ya lo sabes para la próxima!',
                  ),
                  const Divider(),
                  Text('Tú elegiste: ${label(s['answer_$mine'])}'),
                  Text('Tu pareja pensó: ${label(s['guess_$other'])}'),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PongPainter extends CustomPainter {
  final Map<String, dynamic> s;
  final bool sideB;
  final double mine, dt;
  final Map<String, InventoryItem> cosmetics;
  _PongPainter(this.s, this.sideB, this.mine, this.dt, this.cosmetics);
  @override
  void paint(Canvas canvas, Size size) {
    final color = cosmetics['pong_court']?.color ?? const Color(0xFFE6A4D0);
    final court = Rect.fromLTWH(10, 4, size.width - 20, size.height - 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(court, const Radius.circular(16)),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawLine(
      Offset(14, size.height / 2),
      Offset(size.width - 14, size.height / 2),
      Paint()..color = color.withAlpha(70),
    );
    final opponent = (s['paddle_${sideB ? 'a' : 'b'}'] as num? ?? .5)
        .toDouble();
    void paddle(double x, double y, Color c) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x * size.width, y * size.height),
            width: size.width * .22,
            height: 12,
          ),
          const Radius.circular(6),
        ),
        Paint()..color = c,
      );
    }

    paddle(
      mine,
      .9,
      cosmetics['pong_paddle']?.color ?? const Color(0xFF6393E7),
    );
    paddle(
      pongFromServer(opponent, sideB),
      .1,
      s['opponent_paddle_color'] == null
          ? const Color(0xFFF39D75)
          : InventoryItem.parseColor(s['opponent_paddle_color']),
    );
    final play = s['phase'] == 'play' && s['paused'] != true;
    final elapsed = play ? dt : 0.0;
    final x = pongBallX(
      (s['x'] as num).toDouble(),
      (s['vx'] as num).toDouble(),
      elapsed,
    );
    final y =
        ((s['y'] as num).toDouble() +
                (s['vy'] as num).toDouble() * elapsed.clamp(0, .2))
            .clamp(0.02, .98)
            .toDouble();
    final pos = Offset(
      pongFromServer(x, sideB) * size.width,
      pongFromServer(y, sideB) * size.height,
    );
    canvas.drawCircle(
      pos,
      14,
      Paint()
        ..color = (cosmetics['pong_ball']?.color ?? Colors.pink).withAlpha(40),
    );
    canvas.drawCircle(
      pos,
      7,
      Paint()..color = cosmetics['pong_ball']?.color ?? Colors.pink,
    );
  }

  @override
  bool shouldRepaint(covariant _PongPainter old) => true;
}
