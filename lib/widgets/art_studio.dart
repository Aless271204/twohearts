import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/art_document.dart';

const artPets = ['penguin', 'bear', 'pig', 'chick'];
const artPetNames = ['Pingüino', 'Oso', 'Cerdito', 'Pollito'];
const artScenes = ['Tarde de picnic', 'Pintando sueños', 'Bajo las estrellas'];

class ArtReference extends CustomPainter {
  final ui.Image pet;
  final int scene, difficulty;
  ArtReference(this.pet, this.scene, this.difficulty);
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.clipRect(Offset.zero & size);
    c.scale(size.width / 512, size.height / 512);
    c.drawColor(const Color(0xFFFFFFFF), BlendMode.src);
    final p = Paint();
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 20, 472, 472),
        const Radius.circular(45),
      ),
      p..color = const Color(0xFFFFF0EE),
    );
    c.drawOval(
      const Rect.fromLTWH(70, 420, 372, 38),
      p..color = const Color(0xFFE7DED7),
    );
    // Preserve the actual mascot and outfit used throughout NIDO.
    final rect = Rect.fromCenter(
      center: const Offset(256, 260),
      width: 235,
      height: 382,
    );
    c.drawImageRect(
      pet,
      Rect.fromLTWH(0, 0, pet.width.toDouble(), pet.height.toDouble()),
      rect,
      Paint()..filterQuality = FilterQuality.high,
    );
    if (scene % 3 == 0) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(55, 400, 120, 55),
          const Radius.circular(12),
        ),
        p..color = const Color(0xFFEDB2A5),
      );
      c.drawOval(
        const Rect.fromLTWH(70, 390, 90, 26),
        p..color = const Color(0xFFF7D2A8),
      );
      c.drawCircle(
        const Offset(105, 409),
        12,
        p..color = const Color(0xFFDD6D7C),
      );
    } else if (scene % 3 == 1) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(355, 280, 100, 128),
          const Radius.circular(5),
        ),
        p..color = const Color(0xFFDAC2A4),
      );
      c.drawRect(
        const Rect.fromLTWH(363, 288, 84, 110),
        p..color = Colors.white,
      );
      c.drawCircle(
        const Offset(403, 337),
        24,
        p..color = const Color(0xFFF79DAF),
      );
      c.drawLine(
        const Offset(371, 408),
        const Offset(358, 462),
        p
          ..color = const Color(0xFFB59B82)
          ..strokeWidth = 7,
      );
      c.drawLine(const Offset(438, 408), const Offset(455, 462), p);
    } else {
      c.drawCircle(
        const Offset(403, 100),
        38,
        p..color = const Color(0xFFF2CC79),
      );
      c.drawCircle(
        const Offset(420, 87),
        33,
        p..color = const Color(0xFFFFF0EE),
      );
    }
    for (var i = 0; i < 3 + difficulty * 4; i++) {
      final x = 48.0 + (i * 83) % 420, y = 50.0 + (i * 47) % 150;
      if (x > 150 && x < 350 && y > 90) continue;
      c.drawCircle(
        Offset(x, y),
        difficulty == 0 ? 5 : 7,
        p
          ..color = [
            const Color(0xFFDEA5B7),
            const Color(0xFFB5CDB5),
            const Color(0xFFF0CD89),
          ][i % 3],
      );
      if (difficulty > 0) {
        c.drawLine(Offset(x - 11, y), Offset(x + 11, y), p..strokeWidth = 2);
        c.drawLine(Offset(x, y - 11), Offset(x, y + 11), p);
      }
    }
    if (difficulty == 2) {
      for (var i = 0; i < 6; i++) {
        final x = 50.0 + i * 80;
        c.drawLine(
          Offset(x, 480),
          Offset(x, 454),
          p
            ..color = const Color(0xFF8CAE8C)
            ..strokeWidth = 3,
        );
        c.drawCircle(Offset(x, 451), 9, p..color = const Color(0xFFEFAAB8));
        c.drawCircle(Offset(x, 451), 3, p..color = const Color(0xFFFFD899));
      }
    }
    c.restore();
  }

  Future<Uint8List> rgba({int size = 64}) async {
    final rec = ui.PictureRecorder();
    paint(Canvas(rec), Size.square(size.toDouble()));
    final pic = rec.endRecording(), image = await pic.toImage(size, size);
    final bytes = (await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!.buffer.asUint8List();
    image.dispose();
    pic.dispose();
    return bytes;
  }

  @override
  bool shouldRepaint(ArtReference old) =>
      old.pet != pet || old.scene != scene || old.difficulty != difficulty;
}

