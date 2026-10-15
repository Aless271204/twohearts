import '../../services/shared_pet_service.dart';
import '../../core/pet_model_catalog.dart';
import '../../core/duo_training.dart';
import '../../services/duo_audio.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../services/inventory_service.dart';
import '../../core/duo_pong.dart';
import '../../widgets/immersive_game.dart';

class DuoGameScreen extends StatefulWidget {
  final String game, mode, roomCode;
  const DuoGameScreen({
    super.key,
    required this.game,
    this.mode = 'partner',
    this.roomCode = '',
  });
  @override
  State<DuoGameScreen> createState() => _DuoGameScreenState();
}

class _DuoGameScreenState extends State<DuoGameScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final inventory = InventoryService.instance;
  final audio = DuoAudio();
  DuoTraining? practice;
  int practiceAt = 0;
  String practiceStyle = 'masculine';
  Timer? poll;
  late final AnimationController frames;
  Map<String, dynamic>? match;
  Map<String, dynamic> get state =>
      Map<String, dynamic>.from(match?['state'] as Map? ?? {});
  bool get sideB => match?['side'] == 'b';
  bool inFlight = false, active = true, answerBusy = false;
  String? failure, lobbyCode;
  bool waitingOnline = false;
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
    audio.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    active = lifecycle == AppLifecycleState.resumed;
    if (active) {
      if (match?['status'] == 'playing') audio.start();
      _tick();
    } else {
      audio.pause();
    }
  }

  void _accept(dynamic raw) {
    if (!mounted) return;
    final next = Map<String, dynamic>.from(raw as Map);
    if (next['status'] == 'playing' && match?['status'] != 'playing')
      audio.start();
    if (widget.mode != 'train' && match != null) {
      final old = Map<String, dynamic>.from(match!['state'] as Map);
      final nextState = Map<String, dynamic>.from(next['state'] as Map);
      if (nextState['score_a'] != old['score_a'] ||
          nextState['score_b'] != old['score_b']) {
        audio.effect('score');
      } else if (widget.game == 'pong' &&
          (nextState['vy'] as num? ?? 0) * (old['vy'] as num? ?? 0) < 0) {
        audio.effect('hit');
      }
    }
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
      audio.pause();
      if (widget.mode != 'train') inventory.refresh().catchError((Object _) {});
    }
  }

  Future<void> _join() async {
    if (widget.mode == 'train') {
      SupabaseService.instance
          .getMyProfile()
          .then((profile) {
            if (mounted)
              setState(
                () => practiceStyle =
                    profile?['pet_portrait_style'] as String? ?? 'masculine',
              );
          })
          .catchError((Object _) {});
      poll?.cancel();
      practice = DuoTraining(widget.game);
      practiceAt = elapsed.elapsedMilliseconds;
      _accept(practice!.snapshot(DateTime.now().millisecondsSinceEpoch / 1000));
      poll = Timer.periodic(
        const Duration(milliseconds: 33),
        (_) => _practiceTick(),
      );
      return;
    }
    try {
      inventory.refresh().catchError((Object _) {});
      final raw = await SupabaseService.instance.client.rpc(
        widget.mode == 'partner' ? 'duo_join' : 'duo_lobby',
        params: widget.mode == 'partner'
            ? {'p_game': widget.game}
            : {
                'p_action': widget.mode,
                'p_game': widget.game,
                'p_code': widget.roomCode,
              },
      );
      if (!mounted) return;
      poll?.cancel();
      if (raw['lobby'] == true) {
        setState(() {
          waitingOnline = true;
          lobbyCode = raw['code'] as String?;
          failure = null;
        });
        poll = Timer.periodic(const Duration(seconds: 1), (_) => _pollLobby());
      } else {
        waitingOnline = false;
        _accept(raw);
        _startPolling();
      }
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

  void _practiceTick() {
    if (!mounted || !active || practice == null || practice!.finished) return;
    final now = elapsed.elapsedMilliseconds;
    practice!.step((now - practiceAt) / 1000, paddle);
    practiceAt = now;
    if (practice!.event != null) audio.effect(practice!.event!);
    _accept(practice!.snapshot(DateTime.now().millisecondsSinceEpoch / 1000));
  }

  void _startPolling() {
    poll?.cancel();
    poll = Timer.periodic(
      Duration(milliseconds: widget.game == 'pong' ? 120 : 650),
      (_) => _tick(),
    );
  }

  Future<void> _pollLobby() async {
    if (!mounted || !active || inFlight) return;
    inFlight = true;
    try {
      final raw = await SupabaseService.instance.client.rpc(
        'duo_lobby',
        params: {'p_action': 'poll', 'p_game': widget.game},
      );
      if (!mounted) return;
      if (raw['lobby'] != true) {
        waitingOnline = false;
        _accept(raw);
        _startPolling();
      } else if (failure != null) {
        setState(() => failure = null);
      }
    } catch (_) {
      if (mounted)
        setState(
          () =>
              failure = 'La sala no está disponible. Reintenta para conectar.',
        );
    } finally {
      inFlight = false;
    }
  }

  Future<void> _tick({int? choice}) async {
    if (widget.mode == 'train') return;
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
    audio.effect('hit');
    if (widget.mode == 'train') {
      practice?.choose(value);
      if (practice?.event != null) audio.effect(practice!.event!);
      _accept(practice!.snapshot(DateTime.now().millisecondsSinceEpoch / 1000));
      return;
    }
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
    if (widget.mode == 'train') return true;
    if (match == null && waitingOnline) {
      poll?.cancel();
      try {
        await SupabaseService.instance.client.rpc(
          'duo_lobby',
          params: {'p_action': 'leave', 'p_game': widget.game},
        );
      } catch (_) {}
      return true;
    }
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

  Widget _mascotBadge(String side) {
    final players = List<Map<String, dynamic>>.from(
      (match?['players'] as List? ?? []).map(
        (p) => Map<String, dynamic>.from(p as Map),
      ),
    );
    final person = players.where((p) => p['side'] == side).firstOrNull;
    final own = side == (sideB ? 'b' : 'a');
    final species = PetModelCatalog.speciesFor(
      person?['species'] as String? ?? SharedPetService.instance.species,
    );
    final style =
        person?['style'] == 'feminine' ||
            (person == null && (own ? practiceStyle == 'feminine' : true))
        ? 'feminine'
        : 'masculine';
    return SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/images/pet_portraits/$species-$style.png',
              width: 58,
              height: 68,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Text(
                PetModelCatalog.emojis[species]!,
                style: const TextStyle(fontSize: 34),
              ),
            ),
          ),
          Text(
            person?['name'] as String? ??
                (own
                    ? 'Tú'
                    : widget.mode == 'train'
                    ? 'Nube · Bot'
                    : 'Rival'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = state;
    final mine = sideB ? 'b' : 'a';
    final other = sideB ? 'a' : 'b';
    final status = match?['status'];
    final dark = widget.game == 'pong';
    return ImmersiveGame(
      child: PopScope(
        canPop:
            (match == null && !waitingOnline) ||
            ['finished', 'cancelled'].contains(status),
        onPopInvokedWithResult: (popped, result) async {
          if (!popped && await _leave() && context.mounted)
            Navigator.pop(context);
        },
        child: Scaffold(
          backgroundColor: dark
              ? const Color(0xFFFFF9FA)
              : inventory.at('quiz_table')?.color.withAlpha(80) ??
                    const Color(0xFFFFF4F7),
          appBar: status == 'playing'
              ? null
              : AppBar(
                  actions: [
                    IconButton(
                      tooltip: audio.muted
                          ? 'Activar música y sonidos'
                          : 'Silenciar música y sonidos',
                      onPressed: () => setState(audio.toggle),
                      icon: Icon(
                        audio.muted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                      ),
                    ),
                  ],
                  title: Text(
                    dark
                        ? (widget.mode == 'train'
                              ? 'Ping pong · Entrenar'
                              : 'Ping pong')
                        : '¿Quién conoce mejor al otro?',
                  ),
                ),
          body: match == null
              ? Center(
                  child: failure == null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 20),
                            Text(
                              lobbyCode == null
                                  ? 'Buscando alguien para jugar…'
                                  : 'Comparte tu código de sala',
                            ),
                            if (lobbyCode != null) ...[
                              SelectableText(
                                lobbyCode!,
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => Clipboard.setData(
                                  ClipboardData(text: lobbyCode!),
                                ),
                                icon: const Icon(Icons.copy),
                                label: const Text('Copiar código'),
                              ),
                            ],
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () async {
                                if (await _leave() && mounted)
                                  Navigator.pop(context);
                              },
                              child: const Text('Cancelar'),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                failure!,
                                textAlign: TextAlign.center,
                              ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          _mascotBadge(mine),
                          Expanded(
                            child: Text(
                              'Tú ${s['score_$mine'] ?? 0}  ·  ${s['score_$other'] ?? 0} ${widget.mode == 'train' ? 'Nube' : 'Rival'}\n${widget.mode == 'train' && widget.game == 'quiz' ? 'Práctica de preguntas' : 'Rondas ${s['wins_$mine'] ?? 0} – ${s['wins_$other'] ?? 0} · Al mejor de 3'}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF292633),
                              ),
                            ),
                          ),
                          _mascotBadge(other),
                        ],
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
                                    : match!['winner'] == 'practice-draw'
                                    ? '¡Empate!'
                                    : (widget.mode == 'train' &&
                                              match!['winner'] ==
                                                  'practice-player') ||
                                          match!['winner'] ==
                                              SupabaseService
                                                  .instance
                                                  .currentUser
                                                  ?.id
                                    ? '¡Ganaste la partida!'
                                    : '¡Tu rival ganó!',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 24,
                                ),
                              ),
                              if (status == 'finished')
                                Text(
                                  widget.mode == 'train'
                                      ? 'Entrenamiento · Sin recompensas de oro'
                                      : '+${match!['reward'] ?? 0} LoveCoins',
                                  style: TextStyle(
                                    color: dark ? Colors.amber : Colors.pink,
                                  ),
                                ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Salir'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  if (![
                                    'partner',
                                    'train',
                                  ].contains(widget.mode)) {
                                    Navigator.pop(context);
                                    return;
                                  }
                                  match = null;
                                  _join();
                                  setState(() {});
                                },
                                child: const Text('Continuar'),
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
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 18,
                              ),
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
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ),
                  ],
                ),
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
      return const Center(
        child: Text('Esperando la conexión del otro jugador…'),
      );
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
                ? widget.mode == 'train'
                      ? '¿Qué crees que eligió Nube?'
                      : '¿Qué crees que eligió el otro jugador?'
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
                    'Tu rival eligió: ${label(s['answer_$other'])}',
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
                  Text('Tu rival pensó: ${label(s['guess_$other'])}'),
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
