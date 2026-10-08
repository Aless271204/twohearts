# Bosque animado · NIDO 1.1.1+6

El paisaje es una ilustración animada en un video local. El puente, Pip, los obstáculos y las monedas permanecen en 3D interactivo dentro del visor existente de Flutter. El reino y las cascadas mantienen la estética de la referencia.

## Integración visual

- El fondo contiene una isla de llegada con piedra y vegetación, un pequeño tramo lejano de puente y un sendero que asciende hacia los cruces de la cascada. Su punto de fuga se alinea con el puente jugable.
- Los nueve tramos reciclables mantienen tablones, cuerdas y clavos. Se añadieron pilares de madera bajo ambos bordes. Se comparten geometrías y materiales entre tramos.
- El MP4 local dura 8 segundos: 540 × 1140, 24 FPS, H.264 baseline, sin audio, 1.820.381 bytes. Agua, cascadas y follaje reciben movimiento periódico suave; la cámara permanece fija. Los 192 fotogramas se renderizaron desde la ilustración. Los metadatos están al inicio del archivo.
- El JPEG es el respaldo si el dispositivo no reproduce el video. El fondo requiere dos triángulos. Se conserva la proporción del arte y se corrige el color del video antes de la salida sRGB.
- Pausar detiene el video inmediatamente. También se detiene al ocultar la app y se libera al cerrar el juego.
- Flutter incluye el MP4 en sus recursos. El servidor local responde con video/mp4 y admite rangos de bytes para reproducción y reinicio del bucle sin conexión.
- Se empaquetan solo los cuatro modelos del recorrido: Pip, caja, valla y roca, 23.380.776 bytes en total. Son copias exactas de los originales. Se conservan la identidad, las animaciones y los accesorios de Pip.

## Jugabilidad y validación

Se mantienen carriles, saltos, colisiones, dificultad progresiva, replay versión 2, recompensas y equipamiento. El reino es el destino visual de un recorrido en bucle.

Las 16 comprobaciones de JavaScript pasaron. La partida en Chrome verificó video en reproducción, pausa del video y del recorrido, cambios de carril, salto, tres monedas y colisión final a los 96 metros, sin errores. Las muestras registraron 26.929–40.183 triángulos; no son un máximo universal ni una medición de rendimiento en teléfono. La captura está en tropical-preview.png.

GitHub Actions ejecuta pruebas de Flutter, compila Android en modo optimizado y comprueba el visor en un emulador Android sin red: reproducción del video, entrega parcial de bytes, pausa, reanudación y jugabilidad. La publicación del APK está condicionada al éxito de esas comprobaciones. La versión 1.1.1+6 identifica esta entrega.

## Arte y reproducción del bucle

Se editó la ilustración con ImageGen conservando castillo, montañas, cascadas, coníferas y río turquesa. Se pidió una pequeña orilla central bajo la cascada inferior, con puente apoyado y sendero ascendente, dejando libre el río del primer plano para superponer el puente 3D. No se incluyeron interfaz ni personaje en el fondo.

El procedimiento reproducible está en test/build_forest_loop.cjs. Requiere Playwright, Chrome y FFmpeg en el entorno de creación. La app instalada no necesita esas herramientas ni servicios externos de generación.

## APK publicado y firma

La entrega 1.1.1+6 pasó las pruebas de Flutter y la prueba del recorrido en Android sin red, en GitHub Actions 37820996360. El APK publicado mide 106.556.884 bytes y su SHA-256 es 7332df9e7bce3d3a4cc8d2ed2c4451662800020d681c6e5b07b98a3aef745fba. Se descargó y comprobó que contiene el MP4, el JPEG, el código del juego y los cuatro modelos previstos, con soporte arm64.

Descarga: https://github.com/Aless271204/twohearts/releases/download/bosque-1.1.1/NIDO-1.1.1-bosque.apk

La clave antigua no se recuperó de la caché de compilación. Se compararon los certificados públicos de este APK y el anterior TwoHearts 1.1.0: son distintos. Por tanto, la instalación anterior no admite actualización directa con esta entrega; requiere reinstalación, conservando antes los datos locales que se necesiten. La generación y la lectura independiente del QR de descarga también se verificaron.