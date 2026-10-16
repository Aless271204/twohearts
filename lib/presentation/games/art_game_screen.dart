import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/art_document.dart';
import '../../services/supabase_service.dart';
import '../../services/duo_audio.dart';
import '../../widgets/art_studio.dart';
import '../../widgets/art_reference_picker.dart';
import '../../core/art_reference_catalog.dart';

class ArtGameScreen extends StatefulWidget {
  final bool freeDraw;
  const ArtGameScreen({super.key, this.freeDraw = false});
  @override
  State<ArtGameScreen> createState() => _ArtGameScreenState();
}

class _ArtGameScreenState extends State<ArtGameScreen>
    with WidgetsBindingObserver {
  final document = ArtDocument();
  final audio = DuoAudio();
  bool active = true;
  Map<String, dynamic>? room;
  Map<String, int>? score, otherScore;
  Timer? ticker;
  ui.Image? pet;
  ui.Image? customReference;
  Uint8List? sourceReference, referencePng;
  String referenceTitle = 'Picnic en París · Mascotas 3D';
  ReferenceStyle referenceStyle = ReferenceStyle.photo;
  bool preparingReference = false;
  int referenceGeneration = 0;
  int difficulty = 0, scene = 0, seconds = 300;
  DateTime? deadline;
  Duration clockOffset = Duration.zero;
  bool solo = false,
      started = false,
      busy = false,
      sending = false,
      submitted = false,
      finished = false,
      polling = false;
  String? error;
  Uint8List? frozen;
  String get uid => SupabaseService.instance.currentUser?.id ?? 'preview';
  String get draftKey =>
      'art-draft-$uid-${room?['id'] ?? (widget.freeDraw ? 'free' : 'solo')}';
  ArtReference? get reference => pet == null
      ? null
      : ArtReference(pet!, scene, difficulty, custom: customReference);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPet();
    if (!widget.freeDraw) _defaultReference();
    ticker = Timer.periodic(const Duration(seconds: 1), _tick);
    if (widget.freeDraw) {
      solo = true;
      started = true;
    }
  }

  Future<void> _loadPet() async {
    final requestedScene = scene;
    final image = await loadArtPet(requestedScene);
    if (!mounted || requestedScene != scene) {
      image.dispose();
      return;
    }
    final old = pet;
    setState(() => pet = image);
    old?.dispose();
    if (finished) _scoreBoth();
  }

  Future<void> _defaultReference() async {
    final bytes = (await rootBundle.load(
      'assets/images/art_references/paris-mascots.webp',
    )).buffer.asUint8List();
    if (!mounted || sourceReference != null || room != null) return;
    sourceReference = bytes;
    await _prepareReference();
  }

  Future<void> _pickReference() async {
    final choice = await showArtReferencePicker(context);
    if (choice == null || !mounted) return;
    setState(() {
      sourceReference = choice.bytes;
      referenceTitle = choice.title;
      referenceStyle = ReferenceStyle.photo;
    });
    await _prepareReference();
  }

  Future<void> _prepareReference() async {
    final source = sourceReference;
    if (source == null || room != null) return;
    final generation = ++referenceGeneration;
    setState(() => preparingReference = true);
    try {
      final image = await prepareArtReference(
        source,
        style: referenceStyle,
        difficulty: difficulty,
        mascot: pet,
      );
      if (!mounted || generation != referenceGeneration) {
        image.dispose();
        return;
      }
      final png = (await image.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List();
      if (!mounted || generation != referenceGeneration) {
        image.dispose();
        return;
      }
      final old = customReference;
      setState(() {
        customReference = image;
        referencePng = png;
      });
      old?.dispose();
    } catch (_) {
      if (mounted)
        setState(
          () =>
              error = 'No pudimos preparar esa referencia. Elige otra imagen.',
        );
    } finally {
      if (mounted && generation == referenceGeneration)
        setState(() => preparingReference = false);
    }
  }

  Future<void> _loadRemoteReference(Map<String, dynamic> value) async {
    final generation = ++referenceGeneration;
    try {
      final bytes = base64Decode(value['reference_image'] as String);
      if (bytes.length < 24 || bytes.length > 1050000)
        throw const FormatException();
      final header = ByteData.sublistView(bytes);
      if (header.getUint32(16) > 1024 || header.getUint32(20) > 1024)
        throw const FormatException();
      final codec = await ui.instantiateImageCodec(bytes),
          image = (await codec.getNextFrame()).image;
      codec.dispose();
      if (!mounted || generation != referenceGeneration) {
        image.dispose();
        return;
      }
      final old = customReference;
      setState(() {
        customReference = image;
        referencePng = bytes;
        referenceTitle =
            value['reference_title'] as String? ?? 'Nuestro recuerdo';
      });
      old?.dispose();
      if (finished) _scoreBoth();
    } catch (_) {
      if (mounted)
        setState(
          () => error =
              'La referencia no se pudo cargar. Reabre la partida antes de dibujar.',
        );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ticker?.cancel();
    pet?.dispose();
    customReference?.dispose();
    document.dispose();
    audio.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    active = state == AppLifecycleState.resumed;
    if (active && started && !finished) audio.start();
    if (!active) audio.pause();
    if (state == AppLifecycleState.resumed) {
      _tick(null);
      _poll();
    } else if (state == AppLifecycleState.paused) {
      _saveDraft();
    }
  }

  Future<Map<String, dynamic>> _rpc(
    String action, [
    Map<String, dynamic> data = const {},
  ]) async => Map<String, dynamic>.from(
    await SupabaseService.instance.client.rpc(
          'art_action',
          params: {
            'p_action': action,
            'p_data': {'compact': true, ...data},
          },
        )
        as Map,
  );
  Future<void> _act(
    String action, [
    Map<String, dynamic> data = const {},
  ]) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      _accept(
        await _rpc(action, {if (room != null) 'id': room!['id'], ...data}),
      );
    } catch (e) {
      if (mounted)
        setState(
          () => error = e.toString().contains('PostgrestException')
              ? (e as dynamic).message.toString()
              : 'No pudimos conectar. Conservamos tu dibujo; vuelve a intentar.',
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _accept(Map<String, dynamic> value) {
    if (!mounted) return;
    final newScene = value['scene'] as int?;
    final changedScene = newScene != null && (newScene != scene || pet == null);
    final wasStarted = started;
    final changedReference =
        value['reference_image'] != null &&
        value['reference_image'] != base64Encode(referencePng ?? Uint8List(0));
    setState(() {
      room = {...?room, ...value};
      difficulty = value['difficulty'] as int? ?? difficulty;
      if (newScene != null) scene = newScene;
      if (value['server_now'] != null)
        clockOffset = DateTime.parse(
          value['server_now'] as String,
        ).difference(DateTime.now().toUtc());
      if (value['deadline'] != null) {
        deadline = DateTime.parse(value['deadline'] as String);
        started = true;
      }
      final ownKey = value['host'] == uid ? 'host_art' : 'guest_art';
      if (value[ownKey] != null) {
        submitted = true;
        frozen = base64Decode(value[ownKey] as String);
      }
      finished = room!['host_art'] != null && room!['guest_art'] != null;
    });
    if (changedScene) _loadPet();
    if (!wasStarted && started) audio.start();
    if (finished && !changedScene && !changedReference) _scoreBoth();
    if (value['reference_image'] != null &&
        value['reference_image'] != base64Encode(referencePng ?? Uint8List(0)))
      _loadRemoteReference(value);
  }

  void _tick(Timer? t) {
    if (!mounted) return;
    if (deadline != null) {
      final left = deadline!
          .difference(DateTime.now().toUtc().add(clockOffset))
          .inSeconds
          .clamp(0, 300);
      if (left != seconds) setState(() => seconds = left);
      if (left == 0 && !submitted && !sending) _submit();
    }
    if (t != null && t.tick % 3 == 0) _poll();
    if (t != null && t.tick % 12 == 0 && started && !finished) _saveDraft();
  }

  Future<void> _poll() async {
    if (room == null || polling || finished || !mounted || !active) return;
    polling = true;
    try {
      var v = await _rpc('status', {'id': room!['id']});
      if (v['host_submitted'] == true &&
          v['guest_submitted'] == true &&
          !finished)
        v = await _rpc('status', {'id': room!['id'], 'download': true});
      if (mounted) {
        _accept(v);
        if (error != null) setState(() => error = null);
      }
    } catch (_) {
      if (mounted)
        setState(
          () => error =
              'Conexión interrumpida. El tiempo continúa y tu dibujo sigue en este teléfono.',
        );
    } finally {
      polling = false;
    }
  }

  Future<void> _saveDraft() async {
    if (!started || !mounted) return;
    try {
      final png = frozen ?? await document.png();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(draftKey, String.fromCharCodes(png));
      if (room != null)
        await prefs.setString(
          'art-active-$uid',
          jsonEncode({'id': room!['id']}),
        );
    } catch (_) {}
  }

  Future<void> _resume() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('art-active-$uid');
    if (saved == null) {
      setState(() => error = 'No hay una partida guardada');
      return;
    }
    try {
      final v = jsonDecode(saved) as Map;
      await _act('status', {'id': v['id'], 'download': true});
    } catch (_) {
      setState(() => error = 'No pudimos recuperar esa partida');
    }
  }

  Future<void> _submit() async {
    if (sending || submitted) return;
    setState(() => sending = true);
    try {
      frozen ??= await document.png();
      if (solo) {
        final image = await document.render(size: 64);
        final raw = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        image.dispose();
        final ref = await reference!.rgba();
        if (mounted)
          setState(() {
            score = artSimilarity(raw, ref);
            submitted = true;
            finished = true;
          });
      } else {
        final result = await _rpc('submit', {
          'id': room!['id'],
          'content': base64Encode(frozen!),
        });
        _accept(result);
      }
      await _saveDraft();
    } catch (_) {
      if (mounted)
        setState(
          () => error =
              'No pudimos enviar el dibujo. Está guardado; toca «Reintentar envío».',
        );
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<Map<String, int>> _scoreImage(String data) async {
    final codec = await ui.instantiateImageCodec(
      base64Decode(data),
      targetWidth: 64,
      targetHeight: 64,
    );
    final image = (await codec.getNextFrame()).image;
    codec.dispose();
    final bytes = (await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!.buffer.asUint8List();
    image.dispose();
    return artSimilarity(bytes, await reference!.rgba());
  }

  Future<void> _scoreBoth() async {
    if (score != null || pet == null || room == null) return;
    final a = await _scoreImage(
          room![room!['host'] == uid ? 'host_art' : 'guest_art'] as String,
        ),
        b = await _scoreImage(
          room![room!['host'] == uid ? 'guest_art' : 'host_art'] as String,
        );
    if (mounted)
      setState(() {
        score = a;
        otherScore = b;
      });
  }

  Future<void> _export({Uint8List? bytes, bool transparent = false}) async {
    final png =
        bytes ??
        (transparent
            ? await document.png(transparent: true)
            : frozen ?? await document.png());
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(png, mimeType: 'image/png', name: 'nido-dibujo.png'),
        ],
        fileNameOverrides: ['nido-dibujo.png'],
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Future<void> _download() async {
    final png = frozen ?? await document.png();
    if (!mounted) return;
    try {
      await const MethodChannel('nido/art').invokeMethod('savePng', {
        'bytes': png,
        'name': 'NIDO-${DateTime.now().millisecondsSinceEpoch}.png',
      });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dibujo guardado en Imágenes / NIDO')),
        );
    } on MissingPluginException {
      await _export(bytes: png);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar. Usa «Compartir PNG».'),
          ),
        );
    }
  }

  Future<bool> _leave() async {
    if (!started || finished || widget.freeDraw) {
      await _saveDraft();
      return true;
    }
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Salir de la partida?'),
        content: const Text(
          'Guardaremos tu dibujo. En pareja el reloj sigue corriendo; puedes regresar desde «Continuar partida».',
        ),
        actions: [
          IconButton(
            tooltip: 'Música y sonidos',
            onPressed: () => setState(audio.toggle),
            icon: Icon(audio.muted ? Icons.volume_off : Icons.volume_up),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Seguir dibujando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar y salir'),
          ),
        ],
      ),
    );
    if (yes == true) await _saveDraft();
    return yes == true;
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !started || finished,
    onPopInvokedWithResult: (didPop, result) async {
      if (!didPop && await _leave() && mounted) {
        setState(() => started = false);
        if (context.mounted) Navigator.pop(context);
      }
    },
    child: Scaffold(
      backgroundColor: const Color(0xFFFFF7F5),
      appBar: AppBar(
        title: Text(
          widget.freeDraw ? 'Dibuja para tu pareja' : 'Pincel en pareja',
        ),
        backgroundColor: const Color(0xFFFFF7F5),
        actions: [
          IconButton(
            tooltip: 'Música y sonidos',
            onPressed: () => setState(audio.toggle),
            icon: Icon(audio.muted ? Icons.volume_off : Icons.volume_up),
          ),
          if (started && !widget.freeDraw)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            if (error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(error!),
                ),
              ),
            if (!started) ...[
              const Text(
                'Cinco minutos, dos miradas, una misma inspiración.',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Dibuja a nuestras mascotas en escenas acogedoras. Empiezan cuando los dos estén listos; los dibujos se revelan al terminar y enviarlos ambos.',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (var i = 0; i < 3; i++)
                    ChoiceChip(
                      label: Text(['Fácil', 'Medio', 'Difícil'][i]),
                      selected: difficulty == i,
                      onSelected: room == null
                          ? (_) {
                              setState(() => difficulty = i);
                              _prepareReference();
                            }
                          : null,
                    ),
                ],
              ),
              if (pet != null)
                Center(
                  child: SizedBox(
                    width: 230,
                    height: 230,
                    child: CustomPaint(painter: reference),
                  ),
                ),
              if (room == null) ...[
                Text(
                  [
                    'Fácil · formas grandes y colores simplificados',
                    'Medio · más detalles y sombras',
                    'Difícil · referencia completa y texturas',
                  ][difficulty],
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                FilledButton.tonalIcon(
                  onPressed: preparingReference ? null : _pickReference,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Sus fotos, viajes y destinos'),
                ),
                if (sourceReference != null)
                  Wrap(
                    spacing: 5,
                    children: [
                      for (final style in ReferenceStyle.values)
                        ChoiceChip(
                          label: Text(referenceStyleLabels[style.index]),
                          selected: referenceStyle == style,
                          onSelected: preparingReference
                              ? null
                              : (_) {
                                  setState(() => referenceStyle = style);
                                  _prepareReference();
                                },
                        ),
                    ],
                  ),
                if (preparingReference) const LinearProgressIndicator(),
                if (sourceReference != null &&
                    (referenceStyle == ReferenceStyle.mascot3d ||
                        referenceStyle == ReferenceStyle.pixel))
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: scene ~/ 3,
                    decoration: const InputDecoration(
                      labelText: 'Mascota que viaja con ustedes',
                    ),
                    items: [
                      for (var i = 0; i < 4; i++)
                        DropdownMenuItem(value: i, child: Text(artPetNames[i])),
                    ],
                    onChanged: preparingReference
                        ? null
                        : (value) async {
                            if (value == null) return;
                            setState(() => scene = value * 3);
                            await _loadPet();
                            if (mounted) _prepareReference();
                          },
                  ),
                Text(
                  referenceTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                FilledButton.icon(
                  onPressed: busy || preparingReference
                      ? null
                      : () => _act('create', {
                          'difficulty': difficulty,
                          'scene': scene,
                          if (referencePng != null)
                            'reference_image': base64Encode(referencePng!),
                          'reference_title': referenceTitle,
                          'reference_style': referenceStyle.name,
                        }),
                  icon: const Icon(Icons.favorite),
                  label: const Text('Crear partida con mi pareja'),
                ),
                OutlinedButton(
                  onPressed: busy ? null : () => _act('join'),
                  child: const Text('Unirme a la partida de mi pareja'),
                ),
                TextButton(
                  onPressed: busy ? null : _resume,
                  child: const Text('Continuar partida guardada'),
                ),
                TextButton(
                  onPressed: preparingReference
                      ? null
                      : () {
                          setState(() {
                            solo = true;
                            started = true;
                            deadline = DateTime.now().toUtc().add(
                              const Duration(minutes: 5),
                            );
                          });
                          audio.start();
                        },
                  child: const Text('Practicar a solas · 5 minutos'),
                ),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: scene,
                  decoration: const InputDecoration(
                    labelText: 'Escenas básicas de las mascotas',
                  ),
                  items: [
                    for (var i = 0; i < 12; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text(
                          '${artPetNames[i ~/ 3]} · ${artScenes[i % 3]}',
                        ),
                      ),
                  ],
                  onChanged: preparingReference
                      ? null
                      : (v) {
                          if (v != null) {
                            setState(() {
                              scene = v;
                              sourceReference = null;
                              referenceGeneration++;
                              referencePng = null;
                              customReference?.dispose();
                              customReference = null;
                              referenceTitle =
                                  '${artPetNames[v ~/ 3]} · ${artScenes[v % 3]}';
                            });
                            _loadPet();
                          }
                        },
                ),
              ] else ...[
                Text(
                  'Sala ${room!['code']} · tu pareja puede unirse desde este mismo juego',
                ),
                Text(
                  'Tú: ${(room![room!['host'] == uid ? 'host_ready' : 'guest_ready'] == true) ? 'listo' : 'preparándote'} · Pareja: ${(room![room!['host'] == uid ? 'guest_ready' : 'host_ready'] == true) ? 'lista' : 'esperando'}',
                ),
                FilledButton(
                  onPressed: busy ? null : () => _act('ready'),
                  child: const Text('Estoy listo · empezar juntos'),
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Mismas herramientas y tiempo en las tres dificultades. La escena incorpora más detalles en medio y difícil. La valoración automática mide parecido visual, composición y avance; la estética la deciden ustedes. No entrega oro ni cobra por jugar.',
                style: TextStyle(fontSize: 12, height: 1.5),
              ),
            ] else if (!finished) ...[
              if (!widget.freeDraw && reference != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CustomPaint(painter: reference),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customReference != null
                                    ? referenceTitle
                                    : '${artPetNames[scene ~/ 3]} · ${artScenes[scene % 3]}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                [
                                  'Fácil · formas y colores simplificados',
                                  'Medio · más detalles y sombras',
                                  'Difícil · escena completa y texturas',
                                ][difficulty],
                              ),
                              TextButton(
                                onPressed: () => showDialog<void>(
                                  context: context,
                                  builder: (ctx) => Dialog(
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: CustomPaint(painter: reference),
                                    ),
                                  ),
                                ),
                                child: const Text('Ampliar referencia'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (submitted)
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'Dibujo enviado. Esperando a tu pareja… Puedes guardarlo mientras tanto.',
                  ),
                ),
              if (!submitted)
                ArtStudio(
                  key: ValueKey(draftKey),
                  document: document,
                  enabled:
                      !sending &&
                      (widget.freeDraw ||
                          seconds > 0 &&
                              (room == null ||
                                  deadline == null ||
                                  !DateTime.now()
                                      .toUtc()
                                      .add(clockOffset)
                                      .isBefore(
                                        deadline!.subtract(
                                          const Duration(minutes: 5),
                                        ),
                                      ))),
                  draftKey: draftKey,
                ),
              if (frozen != null && submitted)
                Image.memory(frozen!, height: 260),
              if (seconds == 0 && !submitted && !widget.freeDraw)
                FilledButton(
                  onPressed: sending ? null : _submit,
                  child: Text(sending ? 'Enviando…' : 'Reintentar envío'),
                ),
              if (widget.freeDraw)
                FilledButton.icon(
                  onPressed: busy
                      ? null
                      : () async {
                          setState(() => busy = true);
                          try {
                            final png = await document.png();
                            await _rpc('note', {
                              'kind': 'image',
                              'content': base64Encode(png),
                            });
                            if (mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Dibujo enviado a tu pareja'),
                                ),
                              );
                          } catch (_) {
                            if (mounted)
                              setState(
                                () => error =
                                    'No se pudo enviar. Comprueba la conexión y el vínculo de pareja.',
                              );
                          } finally {
                            if (mounted) setState(() => busy = false);
                          }
                        },
                  icon: const Icon(Icons.favorite),
                  label: const Text('Enviar a mi pareja'),
                ),
            ] else ...[
              const Text(
                '¡Sus pequeñas obras de arte!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              if (frozen != null)
                Card(
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Tu dibujo'),
                      ),
                      Image.memory(frozen!, height: 250),
                    ],
                  ),
                ),
              if (!solo && room != null)
                Card(
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Dibujo de tu pareja'),
                      ),
                      Image.memory(
                        base64Decode(
                          room![room!['host'] == uid ? 'guest_art' : 'host_art']
                              as String,
                        ),
                        height: 250,
                      ),
                      TextButton(
                        onPressed: () => _export(
                          bytes: base64Decode(
                            room![room!['host'] == uid
                                    ? 'guest_art'
                                    : 'host_art']
                                as String,
                          ),
                        ),
                        child: const Text(
                          'Compartir o guardar dibujo de mi pareja',
                        ),
                      ),
                    ],
                  ),
                ),
              if (score != null) ...[
                Text(
                  'Valoración visual: ${score!['total']}/100${otherScore == null ? '' : ' · Pareja: ${otherScore!['total']}/100'}',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Parecido ${score!['parecido']} · Avance ${score!['avance']} · Composición ${score!['composicion']}',
                ),
                if (otherScore != null)
                  Text(
                    score!['total'] == otherScore!['total']
                        ? 'Empate en la valoración automática'
                        : score!['total']! > otherScore!['total']!
                        ? 'Tu dibujo tiene mayor parecido visual'
                        : 'El dibujo de tu pareja tiene mayor parecido visual',
                  ),
                const Text(
                  'Es una comparación de formas y colores, no un juicio sobre tu talento. Voten para decidir cuál les gusta más.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
              if (!solo) ...[
                FilledButton.tonal(
                  onPressed: busy ? null : () => _act('vote', {'winner': uid}),
                  child: const Text('Votar por mi dibujo'),
                ),
                FilledButton.tonal(
                  onPressed: busy
                      ? null
                      : () => _act('vote', {
                          'winner': room!['host'] == uid
                              ? room!['guest']
                              : room!['host'],
                        }),
                  child: const Text('Votar por el de mi pareja'),
                ),
                TextButton(
                  onPressed: () => _act('status'),
                  child: const Text('Actualizar votos'),
                ),
                if (room!['host_vote'] != null && room!['guest_vote'] != null)
                  Text(
                    room!['host_vote'] == room!['guest_vote']
                        ? (room!['host_vote'] == uid
                              ? '¡Ganaste la votación!'
                              : '¡Tu pareja ganó la votación!')
                        : '¡Empate! Cada uno tiene una mirada especial.',
                  ),
              ],
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove(draftKey);
                  if (!mounted) return;
                  document.clear();
                  setState(() {
                    room = null;
                    deadline = null;
                    started = false;
                    submitted = false;
                    finished = false;
                    score = null;
                    otherScore = null;
                    frozen = null;
                    seconds = 300;
                  });
                },
                child: const Text('Otra ronda'),
              ),
            ],
            if (started)
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _download,
                    icon: const Icon(Icons.download),
                    label: const Text('Descargar PNG'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _export(),
                    icon: const Icon(Icons.share),
                    label: const Text('Compartir PNG'),
                  ),
                  if (!submitted)
                    TextButton(
                      onPressed: () => _export(transparent: true),
                      child: const Text('PNG transparente'),
                    ),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}
