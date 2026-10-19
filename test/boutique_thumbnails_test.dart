import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twohearts/core/boutique_thumbnails.dart';
import 'package:twohearts/theme/app_theme.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return ((x > y ? x : y) + .05) / ((x < y ? x : y) + .05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'every visible garment has its own packaged boutique illustration',
    () async {
      final catalog =
          jsonDecode(
                await rootBundle.loadString(
                  'assets/runner/accessory-catalog.json',
                ),
              )
              as List;
      final active = catalog.where((item) => item['visible'] != false).toList();
      expect(active.length, 24);
      for (final item in active) {
        final image = boutiqueThumbnails[item['item_key']];
        expect(image, isNotNull, reason: item['item_key']);
        expect(
          (await rootBundle.load(image!)).lengthInBytes,
          greaterThan(1000),
        );
      }
      expect(boutiqueThumbnails.containsKey('wig_pastel'), isFalse);
    },
  );
  test('all game interface collections have their own packaged artwork', () async {
    final paths = <String>{};
    for (final palette in ['forest', 'rose', 'night', 'honey']) {
      for (final slot in [
        'pong_paddle', 'pong_ball', 'pong_court',
        'quiz_card', 'quiz_table', 'quiz_badge',
      ]) {
        final key = '${slot}_$palette';
        final image = boutiqueThumbnails[key];
        expect(image, isNotNull, reason: key);
        paths.add(image!);
        expect((await rootBundle.load(image)).lengthInBytes, greaterThan(1000));
      }
    }
    expect(paths.length, 24);
  });
  test('selected, unselected and disabled controls remain readable', () {
    for (final bg in [
      AppTheme.roseButton,
      AppTheme.selectedSurface,
      AppTheme.surfaceVariantLight,
    ]) {
      expect(contrast(AppTheme.ink, bg), greaterThanOrEqualTo(4.5));
    }
    expect(
      contrast(AppTheme.mutedInk, const Color(0xFFF0E3E7)),
      greaterThanOrEqualTo(4.5),
    );
  });
}