Future<ui.Image> loadArtPet(int scene) async {
  final bytes = await rootBundle.load(
    'assets/images/pet_portraits/${artPets[scene ~/ 3 % 4]}-feminine.png',
  );
  final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
  final image = (await codec.getNextFrame()).image;
  codec.dispose();
  return image;
}

class ArtStudio extends StatefulWidget {
  final ArtDocument document;
  final bool enabled;
  final String draftKey;
  const ArtStudio({
    super.key,
    required this.document,
    this.enabled = true,
    required this.draftKey,
  });
  @override
  State<ArtStudio> createState() => _ArtStudioState();
}

class _ArtStudioState extends State<ArtStudio> {
  ArtTool tool = ArtTool.brush;
  Color color = const Color(0xFFDD6F8E);
  double width = 8, opacity = 1;
  List<Offset> points = [];
  bool move = false, busy = false;
  final transform = TransformationController();
  static const colors = [
    0xFF292936,
    0xFF68554C,
    0xFFFFFFFF,
    0xFFF4D9BF,
    0xFFF4B7C7,
    0xFFDE6886,
    0xFFBD283D,
    0xFFF2A76A,
    0xFFF5D677,
    0xFFA5C9A5,
    0xFF549B81,
    0xFF9AC8DC,
    0xFF577FBA,
    0xFFB5A4DE,
    0xFF8B64AD,
    0xFFB6B7C5,
  ];
  static const labels = [
    'Lápiz',
    'Pincel',
    'Marcador',
    'Acuarela',
    'Goma',
    'Rellenar',
    'Cuentagotas',
    'Línea',
    'Rectángulo',
    'Elipse',
    'Texto',
  ];
  static const icons = [
    Icons.edit,
    Icons.brush,
    Icons.border_color,
    Icons.water_drop,
    Icons.auto_fix_normal,
    Icons.format_color_fill,
    Icons.colorize,
    Icons.horizontal_rule,
    Icons.crop_square,
    Icons.circle_outlined,
    Icons.text_fields,
  ];
  @override
  void initState() {
    super.initState();
    widget.document.addListener(_changed);
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(widget.draftKey);
    if (saved == null ||
        !mounted ||
        widget.document.layers.any((l) => l.marks.isNotEmpty))
      return;
    try {
      final bytes = Uint8List.fromList(saved.codeUnits);
      final codec = await ui.instantiateImageCodec(bytes);
      final image = (await codec.getNextFrame()).image;
      codec.dispose();
      if (mounted)
        widget.document.add(
          ArtMark(ArtTool.fill, Colors.white, 1, const [], image: image),
        );
      else
        image.dispose();
    } catch (_) {}
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.document.removeListener(_changed);
    transform.dispose();
    super.dispose();
  }

