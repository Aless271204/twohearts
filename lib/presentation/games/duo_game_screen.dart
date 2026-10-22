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
import '../../widgets/quiz_answer_art.dart';
import '../../widgets/quiz_reaction_card.dart';
import '../../core/quiz_reactions.dart';

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
  int? pendingChoice, draftChoice;
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
      draftChoice = null;
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
            if (widget.game == 'pong') 'p_phase': 'powerups-v2',
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
      width: 78,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/images/pet_portraits/$species-$style.png',
              width: 74,
              height: 78,
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
              ? const Color(0xFFFFF5E8)
              : inventory.at('quiz_table')?.color.withAlpha(80) ??
                    const Color(0xFFFFF4E9),
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
                        : '¿Cuánto nos conocemos?',
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                      child: Text(
                        dark ? 'Ping pong' : '¿Cuánto nos conocemos?',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'NidoSerif',
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF523D35),
                        ),
                      ),
                    ),
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
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Tú ${s['score_$mine'] ?? 0}  ·  ${s['score_$other'] ?? 0} ${widget.mode == 'train' ? 'Nube' : 'Rival'}\n${widget.mode == 'train' && widget.game == 'quiz' ? 'Práctica de preguntas' : 'Rondas ${s['wins_$mine'] ?? 0} – ${s['wins_$other'] ?? 0} · Al mejor de 3'}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF292633),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      tooltip: audio.muted
                                          ? 'Activar música y sonidos'
                                          : 'Silenciar música y sonidos',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => setState(audio.toggle),
                                      icon: Icon(
                                        audio.muted
                                            ? Icons.volume_off_rounded
                                            : Icons.volume_up_rounded,
                                        size: 20,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Salir de la partida',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () async {
                                        if (await _leave() && context.mounted)
                                          Navigator.pop(context);
                                      },
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
                      Expanded(child: _pongStage(s))
                    else
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 260),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween(
                                    begin: const Offset(0, .035),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                          child: KeyedSubtree(
                            key: ValueKey('${s['question_no']}-${s['phase']}'),
                            child: _quiz(s, mine, other),
                          ),
                        ),
                      ),
                    if (dark && status == 'playing') _powerLegend(s, mine),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        dark
                            ? 'Desliza tu paleta · Atrapa los regalos con la pelota'
                            : widget.mode == 'train'
                            ? 'Responde sobre ti y trata de conocer a Nube.'
                            : 'Responde sobre ti y adivina la respuesta del otro jugador.',
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

  Widget _pongStage(Map<String, dynamic> s) => LayoutBuilder(
    builder: (context, scene) => Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/ui/pong-room-v5.webp',
            fit: BoxFit.fill,
          ),
        ),
        Positioned(
          left: scene.maxWidth * .115,
          right: scene.maxWidth * .115,
          top: scene.maxHeight * .17,
          bottom: scene.maxHeight * .17,
          child: LayoutBuilder(
            builder: (context, box) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (d) => paddle = (d.localPosition.dx / box.maxWidth)
                  .clamp(.11, .89)
                  .toDouble(),
              onPanUpdate: (d) => paddle = (d.localPosition.dx / box.maxWidth)
                  .clamp(.11, .89)
                  .toDouble(),
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _PongPainter(
                    s,
                    sideB,
                    () => paddle,
                    () => (elapsed.elapsedMilliseconds - receivedAt) / 1000,
                    inventory.loadout,
                    frames,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (s['paused'] == true || s['phase'] == 'countdown')
          Center(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFAF0),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                s['paused'] == true ? 'Esperando conexión…' : '¡Prepárate!',
                style: const TextStyle(
                  color: Color(0xFF65434D),
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _powerLegend(Map<String, dynamic> s, String mine) {
    final extended = widget.mode == 'train' || s['powerups_v2'] == true;
    final active = (s['tempo_remaining'] as num? ?? 0) > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 5,
            alignment: WrapAlignment.center,
            children: [
              for (final item in [
                ('Paleta XL', 'wide'),
                ('Escudo', 'shield'),
                if (extended) ('Chispa', 'spark'),
                if (extended) ('Calma', 'calm'),
              ])
                Semantics(
                  label: item.$1,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/ui/pong-power-${item.$2}-v5.webp',
                        width: 54,
                        height: 49,
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                      Text(
                        item.$1,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF493744),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (active)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${s['tempo_kind'] == 3 ? '✨ Chispa' : '☁ Calma'} · ${(s['tempo_remaining'] as num).ceil()} s',
                style: const TextStyle(
                  color: Color(0xFF765481),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _canConfirm(Map<String, dynamic> s) =>
      draftChoice != null &&
      !answerBusy &&
      !inFlight &&
      (s['deadline'] as num? ?? 0) -
              (match!['server_time'] as num) -
              (elapsed.elapsedMilliseconds - receivedAt) / 1000 >
          0;

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
    if (['reveal', 'question_intro', 'countdown'].contains(phase)) {
      return _quizIntermission(s, mine, other, label);
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
                        ((elapsed.elapsedMilliseconds - receivedAt) / 1000))
                    .ceil()
                    .clamp(0, 20);
            final answering = ['self', 'guess'].contains(phase);
            final accent = secs <= 5 && answering
                ? const Color(0xFFB93659)
                : const Color(0xFFCB557B);
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFAF5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF0DDE0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ronda ${s['round']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF493744),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          q['category'] as String? ?? 'Nuestros detalles',
                          style: const TextStyle(color: Color(0xFF755A69)),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: answering ? secs / 20 : 1,
                            minHeight: 5,
                            color: accent,
                            backgroundColor: const Color(0xFFF2E4E8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 62,
                    height: 62,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE9E5),
                      shape: BoxShape.circle,
                      border: Border.all(color: accent, width: 2),
                    ),
                    child: Text(
                      '${secs}s',
                      style: TextStyle(
                        color: accent,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
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
            '${phase == 'self'
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
          style: const TextStyle(
            fontFamily: 'NidoSerif',
            fontSize: 27,
            fontWeight: FontWeight.w600,
            color: Color(0xFF47352D),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < options.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12795C3F),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: OutlinedButton(
                key: ValueKey('quiz-option-$i'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  backgroundColor:
                      (s['my_choice'] ?? pendingChoice ?? draftChoice) == i
                      ? const Color(0xFFFFDFD2)
                      : const Color(0xFFFFFAEF),
                  foregroundColor: const Color(0xFF47352D),
                  disabledForegroundColor: const Color(0xFF47352D),
                  side: BorderSide(
                    color: (s['my_choice'] ?? pendingChoice ?? draftChoice) == i
                        ? border
                        : const Color(0xFFEAD9C5),
                    width: 1.6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed:
                    ['self', 'guess'].contains(phase) &&
                        s['my_choice'] == null &&
                        pendingChoice == null &&
                        !answerBusy
                    ? () => setState(() => draftChoice = i)
                    : null,
                child: Row(
                  children: [
                    QuizAnswerArt(
                      answer: options[i],
                      category: q['category']?.toString() ?? '',
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        options[i],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF47352D),
                        ),
                      ),
                    ),
                    if ((s['my_choice'] ?? pendingChoice ?? draftChoice) == i)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFFD45262),
                        size: 27,
                      ),
                  ],
                ),
              ),
            ),
          ),
        if (['self', 'guess'].contains(phase) &&
            s['my_choice'] == null &&
            pendingChoice == null)
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 10),
            child: AnimatedBuilder(
              animation: frames,
              builder: (context, _) => FilledButton.icon(
                key: const ValueKey('quiz-confirm'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD34B63),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE9DDD2),
                  disabledForegroundColor: const Color(0xFF756356),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: _canConfirm(s) ? () => _choose(draftChoice!) : null,
                icon: Icon(
                  Icons.favorite_rounded,
                  size: 20,
                  color: _canConfirm(s)
                      ? Colors.white
                      : const Color(0xFF756356),
                ),
                label: Text(
                  'Confirmar',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: _canConfirm(s)
                        ? Colors.white
                        : const Color(0xFF756356),
                  ),
                ),
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

  Widget _quizIntermission(
    Map<String, dynamic> s,
    String mine,
    String other,
    String Function(dynamic) label,
  ) {
    final reveal = s['phase'] == 'reveal',
        question = (s['question_no'] as num? ?? 0).toInt();
    final players = List<Map<String, dynamic>>.from(
      (match?['players'] as List? ?? []).map(
        (p) => Map<String, dynamic>.from(p as Map),
      ),
    );
    Widget reactionCard(String side) {
      final person = players.where((p) => p['side'] == side).firstOrNull;
      final correct =
          s['guess_$side'] != null &&
          s['guess_$side'] == s['answer_${side == 'a' ? 'b' : 'a'}'];
      final streak = (s['streak_$side'] as num?)?.toInt() ?? (correct ? 1 : -1);
      return QuizReactionCard(
        key: ValueKey('quiz-reaction-$side'),
        species: PetModelCatalog.speciesFor(
          person?['species'] as String? ?? SharedPetService.instance.species,
        ),
        name:
            person?['name'] as String? ??
            (side == mine
                ? 'Tú'
                : widget.mode == 'train'
                ? 'Nube · Bot'
                : 'Tu pareja'),
        correct: correct,
        reaction: QuizReaction.forStreak(streak, question, side),
        animation: frames,
        answer: label(s['guess_$side']),
        expected: label(s['answer_${side == 'a' ? 'b' : 'a'}']),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
      children: [
        Text(
          reveal ? '¡Así nos conocemos!' : 'Pregunta ${question + 1}',
          key: const ValueKey('quiz-intermission-title'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'NidoSerif',
            fontSize: 29,
            fontWeight: FontWeight.w600,
            color: Color(0xFF493744),
          ),
        ),
        const SizedBox(height: 18),
        if (reveal)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: reactionCard(mine)),
              const SizedBox(width: 10),
              Expanded(child: reactionCard(other)),
            ],
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _mascotBadge(mine),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 22),
                      child: Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFE46A8B),
                        size: 34,
                      ),
                    ),
                    _mascotBadge(other),
                  ],
                ),
                const SizedBox(height: 26),
                const Text(
                  'Un nuevo detalle por descubrir',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF735B68), fontSize: 17),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        AnimatedBuilder(
          animation: frames,
          builder: (_, __) {
            final total = reveal
                ? 5
                : s['phase'] == 'countdown'
                ? 3
                : 2;
            final seconds =
                ((s['deadline'] as num? ?? 0) -
                        (match!['server_time'] as num) -
                        ((elapsed.elapsedMilliseconds - receivedAt) / 1000))
                    .ceil()
                    .clamp(0, total);
            return Column(
              children: [
                Text(
                  reveal
                      ? 'Siguiente pregunta en $seconds…'
                      : '¡Empezamos en $seconds!',
                  key: const ValueKey('quiz-intermission-clock'),
                  style: const TextStyle(
                    color: Color(0xFF8F3E62),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: seconds / total,
                    minHeight: 7,
                    color: const Color(0xFFE77998),
                    backgroundColor: const Color(0xFFF1DEE6),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PongPainter extends CustomPainter {
  final Map<String, dynamic> s;
  final bool sideB;
  final double Function() positionNow, elapsedNow;
  double get mine => positionNow();
  double get dt => elapsedNow();
  final Map<String, InventoryItem> cosmetics;
  _PongPainter(
    this.s,
    this.sideB,
    this.positionNow,
    this.elapsedNow,
    this.cosmetics,
    Listenable frames,
  ) : super(repaint: frames);
  @override
  void paint(Canvas canvas, Size size) {
    if (cosmetics['pong_court'] != null)
      canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)),
        Paint()..color = cosmetics['pong_court']!.color.withAlpha(85),
      );
    for (double x = 24; x < size.width - 24; x += 15)
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(x + 7, size.height / 2),
        Paint()
          ..color = Colors.white.withAlpha(195)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    final opponent = (s['paddle_${sideB ? 'a' : 'b'}'] as num? ?? .5)
        .toDouble();
    void paddle(double x, double y, Color c, bool wide) {
      final rect = Rect.fromCenter(
        center: Offset(x * size.width, y * size.height),
        width: size.width * (wide ? .34 : .22),
        height: 16,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.shift(const Offset(0, 4)),
          const Radius.circular(9),
        ),
        Paint()..color = const Color(0x23564958),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(9)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(c, Colors.white, .35)!, c],
          ).createShader(rect),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(7)),
        Paint()
          ..color = Colors.white.withAlpha(140)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    paddle(
      mine,
      .9,
      cosmetics['pong_paddle']?.color ?? const Color(0xFFF28D83),
      (s['wide_${sideB ? 'b' : 'a'}'] as num? ?? 0) > 0,
    );
    paddle(
      pongFromServer(opponent, sideB),
      .1,
      s['opponent_paddle_color'] == null
          ? const Color(0xFFB0A0E3)
          : InventoryItem.parseColor(s['opponent_paddle_color']),
      (s['wide_${sideB ? 'a' : 'b'}'] as num? ?? 0) > 0,
    );
    for (final side in ['a', 'b']) {
      if (s['shield_$side'] != true) continue;
      final bottom = (side == 'b') == sideB;
      canvas.drawLine(
        Offset(18, size.height * (bottom ? .97 : .03)),
        Offset(size.width - 18, size.height * (bottom ? .97 : .03)),
        Paint()
          ..color = const Color(0xFF55AF9C)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }
    if ((s['power_kind'] as num? ?? 0) > 0) {
      final point = Offset(
        pongFromServer((s['power_x'] as num).toDouble(), sideB) * size.width,
        size.height * .5,
      );
      canvas.drawCircle(point, 18, Paint()..color = const Color(0xFFFFE7A5));
      final text = TextPainter(
        text: TextSpan(
          text: switch (s['power_kind']) {
            1 => '↔',
            2 => '♡',
            3 => '✦',
            _ => '☁',
          },
          style: const TextStyle(
            color: Color(0xFF594526),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, point - Offset(text.width / 2, text.height / 2));
    }
    final play = s['phase'] == 'play' && s['paused'] != true;
    final elapsed = play
        ? dt * ((s['tempo_rate'] as num? ?? 1).clamp(.65, 1.4))
        : 0.0;
    final x = pongBallX(
      (s['x'] as num).toDouble(),
      (s['vx'] as num).toDouble(),
      elapsed,
    );
    final y =
        ((s['y'] as num).toDouble() +
                (s['vy'] as num).toDouble() * elapsed.clamp(0, .35))
            .clamp(0.02, .98)
            .toDouble();
    final pos = Offset(
      pongFromServer(x, sideB) * size.width,
      pongFromServer(y, sideB) * size.height,
    );
    final direction =
        Offset((s['vx'] as num).toDouble(), (s['vy'] as num).toDouble()) *
        (sideB ? -1 : 1);
    if (play && direction.distance > .001)
      for (var i = 4; i > 0; i--)
        canvas.drawCircle(
          pos - direction / direction.distance * (i * 8.0),
          6 - i * .7,
          Paint()
            ..color =
                (s['tempo_kind'] == 3
                        ? const Color(0xFFFFC667)
                        : const Color(0xFFEFAAC4))
                    .withAlpha(65 - i * 10),
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
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.4, -.5),
          colors: [
            Colors.white,
            cosmetics['pong_ball']?.color ?? const Color(0xFFEE7FA8),
          ],
        ).createShader(Rect.fromCircle(center: pos, radius: 7)),
    );
  }

  @override
  bool shouldRepaint(covariant _PongPainter old) => true;
}
