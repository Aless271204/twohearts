# Habitación y tienda: revisión 3D

## Implementación

La habitación de la mascota y la prueba de productos en Flutter utilizan un único contexto Three.js. La mascota, los muebles y las superficies comparten cámara, suelo y luces. `PetRoomStage` configura `Pet3DViewer` en modo habitación; las versiones web y Android/iOS transmiten `room=1` al mismo motor.

Los 20 artículos nuevos y las 24 variantes de habitación existentes son geometría editable de `assets/runner/room-pieces.js`. `createRoomPiece` produce el objeto usado tanto en la habitación como en sus fotografías. Las superficies de pared y suelo reemplazan las anteriores; no son recortes superpuestos. Los muebles se apoyan en el suelo, con posiciones en metros definidas por `ROOM_ANCHORS`. El centro se reserva para la mascota. La geometría se agrupa por material dentro de cada artículo para reducir las llamadas de dibujo, sin fusionar productos independientes.

## Cambiar el inventario manualmente

- Nombres, categorías y visibilidad de habitación: `lib/core/room_catalog.dart`. `visible: false` oculta una entrada de prueba. Mantener `item_key` estable para no romper inventarios existentes.
- Formas, colores de partes y posiciones: `assets/runner/room-pieces.js`. Añadir un estilo requiere implementarlo en la fábrica, definir su anclaje y volver a generar su miniatura.
- Accesorios: `assets/runner/accessory-catalog.json`; `visible: false` oculta artículos. `model_asset` identifica el GLB; `preview_only` debe continuar activado mientras el artículo no esté validado para venta.
- Renders de revisión: `assets/runner/room-review.html` y `accessory-review.html`. Las imágenes expuestas en sus tarjetas proceden de los modelos reales. Guardar los PNG de las tarjetas en `assets/images/products` después de modificar un modelo; no sustituirlos por una ilustración idealizada distinta.
- Catálogo JSON del visor de revisión: ejecutar `scripts/sync-room-review.py` tras editar el catálogo Dart. Es una copia para revisión, no un segundo inventario ni una fuente de precios.
- Los productos publicados y precios de compra se validan en el servidor. Cambiar un precio local no cambia el cobro. Ocultar o modificar productos publicados también exige sincronizar el catálogo del servidor; no borrar referencias de artículos que ya pertenecen a usuarios.

## Carga y coherencia

El motor espera los GLB antes de equipar. Si un GLB solicitado falla, no se sustituye silenciosamente por otra pieza. Se mantiene el límite de espera de carga y se muestra un estado claro de reintento cuando falla la carga o se pierde WebGL. En la habitación se conservan las texturas suministradas de la mascota; la optimización de textura del recorrido permanece independiente.

## Validación y límites

Las pruebas comprueban los 20 modelos, límites finitos, pocas mallas por artículo, cobertura de paredes/suelo, apoyo de muebles y sustitución de superficies. Las pruebas anteriores de accesorios comprueban anclajes y seguimiento del esqueleto en las cuatro mascotas; eso NO demuestra ausencia de intersecciones de ropa durante cada fotograma.

La revisión visual confirma un problema pendiente: ciertas prendas rígidas, especialmente la camiseta sobre el oso, aún no cubren el torso como ropa real. No están listas para presentarse como ropa premium. Necesitan cortes/aberturas y pesos de deformación ajustados al rig de cada especie. No hay Blender instalado localmente ni un conector de Meshy disponible en esta sesión. Un GLB de Meshy sin adaptación al rig no resuelve por sí solo este defecto.

No se han activado compras reales ni publicado un APK con estos cambios. Quedan pendientes la validación en teléfonos Android/iOS, las prendas por especie y animación, y el catálogo implementado de personalización de interfaz. La habitación es una implementación 3D funcional de revisión, no una declaración de que todo el inventario sea perfecto.

Los fondos de la prueba de ping pong y de las pantallas de espera se han cambiado a blanco cálido con texto oscuro. La confirmación del usuario aclaró que el fondo negro observado era una elección estética, no un fallo de carga reproducido. Los estados de fallo 3D se han reforzado por separado; no se afirma haber reproducido un fallo en su teléfono.
