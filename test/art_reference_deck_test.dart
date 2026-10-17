import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twohearts/core/art_reference_deck.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'packaged catalog has 20 active drawings and five mascot images per level',
    () async {
      final list =
          (jsonDecode(
                    await rootBundle.loadString(
                      'assets/images/art_references/mobile/catalog.json',
                    ),
                  )
                  as List)
              .cast<Map<String, dynamic>>();
      final active = list.where((entry) => entry['enabled'] == true).toList();
      expect(active.length, 60);
      for (final level in ['easy', 'medium', 'hard']) {
        final group = active.where((entry) => entry['level'] == level).toList();
        expect(group.length, 20);
        expect(
          group.where((entry) => entry['category'] == 'mascots').length,
          5,
        );
        for (final item in group) {
          expect(
            (await rootBundle.load(item['asset'] as String)).lengthInBytes,
            greaterThan(500),
          );
        }
      }
    },
  );
  test(
    'all references appear once per cycle and cycle boundary never repeats',
    () async {
      final entries = List.generate(
        20,
        (i) => CatalogDrawing('e$i', 'easy', 'Dibujo $i', 'asset$i'),
      );
      final first = <String>[];
      for (var i = 0; i < 20; i++) {
        first.add(
          (await ArtReferenceDeck.drawFrom(
            entries,
            'easy',
            random: Random(i),
          )).id,
        );
      }
      expect(first.toSet().length, 20);
      final next = await ArtReferenceDeck.drawFrom(
        entries,
        'easy',
        random: Random(3),
      );
      expect(next.id, isNot(first.last));
    },
  );
  test('disabled removed items cannot be drawn from a stored bag', () async {
    SharedPreferences.setMockInitialValues({
      'art-reference-bag-v1-medium': ['removed', 'valid'],
    });
    final chosen = await ArtReferenceDeck.drawFrom([
      const CatalogDrawing('valid', 'medium', 'Disponible', 'image'),
    ], 'medium');
    expect(chosen.id, 'valid');
  });
  test('empty level fails instead of silently mixing difficulties', () async {
    expect(ArtReferenceDeck.drawFrom([], 'hard'), throwsStateError);
  });
}
