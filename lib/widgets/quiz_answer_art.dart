import 'package:flutter/material.dart';
import 'duo_object_art.dart';

/// Every answer has an illustration, including answers outside the original atlas.
class QuizAnswerArt extends StatelessWidget {
  final String answer, category;
  const QuizAnswerArt({super.key, required this.answer, this.category = ''});
  static IconData iconFor(String answer, String category) {
    final text = answer.toLowerCase();
    final groups = <IconData, List<String>>{
      Icons.pets_rounded: ['perro', 'gato', 'conejo', 'mascota', 'pip'],
      Icons.icecream_rounded: ['helado', 'vainilla', 'fresa'],
      Icons.local_cafe_rounded: ['café', 'té', 'chocolate caliente'],
      Icons.cake_rounded: ['tarta', 'dulce', 'chocolate', 'postre'],
      Icons.restaurant_rounded: [
        'sushi',
        'hamburguesa',
        'arroz',
        'tacos',
        'comida',
        'cen',
        'cocina',
        'pizza',
        'pasta',
        'nachos',
        'salado',
        'picante',
      ],
      Icons.breakfast_dining_rounded: ['desayuno', 'tostad', 'pan y'],
      Icons.spa_rounded: [
        'fruta',
        'mango',
        'sandía',
        'verde',
        'plant',
        'campo',
        'parque',
      ],
      Icons.flight_rounded: ['avión', 'viaj', 'isla', 'escapada'],
      Icons.train_rounded: ['tren'],
      Icons.directions_car_rounded: ['coche'],
      Icons.location_city_rounded: [
        'ciudad',
        'londres',
        'parís',
        'roma',
        'francia',
        'inglaterra',
        'japón',
      ],
      Icons.museum_rounded: ['museo', 'artesanía'],
      Icons.landscape_rounded: [
        'montaña',
        'escalada',
        'cascad',
        'desierto',
        'explora',
        'aventura',
        'safari',
      ],
      Icons.beach_access_rounded: ['playa', 'mar', 'sol', 'verano'],
      Icons.ac_unit_rounded: ['nieve', 'invierno', 'frío'],
      Icons.wb_sunny_rounded: ['mañana', 'calor', 'temprano', 'atardecer'],
      Icons.cloud_rounded: ['nube', 'nublado'],
      Icons.nightlight_round: ['noche', 'luna', 'aurora'],
      Icons.bedtime_rounded: ['dormir', 'descans', 'tranquilo'],
      Icons.home_rounded: ['casa', 'hogar', 'apartamento', 'cabaña', 'hotel'],
      Icons.photo_camera_rounded: ['foto', 'álbum', 'postal', 'recuerdo'],
      Icons.palette_rounded: [
        'pint',
        'crear',
        'cerámica',
        'hecho a mano',
        'pastel',
        'neutro',
        'vivos',
        'azul',
        'rosa',
        'amarillo',
        'negro',
        'turquesa',
        'dorado',
        'lila',
        'plata',
      ],
      Icons.menu_book_rounded: [
        'leer',
        'libro',
        'biblioteca',
        'aprender',
        'idioma',
      ],
      Icons.edit_rounded: ['escribir'],
      Icons.music_note_rounded: [
        'música',
        'pop',
        'rock',
        'instrument',
        'piano',
        'guitarra',
        'batería',
        'concierto',
        'cantar',
        'escuchar',
      ],
      Icons.directions_run_rounded: [
        'baile',
        'bailar',
        'salsa',
        'bachata',
        'tango',
        'caminar',
        'paseo',
        'salir',
      ],
      Icons.sports_tennis_rounded: ['ping pong'],
      Icons.sports_esports_rounded: ['juego', 'pregunta', 'atraccion'],
      Icons.movie_rounded: ['película', 'comedia', 'romance'],
      Icons.card_giftcard_rounded: [
        'regalo',
        'sorpresa',
        'experiencia',
        'algo que',
      ],
      Icons.favorite_rounded: [
        'abrazo',
        'cariño',
        'compañía',
        'juntos',
        'momento',
        'logro',
      ],
      Icons.chat_bubble_rounded: ['hablar', 'palabra', 'llamar'],
      Icons.checklist_rounded: ['plan', 'organizado', 'esencial', 'improvisar'],
      Icons.backpack_rounded: ['mochila'],
      Icons.checkroom_rounded: ['bufanda', 'sombrero'],
      Icons.candlestick_chart_rounded: ['vela'],
      Icons.pool_rounded: ['natación'],
    };
    for (final group in groups.entries) {
      if (group.value.any(text.contains)) return group.key;
    }
    return switch (category.toLowerCase()) {
      'comida' => Icons.restaurant_rounded,
      'viajes' => Icons.explore_rounded,
      'mascotas' => Icons.pets_rounded,
      'colores' => Icons.palette_rounded,
      'música' => Icons.music_note_rounded,
      'hábitos' => Icons.schedule_rounded,
      'hobbies' || 'tiempo libre' => Icons.interests_rounded,
      'hogar' => Icons.home_rounded,
      _ => Icons.favorite_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (DuoObjectArt.forAnswer(answer) case final int index) {
      return DuoObjectArt(index: index, size: 68);
    }
    return Semantics(
      label: 'Ilustración: $answer',
      image: true,
      child: Container(
        width: 68,
        height: 68,
        margin: const EdgeInsets.only(right: 3),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFEDE2), Color(0xFFF0E7F5)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              iconFor(answer, category),
              color: const Color(0xFFB56C83),
              size: 38,
            ),
            const Positioned(
              top: 5,
              right: 5,
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 12,
                color: Color(0xFFBF9146),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
