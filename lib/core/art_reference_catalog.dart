import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

enum ReferenceStyle { photo, pixel, mascot3d, sketch }

const referenceStyleLabels = [
  'Original',
  'Pixel art',
  'Foto + mascota 3D',
  'Boceto',
];
const travelReferences = [
  ('paris', 'París · Francia'),
  ('rio', 'Río de Janeiro · Brasil'),
  ('london', 'Londres · Inglaterra'),
  ('giza', 'Guiza · Egipto'),
  ('kyoto', 'Kioto · Japón'),
  ('cinque-terre', 'Cinque Terre · Italia'),
  ('santorini', 'Santorini · Grecia'),
  ('machu-picchu', 'Machu Picchu · Perú'),
];

/// Generate exactly the reference bitmap sent to both players. Local transformations
/// require no external AI upload, so private couple photos remain private.
Future<ui.Image> prepareArtReference(
  Uint8List source, {
  required ReferenceStyle style,
  required int difficulty,
  ui.Image? mascot,
}) async {
  final codec = await ui.instantiateImageCodec(source, targetWidth: 768);
  final original = (await codec.getNextFrame()).image;
  codec.dispose();
  final rec = ui.PictureRecorder(), canvas = Canvas(rec);
  canvas.drawColor(const Color(0xFFFFF7F5), BlendMode.src);
  final input = Size(original.width.toDouble(), original.height.toDouble());
  final fit = applyBoxFit(BoxFit.contain, input, const Size.square(512));
  canvas.drawImageRect(
    original,
    Offset.zero & input,
    Alignment.center.inscribe(
      fit.destination,
      const Rect.fromLTWH(0, 0, 512, 512),
    ),
    Paint()..filterQuality = FilterQuality.high,
  );
  if ((style == ReferenceStyle.mascot3d || style == ReferenceStyle.pixel) &&
      mascot != null) {
    final rgba = (await mascot.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!.buffer.asUint8List();
    final bg = rgba.sublist(0, 3),
        seen = Uint8List(mascot.width * mascot.height),
        stack = <int>[0];
    while (stack.isNotEmpty) {
      final p = stack.removeLast();
      if (seen[p] != 0) continue;
      seen[p] = 1;
      final k = p * 4;
      if ((rgba[k] - bg[0]).abs() > 12 ||
          (rgba[k + 1] - bg[1]).abs() > 12 ||
          (rgba[k + 2] - bg[2]).abs() > 12)
        continue;
      rgba[k + 3] = 0;
      if (p % mascot.width > 0) stack.add(p - 1);
      if (p % mascot.width < mascot.width - 1) stack.add(p + 1);
      if (p >= mascot.width) stack.add(p - mascot.width);
      if (p < mascot.width * (mascot.height - 1)) stack.add(p + mascot.width);
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(rgba);
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: mascot.width,
      height: mascot.height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final cutCodec = await descriptor.instantiateCodec(),
        cut = (await cutCodec.getNextFrame()).image;
    canvas.drawRect(
      const Rect.fromLTWH(0, 440, 512, 72),
      Paint()..color = const Color(0xFFF1E6D7),
    );
    canvas.drawLine(
      const Offset(0, 440),
      const Offset(512, 440),
      Paint()
        ..color = const Color(0xFFD7C8B4)
        ..strokeWidth = 3,
    );
    canvas.drawOval(
      const Rect.fromLTWH(62, 455, 210, 30),
      Paint()
        ..color = const Color(0x44000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    final fit = applyBoxFit(
      BoxFit.contain,
      Size(cut.width.toDouble(), cut.height.toDouble()),
      const Size(220, 310),
    );
    canvas.drawImageRect(
      cut,
      Rect.fromLTWH(0, 0, cut.width.toDouble(), cut.height.toDouble()),
      Alignment.bottomCenter.inscribe(
        fit.destination,
        const Rect.fromLTWH(55, 170, 220, 310),
      ),
      Paint()..filterQuality = FilterQuality.high,
    );
    // Picture retains the image until rasterization below.
    final pic = rec.endRecording(), result = await pic.toImage(512, 512);
    pic.dispose();
    cut.dispose();
    cutCodec.dispose();
    descriptor.dispose();
    buffer.dispose();
    original.dispose();
    return style == ReferenceStyle.pixel
        ? _stylize(result, style, difficulty)
        : _levelDetail(result, difficulty);
  }
  final pic = rec.endRecording(), composite = await pic.toImage(512, 512);
  pic.dispose();
  original.dispose();
  if (style == ReferenceStyle.photo) return _levelDetail(composite, difficulty);
  return _stylize(composite, style, difficulty);
}

Future<ui.Image> _stylize(
  ui.Image composite,
  ReferenceStyle style,
  int difficulty,
) async {
  final size = style == ReferenceStyle.pixel
      ? [48, 72, 96][difficulty]
      : [96, 256, 512][difficulty];
  final scaledRec = ui.PictureRecorder(), scaledCanvas = Canvas(scaledRec);
  scaledCanvas.drawImageRect(
    composite,
    const Rect.fromLTWH(0, 0, 512, 512),
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    Paint()..filterQuality = FilterQuality.medium,
  );
  final scaledPic = scaledRec.endRecording(),
      scaled = await scaledPic.toImage(size, size);
  scaledPic.dispose();
  composite.dispose();
  final raw = (await scaled.toByteData(
    format: ui.ImageByteFormat.rawRgba,
  ))!.buffer.asUint8List();
  scaled.dispose();
  if (style == ReferenceStyle.pixel) {
    for (var i = 0; i < raw.length; i += 4) {
      for (var j = 0; j < 3; j++) {
        raw[i + j] = (raw[i + j] / 32).round() * 32 > 255
            ? 255
            : (raw[i + j] / 32).round() * 32;
      }
    }
  } else {
    final before = Uint8List.fromList(raw);
    double gray(int x, int y) {
      final k = (y.clamp(0, size - 1) * size + x.clamp(0, size - 1)) * 4;
      return (before[k] + before[k + 1] + before[k + 2]) / 3;
    }

    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final gradient =
            (gray(x + 1, y) - gray(x - 1, y)).abs() +
            (gray(x, y + 1) - gray(x, y - 1)).abs();
        final value = (255 - gradient * 2).round().clamp(35, 255);
        final k = (y * size + x) * 4;
        raw[k] = value;
        raw[k + 1] = value;
        raw[k + 2] = value;
        raw[k + 3] = 255;
      }
    }
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(raw);
  final descriptor = ui.ImageDescriptor.raw(
    buffer,
    width: size,
    height: size,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final outCodec = await descriptor.instantiateCodec(),
      small = (await outCodec.getNextFrame()).image;
  final outRec = ui.PictureRecorder();
  Canvas(outRec).drawImageRect(
    small,
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    const Rect.fromLTWH(0, 0, 512, 512),
    Paint()
      ..filterQuality = (style == ReferenceStyle.pixel
          ? FilterQuality.none
          : FilterQuality.high),
  );
  final outPic = outRec.endRecording(), result = await outPic.toImage(512, 512);
  outPic.dispose();
  small.dispose();
  outCodec.dispose();
  descriptor.dispose();
  buffer.dispose();
  return result;
}

Future<ui.Image> _levelDetail(
  ui.Image source,
  int difficulty, {
  Offset focus = const Offset(.5, .5),
}) async {
  if (difficulty >= 2) return source;
  final extent = difficulty == 0 ? 352.0 : 448.0;
  final left = (focus.dx * 512 - extent / 2).clamp(0.0, 512 - extent);
  final top = (focus.dy * 512 - extent / 2).clamp(0.0, 512 - extent);
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawImageRect(
    source,
    Rect.fromLTWH(left, top, extent, extent),
    const Rect.fromLTWH(0, 0, 512, 512),
    Paint()..filterQuality = FilterQuality.high,
  );
  final picture = recorder.endRecording(),
      result = await picture.toImage(512, 512);
  picture.dispose();
  source.dispose();
  return result;
}
