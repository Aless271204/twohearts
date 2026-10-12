# Accesorios de cabeza ajustados en Blender

Los cinco GLB Meshy originales se conservan. Se producen veinte variantes:
gorra, sombrero, gorro, boina y peluca para pingüino, oso, cerdito y pollito.

## Archivos que puedes editar

- `design/blender/fitting/NIDO-cabeza-encaje.blend`: taller con las mallas editables,
  materiales empaquetados, originales conservados y las dieciséis combinaciones activas.
  Abre mostrando solamente el pingüino con gorra. En el Outliner se puede activar
  la mascota y la prenda que se quiera revisar, ocultando la anterior.
- `design/blender/head-tailoring.json`: dimensiones y criterios de confección por mascota y artículo.
- `assets/runner/blender-head-models.json`: códigos de inventario y rutas de cada variante.
  Se mantiene separado del catálogo de venta durante la revisión.
- `assets/runner/accessories/*_SPECIES_blender.glb`: geometría resultante por especie.
- `assets/runner/accessories/head_texture_*`: imágenes compartidas entre las variantes.
  No borrar esas imágenes al trasladar un GLB; el `.blend` sí incluye sus texturas.

## Qué cambia en las piezas

Blender corrige copa, profundidad y visera de la gorra; adapta el volumen de las otras
piezas; crea el interior alrededor del cráneo y permite que las orejas sobresalgan.
Los mechones abiertos de la peluca reciben un tratamiento de superficie y una base
interior de cabello. No se aplica una resta de volumen a esos mechones, porque
provoca roturas. Las UV y la imagen de color de Meshy se conservan; la respuesta
del material se adapta a tela sin brillo metálico.

La mascota de referencia usa exactamente la postura y geometría evaluadas en el
motor de la app, incluidos los retoques del pingüino. Las crestas del pingüino y del
pollito se recogen al vestir un sombrero y se restauran al retirarlo. El GLB original
de la mascota no se modifica.

## Flujo de actualización

1. `scripts/prepare-blender-fitting.mjs` obtiene los maniquíes de la app.
2. Blender ejecuta `scripts/blender-tailor-heads.py` para confeccionar y exportar.
3. `scripts/package-blender-heads.py` separa las imágenes idénticas para compartirlas.
   No redimensiona ni recomprime las texturas.
4. `scripts/register-blender-heads.py` registra las variantes para previsualización.
5. `test/blender_head_fit_test.mjs` comprueba las dieciséis piezas activas, UV, imágenes,
   procedencia, dimensiones y unión al hueso durante carrera, salto y escalas.

La integración utiliza `fitted_model_space` para impedir una segunda deformación
o escala sobre la malla ya confeccionada, y `species_models` para elegir la pieza
correcta. Si falta el modelo importado se muestra un error; no se sustituye por
un sombrero genérico.

## Revisión

En navegador: `assets/runner/head-fit-review.html?blender=1`.
Cada tarjeta permite abrir la mascota en 3D, elegir ángulo y probar carrera y salto.
Las miniaturas de esta revisión salen de los mismos GLB usados para vestirla.
Las pruebas de animación y las imágenes permiten revisar el resultado, pero no
certifican que sea idéntico a la imagen conceptual ni garantizan ausencia de
cualquier intersección en poses nuevas. No se publica un APK ni se activa la venta
de estas variantes mediante este flujo.

La copa conserva altura y el asiento baja alrededor del cráneo. Los sombreros de paja reciben un espesor real antes del recorte interior, para impedir que una superficie abierta desaparezca al crear las aberturas de las orejas.

## Revisión de la gorra del pingüino

La variante del pingüino tiene un perfil propio en `species_fit`: copa de 0,31,
base de 0,805 y visera de 0,105 en las coordenadas normalizadas de la app.
Conserva las texturas del original. Se revisaron frente, perfil y tres cuartos.
Para reconstruir solo esta pieza: `blender-tailor-heads.py --cap-only --penguin-only --skip-render`,
seguido de empaquetado y registro. El informe conserva las otras quince variantes.
`blender-update-penguin-cap.py` incorpora esta pieza al taller compartido.
La revisión visual detectó además deformaciones del cuerpo en la animación Running;
la unión de la gorra pasa las pruebas, pero esto no certifica el acabado de esa animación.
