import 'package:flutter/material.dart';

class NidoArticle {
  final String id, title, summary, category;
  final DateTime published;
  final IconData icon;
  final List<(String, String)> sections;
  const NidoArticle(this.id, this.title, this.summary, this.category,
      this.published, this.icon, this.sections);
}

// Editorial entries ship with the app. Dates describe publication of the guide,
// not the release of features that may still be under review.
final nidoArticles = <NidoArticle>[
  NidoArticle('welcome', 'Tu pequeña guía de NIDO',
      'Un lugar para compartir, jugar y cuidar su nido.', 'Guía',
      DateTime(2026, 10, 20, 12), Icons.auto_awesome_rounded, const [
    ('Empieza por su Nido', 'En Nido encontrarás sus recuerdos, indicadores, frase y álbumes. Completa los datos de la relación en Configuración para que sus indicadores tengan una fecha de referencia.'),
    ('Conecta con tu persona', 'En Configuración puedes consultar tu código de cuenta y enlazarlo con el de tu pareja. El código de pareja y el código de una sala de juego cumplen funciones diferentes.'),
    ('Una mascota, muchas historias', 'Tras enlazarse podrán adoptar una mascota. En Mascota, el cofre reúne sus objetos; en Tienda pueden probar, comprar y equipar accesorios con oro.'),
    ('Comparte a tu ritmo', 'Social reúne sus publicaciones y las de otras personas. Revisa qué vas a compartir y los permisos de fotos y ubicación en Configuración.'),
  ]),
  NidoArticle('updates', 'Las novedades tienen un lugar aquí',
      'Actualizaciones y minitutoriales, reunidos por fecha.', 'Noticias',
      DateTime(2026, 10, 20, 11), Icons.campaign_rounded, const [
    ('Noticias y guías', 'Este espacio reúne avisos de NIDO y una ayuda breve para cada juego. Las publicaciones más recientes aparecen primero; puedes distinguir Noticias de Guías.'),
    ('Cada mejora, con su estado', 'Los anuncios de nuevas versiones indicarán qué cambia y cuándo está disponible. Una guía explica cómo jugar; no significa que una actualización pendiente ya esté publicada.'),
  ]),
  NidoArticle('runner', 'Senderos del Nido · Corre y descubre',
      'Monedas, estaciones y un camino cada vez más desafiante.', 'Guía',
      DateTime(2026, 10, 20, 10, 7), Icons.forest_rounded, const [
    ('Tu objetivo', 'Corre, recoge monedas y evita obstáculos. Mira hacia delante: cada tramo puede combinar obstáculos y premios de manera distinta.'),
    ('Cómo jugar', 'Usa los controles que aparecen en pantalla para cambiar de carril, saltar o deslizarte. El escudo rodea a tu mascota y te protege mientras está activo.'),
    ('El recorrido cambia', 'Primavera va de 0 a 2 km; verano, de 2 a 4; otoño, de 4 a 6; invierno, de 6 a 8. Después llega la tormenta y el camino exige más atención.'),
    ('Un consejo', 'Un premio no siempre merece un salto arriesgado. Guarda el resultado al terminar para solicitar el oro de la partida.'),
  ]),
  NidoArticle('guardian', 'Guardianes del Alba · Enciende la aventura',
      'Dispara, esquiva y aprende las señales de cada jefe.', 'Guía',
      DateTime(2026, 10, 20, 10, 6), Icons.wb_twilight_rounded, const [
    ('Tu objetivo', 'Avanza por el bosque o el río, reúne botín y llega al guardián. Sus ataques tienen señales: observa antes de acercarte.'),
    ('En celular', 'Todos los controles aparecen en pantalla. En ajustes puedes escoger la distribución de movimiento, salto, esquiva y disparo que te resulte más cómoda.'),
    ('En laptop', 'A/D o flechas: moverte. Espacio o W: saltar. J o F: disparar. Shift o Q: esquivar. E: mejorar el poder en los puntos habilitados. Esc: pausar.'),
    ('Farolitos y defensa', 'Cuando la defensa del jefe se cierre, sigue la indicación de los faroles. Acércate y mantén Disparar para encenderlos; aprovecha la apertura para atacar.'),
    ('Elige tu reto', 'Fácil empieza con cinco vidas, medio con tres y difícil con una. En difícil no hay corazones extra: coordinarse y leer los ataques es esencial.'),
  ]),
  NidoArticle('pong', 'Ping pong · Una más y ganamos',
      'Domina la paleta y aprovecha los regalos del campo.', 'Guía',
      DateTime(2026, 10, 20, 10, 5), Icons.sports_tennis_rounded, const [
    ('Tu objetivo', 'Devuelve la pelota y haz que sobrepase la paleta rival. Cada persona ve su propia paleta abajo.'),
    ('Cómo moverla', 'Desliza sobre el campo para mover la paleta. En laptop, arrastra con el ratón. Anticipa la trayectoria de la pelota en lugar de perseguirla al último instante.'),
    ('Regalos y práctica', 'Los potenciadores pueden ampliar la paleta, protegerte o cambiar el ritmo. Prueba Entrenar para familiarizarte con sus efectos antes de jugar con otra persona.'),
  ]),
  NidoArticle('quiz', '¿Cuánto nos conocemos? · Adivina con cariño',
      'Descubre lo que respondería la otra persona.', 'Guía',
      DateTime(2026, 10, 20, 10, 4), Icons.favorite_rounded, const [
    ('Dos momentos por pregunta', 'Primero responde sobre ti; después intenta adivinar la respuesta de la otra persona. Lee el encabezado para distinguir cada momento.'),
    ('Veinte segundos', 'Cada respuesta tiene un tiempo de 20 segundos. Confirma tu elección antes de que termine el contador.'),
    ('Mira sus reacciones', 'Entre preguntas aparece el resultado durante cinco segundos y una breve presentación de la siguiente. Las mascotas reaccionan según los aciertos y las rachas.'),
  ]),
  NidoArticle('art', 'Pincel en pareja · Cinco minutos de imaginación',
      'Una referencia sorpresa y dos maneras de dibujarla.', 'Guía',
      DateTime(2026, 10, 20, 10, 3), Icons.palette_rounded, const [
    ('Elige la dificultad', 'Fácil utiliza formas y pocos objetos; medio añade detalles; difícil combina mascota o protagonista, acción y entorno.'),
    ('La sorpresa empieza dentro', 'La referencia se revela al entrar a la partida. Cuando esté preparada, empieza el tiempo para dibujar. Busca primero las formas grandes.'),
    ('Pinta y compara', 'Usa los pinceles, colores y herramientas del lienzo. Al terminar pueden compartir, comparar, votar y descargar sus dibujos con las opciones de la partida.'),
  ]),
  NidoArticle('penalties', 'Goles y abrazos · Tu turno de brillar',
      'Patea, ataja y vive la emoción de los penales.', 'Guía',
      DateTime(2026, 10, 20, 10, 2), Icons.sports_soccer_rounded, const [
    ('Lanzador o arquero', 'Los papeles se alternan. Mira cuál te corresponde antes de elegir tu acción: la cámara cambia con el turno.'),
    ('Quince segundos', 'Dispones de 15 segundos para realizar tu elección. Utiliza los controles en pantalla para apuntar y patear, o elegir hacia dónde lanzarte.'),
    ('Hasta el último penal', 'Cada jugador tiene cinco penales. Si continúan empatados, la muerte súbita decide el resultado una vez que ambos hayan tenido el mismo número de intentos.'),
  ]),
  NidoArticle('maze', 'Farolitos del Nido · Una luz entre sorpresas',
      'Explora el laberinto, busca llaves y elige tus cofres.', 'Guía',
      DateTime(2026, 10, 20, 10, 1), Icons.flashlight_on_rounded, const [
    ('Tu objetivo', 'Encuentra las llaves necesarias y llega a la puerta de salida. La linterna ilumina una parte pequeña del camino: avanzar con calma también es una estrategia.'),
    ('Cómo explorar', 'Usa los controles de movimiento y mirada de la pantalla. Acércate a cofres y llaves para interactuar con ellos cuando aparezca la indicación.'),
    ('Truco o recompensa', 'Algunos cofres esconden sorpresas. Atiende a los sonidos, recuerda las bifurcaciones y revisa la opción de sustos si prefieres una exploración más tranquila.'),
  ]),
];

