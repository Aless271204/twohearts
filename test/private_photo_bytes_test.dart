import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:twohearts/services/private_photo_bytes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('only decoded pixels survive; appended metadata is discarded', () async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawColor(const ui.Color(0xffcc8877), ui.BlendMode.src);
    final picture = recorder.endRecording();
    final image = await picture.toImage(2, 2);
    final encoded = await image.toByteData(format: ui.ImageByteFormat.png);
    final marker = 'GPS_PRIVATE_METADATA'.codeUnits;
    final input = Uint8List.fromList([
      ...encoded!.buffer.asUint8List(),
      ...marker,
    ]);
    final clean = await privatePhotoBytes(input);
    expect(
      String.fromCharCodes(clean),
      isNot(contains('GPS_PRIVATE_METADATA')),
    );
    final codec = await ui.instantiateImageCodec(clean);
    final result = await codec.getNextFrame();
    expect(result.image.width, 2);
    expect(result.image.height, 2);
    result.image.dispose();
    codec.dispose();
    image.dispose();
    picture.dispose();
  });
  test('rejects oversized, empty and undecodable uploads', () async {
    await expectLater(privatePhotoBytes(Uint8List(0)), throwsStateError);
    await expectLater(
      privatePhotoBytes(Uint8List(10 * 1024 * 1024 + 1)),
      throwsStateError,
    );
    await expectLater(
      privatePhotoBytes(Uint8List.fromList([1, 2, 3])),
      throwsA(anything),
    );
  });
}
