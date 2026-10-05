import 'package:flutter/material.dart';
import '../services/inventory_service.dart';

/// A stable, non-interactive layer: decorations never intercept game controls.
class InventoryScene extends StatelessWidget {
  final Map<String, InventoryItem> loadout;
  final bool accessories;
  const InventoryScene({
    super.key,
    required this.loadout,
    this.accessories = false,
  });
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      painter: _ScenePainter(loadout, accessories),
      size: Size.infinite,
    ),
  );
}

class _ScenePainter extends CustomPainter {
  final Map<String, InventoryItem> items;
  final bool accessories;
  _ScenePainter(this.items, this.accessories);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 300, size.height / 350);
    void rect(Rect r, Color c, [double radius = 8]) => canvas.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(radius)),
      Paint()..color = c,
    );
    void oval(Rect r, Color c) => canvas.drawOval(r, Paint()..color = c);
    void line(Offset a, Offset b, Color c, [double width = 2]) =>
        canvas.drawLine(
          a,
          b,
          Paint()
            ..color = c
            ..strokeWidth = width,
        );
    void emoji(String text, double x, double y, double scale) {
      final p = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(fontSize: scale),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      p.paint(canvas, Offset(x, y));
    }

    if (!accessories) {
      final wall = items['room_wall'];
      if (wall != null) {
        rect(const Rect.fromLTWH(0, 0, 300, 260), wall.color.withAlpha(100));
        for (var x = 20; x < 300; x += 45) {
          oval(Rect.fromLTWH(x.toDouble(), 45, 7, 7), Colors.white54);
        }
      }
      final floor = items['room_floor'];
      if (floor != null) {
        rect(const Rect.fromLTWH(0, 258, 300, 92), floor.color.withAlpha(180));
        for (var y = 265; y < 350; y += 20) {
          line(
            Offset(0, y.toDouble()),
            Offset(300, y.toDouble()),
            Colors.white38,
          );
        }
      }
      final bed = items['room_bed'];
      if (bed != null) {
        oval(const Rect.fromLTWH(75, 258, 150, 42), bed.color);
        oval(
          const Rect.fromLTWH(87, 264, 126, 27),
          Color.lerp(bed.color, Colors.white, .45)!,
        );
      }
      final plant = items['room_plant'];
      if (plant != null) {
        rect(const Rect.fromLTWH(23, 230, 32, 38), plant.color);
        line(
          const Offset(39, 235),
          const Offset(39, 182),
          const Color(0xFF567F65),
          4,
        );
        for (var y = 190; y < 226; y += 13) {
          oval(
            Rect.fromLTWH(18, y.toDouble(), 23, 13),
            const Color(0xFF70A889),
          );
          oval(
            Rect.fromLTWH(39, y.toDouble() - 6, 23, 13),
            const Color(0xFF57836B),
          );
        }
      }
      final lamp = items['room_lamp'];
      if (lamp != null) {
        oval(const Rect.fromLTWH(221, 100, 75, 150), const Color(0x22FFE4A2));
        line(const Offset(256, 157), const Offset(256, 271), lamp.color, 5);
        rect(const Rect.fromLTWH(229, 131, 54, 30), lamp.color);
        oval(const Rect.fromLTWH(238, 263, 37, 9), lamp.color);
      }
      final decor = items['room_decor'];
      if (decor != null) {
        rect(const Rect.fromLTWH(111, 56, 78, 62), decor.color);
        rect(const Rect.fromLTWH(117, 62, 66, 50), const Color(0xFFFFF6E6), 3);
        emoji(decor.emoji, 133, 68, 30);
      }
    } else {
      final head = items['pet_head'];
      if (head != null) {
        switch (head.style) {
          case 'bow':
            oval(const Rect.fromLTWH(120, 58, 28, 20), head.color);
            oval(const Rect.fromLTWH(148, 58, 28, 20), head.color);
            oval(const Rect.fromLTWH(144, 64, 10, 10), head.color);
            break;
          case 'crown':
            final path = Path()
              ..moveTo(119, 76)
              ..lineTo(116, 49)
              ..lineTo(134, 63)
              ..lineTo(150, 42)
              ..lineTo(166, 63)
              ..lineTo(184, 49)
              ..lineTo(181, 76)
              ..close();
            canvas.drawPath(path, Paint()..color = head.color);
            break;
          case 'cone':
          case 'santa':
            final path = Path()
              ..moveTo(120, 75)
              ..lineTo(150, 27)
              ..lineTo(180, 75)
              ..close();
            canvas.drawPath(path, Paint()..color = head.color);
            oval(const Rect.fromLTWH(144, 22, 12, 12), Colors.white);
            rect(const Rect.fromLTWH(116, 72, 68, 8), Colors.white);
            break;
          default:
            rect(const Rect.fromLTWH(124, 45, 52, 30), head.color);
            oval(const Rect.fromLTWH(110, 70, 80, 13), head.color);
            if (head.style == 'flower_hat') emoji('🌸', 153, 54, 19);
        }
      }
      final eyes = items['pet_eyes'];
      if (eyes != null) {
        rect(const Rect.fromLTWH(123, 104, 23, 14), eyes.color, 5);
        rect(const Rect.fromLTWH(154, 104, 23, 14), eyes.color, 5);
        line(const Offset(146, 109), const Offset(154, 109), eyes.color, 3);
      }
      final neck = items['pet_neck'];
      if (neck != null) {
        rect(const Rect.fromLTWH(112, 150, 76, 12), neck.color);
        rect(const Rect.fromLTWH(168, 157, 15, 42), neck.color);
        for (var y = 161; y < 194; y += 10) {
          oval(Rect.fromLTWH(173, y.toDouble(), 4, 4), Colors.white70);
        }
      }
      final body = items['pet_body'];
      if (body != null) {
        rect(const Rect.fromLTWH(118, 174, 64, 37), body.color, 12);
        emoji('🤍', 139, 176, 20);
      }
      final back = items['pet_back'];
      if (back != null) {
        rect(const Rect.fromLTWH(190, 160, 25, 50), back.color);
        line(const Offset(184, 163), const Offset(195, 205), back.color, 6);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ScenePainter old) => true;
}