class NidoNews extends StatefulWidget {
  const NidoNews({super.key});
  @override
  State<NidoNews> createState() => _NidoNewsState();
}

class _NidoNewsState extends State<NidoNews> {
  String filter = 'Noticias';
  @override
  Widget build(BuildContext context) {
    final articles = nidoArticles.where((a) => filter == 'Todo' || a.category == filter).toList()
      ..sort((a, b) => b.published.compareTo(a.published));
    return ListView(
      key: const PageStorageKey('nido-news'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      children: [
        const Text('Noticias y guías', style: TextStyle(fontFamily: 'Georgia',
            fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF392E36))),
        const SizedBox(height: 4),
        const Text('Lo nuevo y pequeñas ayudas para disfrutar NIDO.',
            style: TextStyle(color: Color(0xFF6D5864))),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [for (final value in ['Noticias', 'Guía'])
          ChoiceChip(label: Text(value == 'Guía' ? 'Guías' : 'Actualizaciones'),
            selected: filter == value, onSelected: (_) => setState(() => filter = value),
            selectedColor: const Color(0xFFFFDDE5),
            labelStyle: const TextStyle(color: Color(0xFF553744)))]),
        const SizedBox(height: 12),
        for (final article in articles) Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(color: const Color(0xFFFFFEFA), elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: Color(0xFFF0DEE0))),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(key: PageStorageKey(article.id),
              leading: CircleAvatar(backgroundColor: const Color(0xFFFFE7DA),
                  child: Icon(article.icon, color: const Color(0xFFB94F69))),
              iconColor: const Color(0xFFB94F69), collapsedIconColor: const Color(0xFF79596A),
              textColor: const Color(0xFF392E36), collapsedTextColor: const Color(0xFF392E36),
              title: Text(article.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Padding(padding: const EdgeInsets.only(top: 5), child: Text(
                '${article.category} · ${article.published.day}/${article.published.month}/${article.published.year}\n${article.summary}',
                style: const TextStyle(color: Color(0xFF6D5864), height: 1.45))),
              childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              children: [for (final section in article.sections) Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(section.$1, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF553744))),
                  const SizedBox(height: 4),
                  Text(section.$2, style: const TextStyle(color: Color(0xFF594C54), height: 1.5)),
                ]))],
            )),
        ),
      ],
    );
  }
}
