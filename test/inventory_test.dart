import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twohearts/services/inventory_service.dart';
import 'package:twohearts/core/duo_pong.dart';
import 'package:twohearts/core/room_catalog.dart';

void main() {
  test(
    'Hiding a room product preserves its ownership reference and server price',
    () {
      final local = roomConcepts.first;
      final previous = local['visible'];
      try {
        local['visible'] = false;
        final item = InventoryItem({
          'item_key': local['item_key'],
          'scope': 'room',
          'price_coins': 180,
        });
        final result = InventoryService.mergeAccessoryConcepts([
          item,
        ]).singleWhere((i) => i.key == item.key);
        expect(result.visible, isFalse);
        expect(result.price, 180);
      } finally {
        local['visible'] = previous;
      }
    },
  );
  test('Tailored catalog is purchasable and preserves published prices', () {
    final published = InventoryItem({'item_key': 'cap_pink', 'price': 75});
    final catalog = InventoryService.mergeAccessoryConcepts([published]);
    final cap = catalog.where((item) => item.key == 'cap_pink').single;
    expect(cap.data['price'], 75);
    expect(cap.previewOnly, isFalse);
    expect(cap.appearance['fitted_model_space'], isTrue);
    expect((cap.appearance['species_models'] as Map).length, 4);
    expect(
      catalog.where((item) => item.previewOnly && item.scope == 'pet').length,
      0,
    );
    expect(
      catalog.any((item) => item.key == 'wig_pastel' && item.visible),
      isFalse,
    );
    expect(catalog.any((item) => item.slot == 'pet_feet'), isTrue);
  });
  test('Inventory color parsing rejects unsafe and malformed styles', () {
    expect(InventoryItem.parseColor('#ef91b4'), const Color(0xFFEF91B4));
    for (final value in [
      'red',
      'javascript:alert(1)',
      '#123',
      ' #FFFFFF',
      null,
      {},
    ]) {
      expect(InventoryItem.parseColor(value), const Color(0xFF92BDA7));
    }
  });
  test('Opposing phones mirror input while preserving collision limits', () {
    expect(pongToServerX(.25, false), .25);
    expect(pongToServerX(.25, true), .75);
    expect(pongToServerX(-5, false), .11);
    expect(pongToServerX(3, true), .11);
    for (final x in [.11, .25, .5, .75, .89]) {
      expect(pongFromServer(pongFromServer(x, true), true), closeTo(x, .00001));
    }
  });
  test('Prediction reflects at walls and never advances more than 200ms', () {
    expect(pongBallX(.97, .5, .1), closeTo(.93, .00001));
    expect(pongBallX(.03, -.5, .1), closeTo(.07, .00001));
    expect(pongBallX(.5, .5, 100), pongBallX(.5, .5, .2));
  });
}
