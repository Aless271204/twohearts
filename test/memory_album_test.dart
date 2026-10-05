import 'package:flutter_test/flutter_test.dart';
import 'package:twohearts/services/memory_album_service.dart';

void main() {
  test('old albums remain readable without category', () {
    final album = MemoryAlbum.fromJson({
      'id': 'a',
      'user_id': 'u',
      'couple_id': 'c',
      'album_name': 'Viaje',
      'photo_urls': ['one', 'two', 'three', 'four', 'five'],
    });
    expect(album.photoUrls.length, 5);
    expect(album.category, 'general');
  });
  test(
    'empty and oversized albums rejected before accessing backend',
    () async {
      final service = MemoryAlbumService.instance;
      expect(
        await service.createAlbum(
          albumName: '',
          description: '',
          photoUrls: ['one'],
        ),
        isNotNull,
      );
      expect(
        await service.createAlbum(
          albumName: 'Trip',
          description: '',
          photoUrls: [],
        ),
        'Agrega al menos una foto',
      );
      expect(
        await service.createAlbum(
          albumName: 'Trip',
          description: '',
          photoUrls: List.filled(6, 'photo'),
        ),
        'Máximo 5 fotos por álbum',
      );
    },
  );
}
