import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:twohearts/core/shop_showcase.dart';
import 'package:twohearts/core/shop_economy_v2.dart';
import 'package:twohearts/services/inventory_service.dart';
import 'package:twohearts/core/store_packages.dart';

void main() {
  test('every published bundle has a complete saved WebP showroom', () {
    final sql = File(
      'supabase/migrations/20261020204524_balanced_shop_bundles.sql',
    ).readAsStringSync();
    final bundles = jsonDecode(sql.split(r'$bundles$')[1]) as List;
    expect(bundles, isNotEmpty);
    for (final bundle in bundles) {
      final file = File(
        'assets/images/products/showcases/${bundle['bundle_key']}.webp',
      );
      expect(
        file.existsSync(),
        isTrue,
        reason: '${bundle['bundle_key']} has no complete preview',
      );
      final bytes = file.readAsBytesSync();
      expect(ascii.decode(bytes.sublist(0, 4)), 'RIFF');
      expect(ascii.decode(bytes.sublist(8, 12)), 'WEBP');
    }
  });

  test(
    'whole room showroom retains every furniture item without overwriting shared slots',
    () {
      final products = roomShopV2
          .where(
            (row) =>
                row['item_key'].toString().startsWith('room_nursery_space_'),
          )
          .map(InventoryItem.new)
          .toList();
      expect(products.length, 17);
      final layout = showcaseRoomLayout(products),
          items = layout['items'] as List;
      expect(items.length, 14);
      expect(items.map((e) => e['id']).toSet().length, 14);
      for (final item in items) {
        expect(item['appearance'], isNotEmpty);
        expect(item['slot'], startsWith('room_'));
      }
    },
  );
  test(
    'proposed premium covers the current most expensive room, all three outfits and legendary crown',
    () {
      expect(storePackages.length, 3);
      expect(
        storePackages.last.gold,
        greaterThanOrEqualTo(6570 + 315 + 531 + 675 + 900),
      );
      expect(purchasesEnabled, isFalse);
      expect(
        storePackages.every(
          (p) => !p.voice && !p.customVoice && p.growthPets == 0,
        ),
        isTrue,
      );
    },
  );
}
