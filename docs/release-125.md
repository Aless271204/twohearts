# NIDO 1.2.5+20 — Pincel en pareja y notas privadas

Incluye Guardianes online y el logo de 1.2.4. Añade Pincel en pareja en Juegos:
referencias de las cuatro mascotas en tres escenas, tres dificultades, cinco
minutos y tres segundos de preparación; ambos participantes deben estar listos.
Pinceles, lápiz, marcador, acuarela, goma por capa, relleno, cuentagotas, formas,
texto, colores personalizados, tamaño/opacidad, tres capas, undo/redo y zoom.
Referencias personales: álbumes y fotos de Recuerdos, viajes guardados y destinos
futuros sin lista cerrada de países; carga de inspiración desde el teléfono.
Explorar incluye ocho fotos turísticas de Unsplash (Francia, Brasil, Inglaterra,
Egipto, Japón, Italia, Grecia y Perú) y dos ilustraciones originales con las cuatro
mascotas: picnic 3D en París y aventura pixel art de Guardianes. Catálogo editable
en art_reference_catalog.dart; fuentes y prompts en design/art-references.
Original, pixelado con mascota, foto con mascota 3D y boceto son transformaciones
locales. No se envían fotos privadas a IA externa ni se reconstruye una escena 3D
a partir de la foto. La dificultad reduce detalle/resolución de la referencia.
Las nuevas imágenes incluidas suman menos de 1 MB.

PNG descargable a Pictures/NIDO en Android moderno o compartible; fondo
transparente opcional. Borrador local rasterizado y recuperación de partida.

Servidor: pareja recíproca exclusivamente; identidad autenticada; imágenes
privadas, límite de tamaño y partidas diarias. El contrario no ve el dibujo
antes de enviar ambos. Cada voto es definitivo. Comparación automática local de
color, composición y cobertura: orientativa, no evalúa talento o mérito artístico,
no usa IA semántica ni entrega oro. Los votos deciden su ganador humano.
Guardar imágenes: PNG de 512 × 512. Los montajes personales usan retratos existentes;
las dos ilustraciones nuevas muestran acciones creadas para las respectivas escenas.

Inicio: foto de cámara o galería con confirmación, nota de hasta 500 caracteres,
dibujo libre y último envío del compañero. Widget Android NIDO · Para ti,
redimensionable, manual/al abrir y periódicamente cada 30 minutos sujeto a Android.
No hay FCM/push instantáneo. Cada teléfono añade su propio widget.
Permiso aleatorio de 256 bits de solo lectura de la última nota, revocable y
vencimiento 30 días. No se guardan tokens de sesión Supabase en el widget.
Revocación al cerrar sesión conectado; limpieza local incluso sin conexión.
Desenlazar cuentas impide lecturas. No se comparte nada con Social.

Las partidas online se conservan durante 30 días; la última nota persiste hasta
sustituirla o desvincularse. Tras autorización explícita del usuario se activa
limpieza diaria de partidas antiguas, permisos caducados y notas desvinculadas.
El autor puede guardar sus dibujos para conservarlos fuera de la app.

Verificación realizada: cinco pruebas de lienzo/referencia y capturas Flutter;
transacción real en Supabase comprueba pareja, reloj, rechazo anticipado, revelado,
voto inmutable, entrega de nota, token de widget revocado e intruso rechazado.
La transacción se revierte. CI debe pasar compilación Android y prueba de descarga
PNG/puente widget antes de publicar el APK. No es publicación en Google Play.
