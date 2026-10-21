# Tienda y juegos — 21 de octubre de 2026

## Cambios

- Carrusel general de los ocho conjuntos de habitación y tres outfits antes de los filtros. Vista completa del conjunto activo; una sola escena 3D a la vez. Artículos agrupados en carruseles por categoría, sin el antiguo límite de 16 productos. Flechas y deslizamiento. Previsualización separada del inventario guardado y compras confirmadas mediante las cotizaciones actuales del servidor.
- La habitación de muestra incorpora las 14 piezas colocables, además de pared, suelo y lámpara de techo, incluso si comparten ranura. Se utilizan los objetos reales existentes; el acabado no se certifica idéntico a la ilustración de referencia.
- Ranking con portada y podio interactivo, sin animación continua en la portada.
- Nieve: fondos distintos por mapa, escenario estático cacheado, resolución limitada y presentación a 30 fps. Cuenta atrás de tres segundos validada por el servidor antes del minuto completo. Aviso rojo en los últimos diez segundos y posiciones iniciales permutadas de forma determinista. Salas de dos a cuatro jugadores.
- Ping pong: animación de pelota y paleta mediante repintado, sin reconstruir el árbol de widgets en cada fotograma ni en cada movimiento del dedo. Extrapolación visual limitada a 350 ms; no cambia las colisiones ni los premios del servidor. Se mantienen los cuatro power-ups existentes.
- Preguntas: 36 nuevas, 96 en servidor. Ilustraciones del atlas existente o iconos semánticos para todas las opciones. Entrenamiento usa un mazo aleatorio sin repetir hasta agotarlo.
- Penales: silbato al habilitar cada turno; fuegos artificiales y sonido al ganar. Efecto limitado a 90 partículas y 3,2 segundos, respeta movimiento reducido.
- Senderos: eventos por kilómetro y reglas de reproducción versión 11; partidas anteriores conservan su versión.
- Paquetes propuestos: 600/US$1,99, 2.000/US$5,99 y 10.000/US$24,99. Compras reales desactivadas; se retiraron beneficios de voz/crecimiento aún no disponibles.

## Verificación

- 14 pruebas Flutter aprobadas: entrenamiento, captura de ping pong/preguntas, ranking y economía. Capturas reales de widgets en `outputs/duo-visual-review`; no son capturas de Chrome ni de un teléfono físico.
- Dos pruebas adicionales de distribución completa de habitación y cobertura del paquete premium aprobadas.
- 12 pruebas Node de nieve, caché y eventos kilométricos aprobadas.
- Prueba de base de datos local: capacidad de cuatro jugadores, controles de acceso, requisitos de Listo, revancha conservando sala y recompensas idempotentes.
- Migración de preguntas aplicada: 96 filas, todas con tres opciones. `snow-arena` versión 4 activa, JWT requerido, hash `519de9a326028f21417a679afd25e8bb984cd27845ef9b1978b1962ace867587`.

## Límites

No se ha medido FPS en el Pixel 6 ni probado cuatro teléfonos simultáneamente. La herramienta Windows no pudo confirmar la URL de Chrome y se detuvo; no se eludió esa restricción. Los cambios se validan mediante pruebas y compilación. El APK 1.3.2 ya entregado conserva su código anterior y no se sustituye por una compilación diferente con la misma versión.

Versus personalizados: se pueden construir con las cuatro mascotas y sus prendas reales en el renderizador actual, sin contratar otro servicio. La secuencia aún no está implementada.
