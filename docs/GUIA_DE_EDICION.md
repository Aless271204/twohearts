# Guía para editar TwoHearts

La app mantiene separadas la presentación, los datos y el comportamiento. Esta guía describe los archivos reales del proyecto; no implica que se haya reescrito toda la aplicación.

## Dónde cambiar cada parte

| Cambio | Archivo o carpeta |
|---|---|
| Colores y tipografía globales | `lib/theme/app_theme.dart` |
| Botones, tarjetas y barra de las cinco pestañas | `lib/widgets/twohearts_ui.dart` |
| Pantallas de carga y mensajes | `lib/widgets/rose_ui.dart`, `lib/widgets/scene_status.dart` |
| Rutas de la aplicación | `lib/routes/app_routes.dart` |
| Pantallas de cada sección | `lib/presentation/` |
| Frase, mapa, estadísticas y habitación | `lib/presentation/home_screen/widgets/` |
| Objetos del catálogo de habitación | `lib/core/room_catalog.dart` |
| Ubicación y dibujo de esos objetos | `lib/widgets/room_catalog_scene.dart` |
| Habitaciones y objetos anteriores | `lib/widgets/inventory_scene.dart` |
| Catálogo de accesorios de mascota | `lib/core/pet_accessory_catalog.dart` |
| Modelos de mascotas | `lib/core/pet_model_catalog.dart` |
| Tienda, filtros y prueba de objetos | `lib/presentation/shop_screen/inventory_screen.dart` |
| Inventario, objetos compartidos y operaciones de compra | `lib/services/inventory_service.dart` |
| Cuidados y progresión compartida | `lib/services/shared_pet_service.dart` |
| Idiomas | `lib/services/app_language.dart` |
| Música y propiedad del audio por escena | `lib/services/audio_service.dart`, `lib/services/scene_audio_policy.dart` |
| Álbum y fotografías privadas | `lib/services/memory_album_service.dart` |
| Juego del bosque | `assets/runner/game.js` |
| Geometría de accesorios | `assets/runner/accessory-pieces.js` |
| Ajuste a huesos y proporciones | `assets/runner/cosmetics.js` |
| Respiración y caricias | `assets/runner/pet-motion.js` |
| Recursos gráficos | `assets/images/` |
| Backend y validadores | `supabase/functions/`, `supabase/migrations/` |
| Verificaciones | `test/` |

## Añadir, quitar o modificar un artículo de habitación

Cada línea `roomItem(...)` en `lib/core/room_catalog.dart` es un artículo independiente. Sus argumentos son identificador, nombre, espacio de colocación, categoría, estilo, color y posición de su imagen en el atlas. Los identificadores y posiciones están escritos explícitamente: quitar o reordenar una línea no altera las imágenes de los demás.

Para ocultar un concepto local, elimina o comenta su línea. Para cambiar su texto, edita el nombre. No reutilices el identificador de otro objeto. Eliminar un concepto local no borra compras ya publicadas en el servidor: estas tienen prioridad al cargar el catálogo.

Para añadir una imagen propia sin regenerar el atlas:

```dart
roomItem('mi_sillon', 'Sillón lavanda', 'room_chair', 'Muebles',
  'lavender_chair', '#BAA2DB', null,
  imageAsset: 'assets/images/products/mi-sillon.png'),
```

Pon una imagen PNG transparente en esa ruta. La tienda y la habitación usarán la misma imagen. Para un fondo o un suelo, utiliza su espacio correspondiente y un recurso que cubra la superficie. El archivo `pubspec.yaml` ya incluye las carpetas de imágenes utilizadas aquí; una carpeta nueva requiere declararla.

`placementFor` en `room_catalog_scene.dart` define el lugar del objeto en coordenadas 300 × 350, escaladas a la pantalla. Los muebles se colocan fuera del centro para que la mascota siga siendo protagonista. Cambiar un espacio afecta a todos sus artículos; crea otro espacio si necesitas una segunda posición independiente y añádelo también a `InventoryItem.slots`.

## Separación entre prueba y propiedad

Los nuevos artículos tienen `preview_only: true`. Se pueden probar juntos en el dispositivo, cambiar de pestaña y restaurar la habitación. Esta prueba dura la sesión: no gasta monedas ni se presenta como una compra o como un cambio compartido con la pareja.

Publicar precios y habilitar compras exige añadir los artículos al catálogo del servidor con sus espacios admitidos y permisos. No basta con quitar `preview_only` en Flutter. Los objetos ya comprados y la habitación compartida conservan sus datos.

## Reglas al continuar el desarrollo

Coloca datos editables en `core`, dibujado reutilizable en `widgets`, pantallas en `presentation` y estado o persistencia en `services`. Evita duplicar catálogos o añadir otra moneda. No cambies la navegación para introducir un objeto. Mantén separadas las previsualizaciones (`design_preview_main.dart`) de la entrada real (`main.dart`). Los archivos de `sources/` son referencias de solo lectura.

Antes de publicar, verifica las piezas modificadas. Para el catálogo actual: `flutter test test/room_catalog_test.dart test/inventory_test.dart`. Si amplías el catálogo aprobado, actualiza también sus cantidades esperadas en la prueba. Para modelos: las pruebas `pet_accessory_fit_test.mjs` y `inventory_cosmetics_test.mjs` comprueban ajustes y animaciones. No se generó un APK como parte de esta integración.
