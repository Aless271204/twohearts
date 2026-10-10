import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/inventory_service.dart';

Future<ui.Image>? _atlas;
Future<ui.Image> _loadAtlas() => _atlas ??= () async {
  final bytes = await rootBundle.load(
    'assets/images/ui/room-catalog-atlas.png',
  );
  final codec = await ui.instantiateImageCodec(
    bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
  );
  final frame = await codec.getNextFrame();
  codec.dispose();
  return frame.image;
}();

bool _usesAtlas(InventoryItem item) {
  final index=item.appearance['atlas_index'];
  return index is int && index>=0 && index<20;
}
bool isRoomConcept(InventoryItem item) =>
    _usesAtlas(item) || item.appearance['image_asset'] is String;

/// One shared atlas and renderer for the store and placed room objects.
class RoomCatalogArt extends StatelessWidget {
  final Map<String, InventoryItem> items;
  final InventoryItem? isolated;
  const RoomCatalogArt({super.key, this.items = const {}, this.isolated});
  @override
  Widget build(BuildContext context) {
    final custom = isolated?.appearance['image_asset'];
    if (custom is String) return Image.asset(custom, fit: BoxFit.contain);
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<ui.Image>(
            future: _loadAtlas(),
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return const Center(
                  child: Icon(Icons.image_not_supported_outlined),
                );
              if (!snapshot.hasData) return const SizedBox.expand();
              return CustomPaint(
                painter: RoomCatalogPainter(snapshot.data!, items, isolated),
                size: Size.infinite,
              );
            },
          ),
          for (final item in items.values.where(
            (i) => i.appearance['image_asset'] is String,
          ))
            Positioned.fromRect(
              rect: _scaledPlacement(item, constraints),
              child: Image.asset(
                item.appearance['image_asset'] as String,
                fit: BoxFit.contain,
              ),
            ),
        ],
      ),
    );
  }

  Rect _scaledPlacement(InventoryItem item, BoxConstraints c) {
    final rect = RoomCatalogPainter.placementFor(item);
    return Rect.fromLTWH(
      rect.left * c.maxWidth / 300,
      rect.top * c.maxHeight / 350,
      rect.width * c.maxWidth / 300,
      rect.height * c.maxHeight / 350,
    );
  }
}

class RoomCatalogPainter extends CustomPainter {
  final ui.Image atlas;
  final Map<String, InventoryItem> items;
  final InventoryItem? isolated;
  RoomCatalogPainter(this.atlas, this.items, this.isolated);
  static Rect sourceFor(int index, Size image) {
    // Explicit bounds exclude glows or hanging cords from neighboring pieces.
    const bounds = [
      Rect.fromLTRB(0,45,281,311), Rect.fromLTRB(289,45,564,312),
      Rect.fromLTRB(586,46,821,312), Rect.fromLTRB(831,90,1113,312),
      Rect.fromLTRB(1115,74,1402,312),
      Rect.fromLTRB(12,329,280,568), Rect.fromLTRB(304,329,560,568),
      Rect.fromLTRB(590,328,824,568), Rect.fromLTRB(858,326,1108,568),
      Rect.fromLTRB(1117,337,1402,568),
      Rect.fromLTRB(9,584,281,822), Rect.fromLTRB(301,584,563,822),
      Rect.fromLTRB(580,584,824,822), Rect.fromLTRB(827,596,1113,822),
      Rect.fromLTRB(1115,597,1402,822),
      Rect.fromLTRB(0,833,281,1122), Rect.fromLTRB(286,833,564,1122),
      Rect.fromLTRB(573,833,824,1122), Rect.fromLTRB(831,833,1112,1122),
      Rect.fromLTRB(1115,833,1402,1122),
    ];
    final r=bounds[index];
    return Rect.fromLTRB(r.left*image.width/1402,r.top*image.height/1122,r.right*image.width/1402,r.bottom*image.height/1122);
  }

