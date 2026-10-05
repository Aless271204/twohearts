# Corre en pareja

El bosque se abre desde Juegos > Corre en pareja dentro de Flutter. Pip utiliza el archivo original de Meshy y sus animaciones Running, Regular_Jump e Idle_9. El selector y la mascota elegida también utilizan ese modelo; las demás mascotas conservan sus recursos.

## Probar en Chrome

Abre esta carpeta en Visual Studio Code, ejecuta `flutter pub get` y después `flutter run -d chrome --dart-define-from-file=env.json`. Inicia sesión, abre Juegos y juega una partida. Al terminar, comprueba el mensaje de guardado y vuelve al menú para ver el saldo y el récord. Repite la prueba cerrando y abriendo la app para comprobar la persistencia.

La vista previa independiente es práctica y no guarda recompensas. En Flutter se usa la sesión de la cuenta actual. La música comienza al pulsar Jugar y puede silenciarse. Los controles son flechas/A/D para cambiar de carril y espacio/flecha arriba para saltar; en móvil se usan los botones o gestos.

## Base de datos

Las migraciones del bosque y la función `forest-runner` están desplegadas en el proyecto NIDO APP. El servidor vuelve a simular los movimientos, calcula la recompensa y actualiza `game_stats`, `game_scores` y `game_records` en una transacción. Cada sesión solo acredita monedas una vez. Se permiten hasta 500 monedas por partida y 1000 por día UTC. Una partida dura como máximo 20 minutos; un envío pendiente puede recuperarse durante 24 horas.

La función requiere un JWT válido. Las operaciones de inicio y recompensa solo pueden ejecutarse con el rol del servidor; los usuarios solo pueden leer sus propias sesiones. Las claves del servidor nunca se incluyen en Flutter.

Los otros minijuegos conservan el sistema anterior, que permite al cliente actualizar su saldo. Por eso la validación del bosque no protege todavía toda la economía de la app; antes de una publicación comercial se debe migrar ese sistema también.

## Comprobaciones y distribución

GitHub Actions ejecuta las pruebas del simulador, el análisis de Flutter y las compilaciones web y Android. Sus artefactos contienen la web y un APK de prueba. La configuración de compilación incluye únicamente la URL pública, la clave pública de Supabase y el identificador público de Google.

Los modelos están incluidos en la app. El motor Three.js se carga de una versión fija en CDN, de modo que se necesita conexión para abrir el bosque. Antes de publicar en las tiendas conviene empaquetar también ese motor y probar rendimiento en dispositivos reales.

El APK de prueba no es una versión de tienda. Google Play requiere un AAB firmado y la configuración de publicación; App Store requiere compilar y firmar en macOS, además de la cuenta de Apple Developer. Ninguna de esas publicaciones se realiza con esta integración.
