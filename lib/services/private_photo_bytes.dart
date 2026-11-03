import 'dart:typed_data';
import 'dart:ui' as ui;

/// Upload decoded pixels, never original EXIF/GPS, comments or filenames.
Future<Uint8List> privatePhotoBytes(Uint8List input) async {
  const limit = 10 * 1024 * 1024;
  if (input.isEmpty || input.length > limit) {
    throw StateError('Cada foto debe pesar menos de 10 MB');
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(input);
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  ui.Image? image;
  try {
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    if (descriptor.width * descriptor.height > 40000000) {
      throw StateError('La resolución de esta foto es demasiado grande');
    }
    final width = descriptor.width > 1280 ? 1280 : descriptor.width;
    final height = (descriptor.height * width / descriptor.width).round();
    final scale = height > 1280 ? 1280 / height : 1.0;
    codec = await descriptor.instantiateCodec(
      targetWidth: (width * scale).round().clamp(1, 1280),
      targetHeight: (height * scale).round().clamp(1, 1280),
    );
    image = (await codec.getNextFrame()).image;
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null || data.lengthInBytes > limit) {
      throw StateError('No pudimos preparar esa foto');
    }
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } finally {
    image?.dispose();
    codec?.dispose();
    descriptor?.dispose();
    buffer.dispose();
  }
}
