import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

enum ArtTool {
  pencil,
  brush,
  marker,
  watercolor,
  eraser,
  fill,
  dropper,
  line,
  rectangle,
  ellipse,
  text,
}

class ArtMark {
  final ArtTool tool;
  final Color color;
  final double width;
  final List<Offset> points;
  final String text;
  final ui.Image? image;
  const ArtMark(
    this.tool,
    this.color,
    this.width,
    this.points, {
    this.text = '',
    this.image,
  });
}

class ArtLayer {
  String name;
  bool visible = true;
  final List<ArtMark> marks = [];
  ArtLayer(this.name);
}

/// Fixed logical coordinates keep exports and strokes independent of phone size.
class ArtDocument extends ChangeNotifier {
  final Set<ui.Image> _images = {};
  bool _disposed = false;
  static const side = 512.0;
  final List<ArtLayer> layers = [
    ArtLayer('Boceto'),
    ArtLayer('Color'),
    ArtLayer('Detalles'),
  ];
  int active = 0;
  Color paper = Colors.white;
  final List<({int layer, ArtMark mark})> _redo = [];
  bool get canUndo => layers[active].marks.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  void add(ArtMark mark) {
    if (_disposed) {
      mark.image?.dispose();
      return;
    }
    if (mark.image != null) _images.add(mark.image!);
    layers[active].marks.add(mark);
    _redo.clear();
    notifyListeners();
  }

  void undo() {
    if (canUndo) {
      _redo.add((layer: active, mark: layers[active].marks.removeLast()));
      notifyListeners();
    }
  }

  void redo() {
    if (_redo.isNotEmpty) {
      final v = _redo.removeLast();
      layers[v.layer].marks.add(v.mark);
      notifyListeners();
    }
  }

  void clear() {
    for (final image in _images) {
      image.dispose();
    }
    _images.clear();
    for (final l in layers) {
      l.marks.clear();
    }
    _redo.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final image in _images) {
      image.dispose();
    }
    _images.clear();
    super.dispose();
  }

  void refresh() => notifyListeners();
  Future<ui.Image> render({
    int size = 512,
    bool transparent = false,
    int? onlyLayer,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(size / side);
    if (!transparent) canvas.drawColor(paper, BlendMode.src);
    paintLayers(canvas, onlyLayer: onlyLayer);
    final picture = recorder.endRecording();
    final result = await picture.toImage(size, size);
    picture.dispose();
    return result;
  }

  Future<Uint8List> png({bool transparent = false}) async {
    final image = await render(transparent: transparent);
    try {
      return (await image.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  void paintLayers(Canvas canvas, {int? onlyLayer}) {
    for (var i = 0; i < layers.length; i++) {
      if (onlyLayer != null && onlyLayer != i || !layers[i].visible) continue;
      canvas.saveLayer(const Rect.fromLTWH(0, 0, side, side), Paint());
      for (final mark in layers[i].marks) {
        paintMark(canvas, mark);
      }
      canvas.restore();
    }
  }

  static void paintMark(Canvas canvas, ArtMark mark) {
    if (mark.image != null) {
      canvas.drawImageRect(
        mark.image!,
        Rect.fromLTWH(
          0,
          0,
          mark.image!.width.toDouble(),
          mark.image!.height.toDouble(),
        ),
        const Rect.fromLTWH(0, 0, side, side),
        Paint()..blendMode = BlendMode.src,
      );
      return;
    }
    if (mark.points.isEmpty) return;
    final paint = Paint()
      ..color = mark.color
      ..strokeWidth = mark.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    if (mark.tool == ArtTool.eraser) paint.blendMode = BlendMode.clear;
    if (mark.tool == ArtTool.watercolor)
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, mark.width / 7);
    final a = mark.points.first, b = mark.points.last;
    switch (mark.tool) {
      case ArtTool.rectangle:
        canvas.drawRect(Rect.fromPoints(a, b), paint);
        return;
      case ArtTool.ellipse:
        canvas.drawOval(Rect.fromPoints(a, b), paint);
        return;
      case ArtTool.line:
        canvas.drawLine(a, b, paint);
        return;
      case ArtTool.text:
        final text = TextPainter(
          text: TextSpan(
            text: mark.text,
            style: TextStyle(
              color: mark.color,
              fontSize: mark.width * 3 + 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: side - a.dx);
        text.paint(canvas, a);
        return;
      default:
        break;
    }
    if (mark.points.length == 1) {
      canvas.drawCircle(a, mark.width / 2, paint..style = PaintingStyle.fill);
      return;
    }
    final path = Path()..moveTo(a.dx, a.dy);
    for (final p in mark.points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  /// Four-neighbour tolerance fill on the active layer, undoable as one action.
  Future<void> fill(Offset point, Color color) async {
    final image = await render(transparent: true, onlyLayer: active);
    final data = (await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!.buffer.asUint8List();
    image.dispose();
    final x = point.dx.floor().clamp(0, 511),
        y = point.dy.floor().clamp(0, 511);
    final start = (y * 512 + x) * 4;
    final target = data.sublist(start, start + 4);
    final argb = color.toARGB32();
    final replacement = [
      (argb >> 16) & 255,
      (argb >> 8) & 255,
      argb & 255,
      (argb >> 24) & 255,
    ];
    final seen = Uint8List(512 * 512), stack = <int>[y * 512 + x];
    while (stack.isNotEmpty) {
      final p = stack.removeLast();
      if (seen[p] != 0) continue;
      seen[p] = 1;
      final j = p * 4;
      if (List.generate(
        4,
        (i) => (data[j + i] - target[i]).abs(),
      ).any((d) => d > 24))
        continue;
      for (var i = 0; i < 4; i++) {
        data[j + i] = replacement[i];
      }
      if (p % 512 > 0) stack.add(p - 1);
      if (p % 512 < 511) stack.add(p + 1);
      if (p >= 512) stack.add(p - 512);
      if (p < 512 * 511) stack.add(p + 512);
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(data);
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: 512,
      height: 512,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final codec = await descriptor.instantiateCodec();
    final filled = (await codec.getNextFrame()).image;
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
    add(ArtMark(ArtTool.fill, color, 1, const [], image: filled));
  }
}

/// Transparent, deterministic visual similarity; never claims to understand artistic merit.
Map<String, int> artSimilarity(Uint8List drawing, Uint8List reference) {
  if (drawing.length != reference.length || drawing.length % 4 != 0)
    throw ArgumentError('RGBA dimensions differ');
  var ink = 0, target = 0, overlap = 0;
  double difference = 0;
  for (var i = 0; i < drawing.length; i += 4) {
    final a = drawing[i] < 242 || drawing[i + 1] < 242 || drawing[i + 2] < 242;
    final b =
        reference[i] < 242 || reference[i + 1] < 242 || reference[i + 2] < 242;
    if (a) ink++;
    if (b) target++;
    if (a && b) overlap++;
    if (a || b) {
      for (var c = 0; c < 3; c++) {
        difference += (drawing[i + c] - reference[i + c]).abs() / 765;
      }
    }
  }
  if (ink == 0 || target == 0)
    return {'parecido': 0, 'avance': 0, 'composicion': 0, 'total': 0};
  final union = ink + target - overlap;
  final similarity = (100 * (1 - difference / union)).round().clamp(0, 100);
  final composition = (100 * overlap / union).round().clamp(0, 100);
  final progress = (100 * overlap / target).round().clamp(0, 100);
  return {
    'parecido': similarity,
    'avance': progress,
    'composicion': composition,
    'total': (similarity * .4 + composition * .4 + progress * .2).round(),
  };
}
