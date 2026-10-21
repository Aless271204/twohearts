import '../services/inventory_service.dart';

/// Read-only showroom; never changes the couple's saved room or equipment.
Map<String, dynamic> showcaseRoomLayout(List<InventoryItem> products) {
  const anchors = <String, List<double>>{
    'bed': [-.98, 0, -.78],
    'chair': [.98, 0, -1.05],
    'desk': [1.23, 0, .25],
    'dresser': [.88, 0, -2.06],
    'plant': [-1.35, 0, -1.75],
    'lamp': [1.58, 0, -1.5],
    'frame': [.9, 1.63, -2.33],
    'shelf': [.9, 1.17, -2.23],
    'rug': [0, 0, .05],
    'curtain': [-.92, 1.83, -2.30],
    'chest': [-1.6, 0, .65],
    'toy': [1.65, 0, .85],
    'special_one': [-1.65, 0, -.65],
    'special_two': [1.65, 0, -.65],
  };
  return {
    'items': [
      for (final item in products)
        if (!['room_wall', 'room_floor', 'room_ceiling'].contains(item.slot))
          (() {
            final part = anchors.keys.firstWhere(
              (p) => item.key.endsWith('_$p'),
              orElse: () => 'toy',
            );
            final p = anchors[part]!;
            return {
              'id': 'showcase-${item.key}',
              'item_key': item.key,
              'slot': item.slot,
              'appearance': item.appearance,
              'x': p[0],
              'y': p[1],
              'z': p[2],
              'rotation': 0,
            };
          })(),
    ],
  };
}
