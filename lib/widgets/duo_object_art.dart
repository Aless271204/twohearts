import 'package:flutter/material.dart';

/// Transparent illustrations, shared as one small atlas rather than 12 images.
class DuoObjectArt extends StatelessWidget {
  final int index;
  final double size;
  const DuoObjectArt({super.key, required this.index, this.size = 72});

  static int? forAnswer(String answer) {
    final text = answer.toLowerCase();
    for (final entry in <(String, int)>[
      ('pícnic', 0),
      ('picnic', 0),
      ('película', 1),
      ('cine', 1),
      ('viaj', 2),
      ('paseo', 2),
      ('escapada', 2),
      ('montaña', 2),
      ('hogar', 3),
      ('casa', 3),
      ('terraza', 3),
      ('pizza', 4),
      ('música', 5),
      ('pop', 5),
      ('rock', 5),
      ('instrumental', 5),
      ('leer', 6),
      ('libro', 6),
      ('biblioteca', 6),
      ('regalo', 7),
      ('jardín', 8),
      ('bosque', 8),
      ('plant', 8),
      ('pint', 9),
      ('cerámica', 9),
      ('cocinar', 10),
      ('cenar', 10),
      ('café', 10),
      ('playa', 11),
      ('mar', 11),
    ]) {
      if (text.contains(entry.$1)) return entry.$2;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: size * 4,
          maxWidth: size * 4,
          minHeight: size * 3,
          maxHeight: size * 3,
          child: Transform.translate(
            offset: Offset(-(index % 4) * size, -(index ~/ 4) * size),
            child: Image.asset(
              'assets/images/ui/quiz-objects-v5.webp',
              width: size * 4,
              height: size * 3,
              fit: BoxFit.fill,
            ),
          ),
        ),
      ),
    ),
  );
}
