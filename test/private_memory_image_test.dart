import 'package:flutter_test/flutter_test.dart';
import 'package:twohearts/widgets/private_memory_image.dart';

void main() {
  const project = 'https://example.supabase.co';
  test('legacy private photos resolve only on the configured project', () {
    expect(memoryPhotoPath('$project/storage/v1/object/public/memory-photos/albums/u/photo.jpg', project), 'albums/u/photo.jpg');
    expect(memoryPhotoPath('https://other.example/storage/v1/object/public/memory-photos/albums/u/photo.jpg', project), isNull);
    expect(memoryPhotoPath('http://example.supabase.co/storage/v1/object/public/memory-photos/albums/u/photo.jpg', project), isNull);
  });
  test('stable references cannot escape the albums folder', () {
    expect(memoryPhotoPath('memory-photo:albums/u/photo.jpg', project), 'albums/u/photo.jpg');
    expect(memoryPhotoPath('memory-photo:albums/../photo.jpg', project), isNull);
    expect(memoryPhotoPath('memory-photo:other/u/photo.jpg', project), isNull);
  });
}
