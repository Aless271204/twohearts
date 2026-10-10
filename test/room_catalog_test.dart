import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twohearts/core/room_catalog.dart';
import 'package:twohearts/services/inventory_service.dart';
import 'package:twohearts/widgets/room_catalog_scene.dart';

void main() {
  test('Atlas crops are isolated and stable when catalog order changes', () {
    const size=Size(1402,1122);
    final crops=[for(var i=0;i<20;i++)RoomCatalogPainter.sourceFor(i,size)];
    for(var i=0;i<crops.length;i++) {
      expect(crops[i].left>=0&&crops[i].top>=0&&crops[i].right<=size.width&&crops[i].bottom<=size.height,isTrue);
      for(var j=i+1;j<crops.length;j++) expect(crops[i].overlaps(crops[j]),isFalse);
    }
    for(final data in roomConcepts.reversed) {
      final index=InventoryItem(data).appearance['atlas_index'] as int;
      expect(RoomCatalogPainter.sourceFor(index,size),crops[index]);
    }
    final custom=InventoryItem(roomItem('custom','Custom','room_chair','Muebles','custom','#BAA2DB',null,imageAsset:'assets/images/products/custom.png'));
    expect(isRoomConcept(custom),isTrue);
    expect(custom.appearance.containsKey('atlas_index'),isFalse);
  });
  test('Approved room catalog contains five distinct items per category', () {
    expect(roomConcepts.length, 20);
    expect(roomConcepts.map((i) => i['item_key']).toSet().length, 20);
    for (final category in roomCategories)
      expect(
        roomConcepts.where((i) => i['room_category'] == category).length,
        5,
      );
    for (final data in roomConcepts) {
      final item = InventoryItem(data);
      expect(item.previewOnly, isTrue);
      expect(item.scope, 'room');
      expect(data.containsKey('price_coins'), isFalse);
      expect(InventoryItem.slots.containsKey(item.slot), isTrue);
    }
  });
  test('Furniture and ceiling anchors leave the pet body area clear', () {
    const body = Rect.fromLTWH(105, 100, 90, 176);
    for (final data in roomConcepts) {
      final item = InventoryItem(data);
      if (['room_wall', 'room_floor', 'room_rug'].contains(item.slot)) continue;
      final anchor = RoomCatalogPainter.placementFor(item);
      expect(anchor.overlaps(body), isFalse, reason: item.name);
      expect(
        (const Rect.fromLTWH(0, 0, 300, 350)).contains(anchor.topLeft),
        isTrue,
      );
      expect(anchor.bottom <= 350, isTrue);
    }
  });
  testWidgets('All twenty thumbnails load from the shared room atlas', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Wrap(
            children: [
              for (final data in roomConcepts)
                SizedBox(
                  width: 60,
                  height: 60,
                  child: RoomCatalogArt(isolated: InventoryItem(data)),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
    });
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(CustomPaint), findsAtLeastNWidgets(20));
  });
}