  static Rect placementFor(InventoryItem item) => switch (item.slot) {
    'room_ceiling' =>
      item.style == 'lights' || item.style == 'beams'
          ? const Rect.fromLTWH(5, 0, 290, 70)
          : const Rect.fromLTWH(220, 0, 72, 100),
    'room_decor' => const Rect.fromLTWH(225, 102, 55, 66),
    'room_mirror' => const Rect.fromLTWH(240, 169, 49, 66),
    'room_shelf' => const Rect.fromLTWH(200, 188, 95, 50),
    'room_rug' => const Rect.fromLTWH(74, 276, 152, 58),
    'room_bed' => const Rect.fromLTWH(3, 272, 88, 73),
    'room_chair' => const Rect.fromLTWH(3, 222, 73, 70),
    'room_table' => const Rect.fromLTWH(232, 277, 66, 56),
    'room_dresser' => const Rect.fromLTWH(221, 232, 74, 66),
    'room_plant' => const Rect.fromLTWH(2, 192, 65, 88),
    'room_floor' => const Rect.fromLTWH(0, 260, 300, 90),
    _ => const Rect.fromLTWH(0, 0, 300, 350),
  };
  void drawPiece(Canvas canvas, InventoryItem item, Rect target, {double xScale=1,double yScale=1}) {
    final index = item.appearance['atlas_index'] as int;
    final source = sourceFor(
      index,
      Size(atlas.width.toDouble(), atlas.height.toDouble()),
    );
    final fitted = applyBoxFit(BoxFit.contain, source.size, Size(target.width*xScale,target.height*yScale));
    canvas.drawImageRect(
      atlas,
      source,
      Alignment.center.inscribe(Size(fitted.destination.width/xScale,fitted.destination.height/yScale), target),
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  void tileSurface(Canvas canvas, InventoryItem item, Rect area, Size tile) {
    final cell = sourceFor(
      item.appearance['atlas_index'] as int,
      Size(atlas.width.toDouble(), atlas.height.toDouble()),
    );
    final source = Rect.fromCenter(
      center: cell.center,
      width: cell.width * .55,
      height: cell.height * .55,
    );
    canvas.save();
    canvas.clipRect(area);
    for (double y = area.top; y < area.bottom; y += tile.height) {
      for (double x = area.left; x < area.right; x += tile.width) {
        canvas.drawImageRect(
          atlas,
          source,
          Rect.fromLTWH(x, y, tile.width, tile.height),
          Paint()..filterQuality = FilterQuality.medium,
        );
      }
    }
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (isolated != null) {
      drawPiece(canvas, isolated!, Offset.zero & size);
      return;
    }
    canvas.save();
    canvas.scale(size.width / 300, size.height / 350);
    final wall = items['room_wall'];
    if (wall != null && _usesAtlas(wall)) {
      final path = Path()..addRect(const Rect.fromLTWH(0, 0, 300, 260));
      final window = Path()..addRect(const Rect.fromLTWH(0, 0, 102, 210));
      canvas.save();
      canvas.clipPath(Path.combine(PathOperation.difference, path, window));
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 300, 260),
        Paint()
          ..shader = LinearGradient(
            colors: [const Color(0xFFFFF5E9), wall.color],
          ).createShader(const Rect.fromLTWH(0, 0, 300, 260)),
      );
      if (wall.style == 'sage_panel') {
        canvas.drawRect(
          const Rect.fromLTWH(0, 154, 300, 106),
          Paint()..color = wall.color,
        );
        for (double x = 0; x < 300; x += 13)
          canvas.drawLine(
            Offset(x, 154),
            Offset(x, 260),
            Paint()
              ..color = const Color(0x50739380)
              ..strokeWidth = 1,
          );
        canvas.drawRect(
          const Rect.fromLTWH(0, 151, 300, 4),
          Paint()..color = const Color(0xFFDFE8D6),
        );
      } else {
        tileSurface(
          canvas,
          wall,
          const Rect.fromLTWH(0, 0, 300, 260),
          const Size(90, 90),
        );
      }
      canvas.restore();
    }
    final floor = items['room_floor'];
    if (floor != null && _usesAtlas(floor)) {
      const area = Rect.fromLTWH(0, 260, 300, 90);
      canvas.save();
      canvas.clipRect(area);
      canvas.drawRect(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(floor.color, Colors.black, .10)!,
              Color.lerp(floor.color, Colors.white, .15)!,
            ],
          ).createShader(area),
      );
      tileSurface(canvas, floor, area, const Size(74, 34));
      final grout = Paint()
        ..color = Color.lerp(floor.color, Colors.white, .45)!
        ..strokeWidth = 1;
      if (floor.style == 'honey') {
        for (double y = 250; y < 370; y += 13)
          for (double x = -20; x < 320; x += 36) {
            final p = Path()
              ..moveTo(x, y)
              ..lineTo(x + 18, y + 8)
              ..lineTo(x + 36, y)
              ..moveTo(x + 18, y + 8)
              ..lineTo(x + 18, y + 20);
            canvas.drawPath(p, grout..style = PaintingStyle.stroke);
          }
      } else {
        for (double y = 260; y < 351; y += floor.style == 'rose_tile' ? 22 : 14)
          canvas.drawLine(Offset(0, y), Offset(300, y), grout);
        for (double x = 0; x < 300; x += floor.style == 'rose_tile' ? 45 : 80)
          canvas.drawLine(Offset(x, 260), Offset(x, 350), grout);
      }
      canvas.drawLine(
        const Offset(0, 260),
        const Offset(300, 260),
        Paint()
          ..color = const Color(0xFFEBDBCB)
          ..strokeWidth = 5,
      );
      canvas.restore();
    }
    final objects =
        items.values
            .where(
              (i) =>
                  _usesAtlas(i) &&
                  !['room_wall', 'room_floor'].contains(i.slot),
            )
            .toList()
          ..sort(
            (a, b) => (a.slot == 'room_rug' ? -1 : placementFor(a).bottom)
                .compareTo(b.slot == 'room_rug' ? -1 : placementFor(b).bottom),
          );
    for (final item in objects) drawPiece(canvas, item, placementFor(item),xScale:size.width/300,yScale:size.height/350);
    canvas.restore();
  }

  @override
  bool shouldRepaint(RoomCatalogPainter old) =>
      old.items != items || old.isolated != isolated || old.atlas != atlas;
}