  ArtMark get _mark => ArtMark(
    tool,
    color.withValues(
      alpha:
          opacity *
          (tool == ArtTool.watercolor
              ? .32
              : tool == ArtTool.marker
              ? .65
              : 1),
    ),
    tool == ArtTool.pencil ? width * .45 : width,
    List.of(points),
  );
  Future<void> _start(Offset p) async {
    if (!widget.enabled || busy) return;
    if (tool == ArtTool.fill) {
      setState(() => busy = true);
      await widget.document.fill(p, color.withValues(alpha: opacity));
      if (mounted) setState(() => busy = false);
      return;
    }
    if (tool == ArtTool.dropper) {
      final image = await widget.document.render();
      final bytes = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!.buffer.asUint8List();
      image.dispose();
      final i =
          (p.dy.floor().clamp(0, 511) * 512 + p.dx.floor().clamp(0, 511)) * 4;
      if (mounted)
        setState(
          () =>
              color = Color.fromARGB(255, bytes[i], bytes[i + 1], bytes[i + 2]),
        );
      return;
    }
    if (tool == ArtTool.text) {
      final ctrl = TextEditingController();
      final text = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Escribe en tu dibujo'),
          content: TextField(controller: ctrl, maxLength: 80, autofocus: true),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Añadir'),
            ),
          ],
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      ctrl.dispose();
      if (text != null && mounted && widget.enabled)
        widget.document.add(ArtMark(tool, color, width, [p], text: text));
      return;
    }
    setState(() => points = [p]);
  }

  void _end() {
    if (points.isNotEmpty) {
      if (widget.enabled) widget.document.add(_mark);
      setState(() => points = []);
    }
  }

  Future<void> _paper() async {
    final result = await showDialog<Color>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Color del papel'),
        children: [
          Wrap(
            children: colors
                .map(
                  (v) => IconButton(
                    onPressed: () => Navigator.pop(ctx, Color(v)),
                    icon: Icon(Icons.circle, color: Color(v)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
    if (result != null) {
      widget.document.paper = result;
      widget.document.refresh();
    }
  }

  Future<void> _customColor() async {
    final ctrl = TextEditingController(
      text: color.toARGB32().toRadixString(16).substring(2).toUpperCase(),
    );
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Color personalizado'),
        content: TextField(
          controller: ctrl,
          maxLength: 6,
          decoration: const InputDecoration(
            prefixText: '#',
            hintText: 'DD6F8E',
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    ctrl.dispose();
    if (value != null && RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(value) && mounted)
      setState(() => color = Color(int.parse('FF$value', radix: 16)));
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          for (var i = 0; i < 3; i++)
            Expanded(
              child: FilterChip(
                label: Text(widget.document.layers[i].name),
                selected: widget.document.active == i,
                onSelected: widget.enabled
                    ? (_) => setState(() => widget.document.active = i)
                    : null,
              ),
            ),
          IconButton(
            tooltip: 'Ocultar o mostrar capa',
            onPressed: widget.enabled
                ? () {
                    final layer =
                        widget.document.layers[widget.document.active];
                    layer.visible = !layer.visible;
                    widget.document.refresh();
                  }
                : null,
            icon: Icon(
              widget.document.layers[widget.document.active].visible
                  ? Icons.visibility
                  : Icons.visibility_off,
            ),
          ),
        ],
      ),
      AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: LayoutBuilder(
            builder: (ctx, box) => InteractiveViewer(
              transformationController: transform,
              panEnabled: move,
              scaleEnabled: move,
              minScale: 1,
              maxScale: 4,
              child: GestureDetector(
                onPanStart: move ? null : (_) {},
                onPanUpdate: move ? null : (_) {},
                child: Listener(
                  onPointerDown: move
                      ? null
                      : (e) => _start(e.localPosition * (512 / box.maxWidth)),
                  onPointerMove: move
                      ? null
                      : (e) {
                          if (points.isNotEmpty && widget.enabled)
                            setState(
                              () => points.add(
                                Offset(
                                  (e.localPosition.dx * 512 / box.maxWidth)
                                      .clamp(0, 512),
                                  (e.localPosition.dy * 512 / box.maxWidth)
                                      .clamp(0, 512),
                                ),
                              ),
                            );
                        },
                  onPointerUp: move ? null : (_) => _end(),
                  onPointerCancel: (_) => _end(),
                  child: CustomPaint(
                    key: const Key('nido-art-canvas'),
                    size: Size.square(box.maxWidth),
                    painter: _ArtPainter(
                      widget.document,
                      points.isEmpty ? null : _mark,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final t in ArtTool.values)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: ChoiceChip(
                  avatar: Icon(icons[t.index], size: 16),
                  label: Text(labels[t.index]),
                  selected: tool == t,
                  onSelected: widget.enabled
                      ? (_) => setState(() {
                          tool = t;
                          move = false;
                        })
                      : null,
                ),
              ),
          ],
        ),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final v in colors)
              IconButton(
                tooltip: 'Color #${v.toRadixString(16).substring(2)}',
                onPressed: widget.enabled
                    ? () => setState(() => color = Color(v))
                    : null,
                icon: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: Color(v),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.toARGB32() == v
                          ? const Color(0xFFDE6886)
                          : Colors.black12,
                      width: color.toARGB32() == v ? 3 : 1,
                    ),
                  ),
                ),
              ),
            IconButton(
              tooltip: 'Color personalizado',
              onPressed: widget.enabled ? _customColor : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ),
      Row(
        children: [
          const Text('Grosor'),
          Expanded(
            child: Slider(
              value: width,
              min: 1,
              max: 44,
              onChanged: widget.enabled
                  ? (v) => setState(() => width = v)
                  : null,
            ),
          ),
          Text('${width.round()}'),
          const SizedBox(width: 8),
          const Text('Opacidad'),
          Expanded(
            child: Slider(
              value: opacity,
              min: .1,
              max: 1,
              onChanged: widget.enabled
                  ? (v) => setState(() => opacity = v)
                  : null,
            ),
          ),
        ],
      ),
      Wrap(
        alignment: WrapAlignment.center,
        children: [
          IconButton(
            tooltip: 'Deshacer en esta capa',
            onPressed: widget.enabled && widget.document.canUndo
                ? widget.document.undo
                : null,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: 'Rehacer',
            onPressed: widget.enabled && widget.document.canRedo
                ? widget.document.redo
                : null,
            icon: const Icon(Icons.redo),
          ),
          IconButton(
            tooltip: move
                ? 'Volver a dibujar'
                : 'Mover y ampliar con dos dedos',
            onPressed: () => setState(() => move = !move),
            icon: Icon(move ? Icons.brush : Icons.pan_tool_outlined),
          ),
          IconButton(
            tooltip: 'Restablecer zoom',
            onPressed: () => transform.value = Matrix4.identity(),
            icon: const Icon(Icons.fit_screen),
          ),
          IconButton(
            tooltip: 'Color del papel',
            onPressed: widget.enabled ? _paper : null,
            icon: const Icon(Icons.wallpaper),
          ),
          IconButton(
            tooltip: 'Borrar todo',
            onPressed: widget.enabled
                ? () async {
                    final yes = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('¿Empezar de nuevo?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Borrar'),
                          ),
                        ],
                      ),
                    );
                    if (yes == true) widget.document.clear();
                  }
                : null,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    ],
  );
}

class _ArtPainter extends CustomPainter {
  final ArtDocument doc;
  final ArtMark? pending;
  _ArtPainter(this.doc, this.pending);
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.clipRect(Offset.zero & s);
    c.scale(s.width / 512);
    c.drawColor(doc.paper, BlendMode.src);
    for (var i = 0; i < doc.layers.length; i++) {
      if (!doc.layers[i].visible) continue;
      c.saveLayer(const Rect.fromLTWH(0, 0, 512, 512), Paint());
      for (final m in doc.layers[i].marks) {
        ArtDocument.paintMark(c, m);
      }
      if (i == doc.active && pending != null)
        ArtDocument.paintMark(c, pending!);
      c.restore();
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_ArtPainter old) => true;
}
