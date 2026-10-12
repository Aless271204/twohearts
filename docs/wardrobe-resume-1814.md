# Punto de continuación: vestuario digital · 11 de octubre de 2026

## Entrega verificada · 12 de octubre de 2026

- APK publicado: NIDO 1.1.9+14, 247.399.846 bytes (247,4 MB).
- Código y activos de la app subidos: `2b761703bfb51f58809c34271e7052ce9c0de57a`.
- GitHub Actions 38208862649: verificación, Android y publicación aprobados.
- Descarga: https://github.com/Aless271204/twohearts/releases/download/nido-1.1.9/NIDO-1.1.9-actualizada.apk
- SHA-256: `68c2c3f9df8aaa2ce48aa4dbe194c19989650789ebf702fbc5f6d4c5835337a6`.
- Archivo descargado revisado: versión/código correctos, ZIP íntegro, 96 GLB y
  24 miniaturas con hashes exactos, 38 texturas compartidas idénticas y los siete
  módulos actuales del visor. Firma idéntica al APK 1.1.8 anterior.
- Evidencia en outputs/wardrobe-apk-verification.json y wardrobe-delivery-record.json.
- 13 pruebas locales de carga, encaje y movimiento, 4 pruebas de reparación de
  exportación y auditoría estricta de las 20 superficies de cuerpo aprobadas.
- Miniaturas regeneradas sin bajar resolución ni muestras; 24 procedencias
  comprobadas. Los diez archivos de cuerpo/cuello precedentes quedaron sustituidos.
- Capturas reales actuales: delivery-dulce-front.jpg, delivery-dulce-room.jpg,
  delivery-cozy-running-quarter.jpg, delivery-jardin-running-quarter.jpg,
  delivery-chic-jump-quarter.jpg, delivery-pastel-running-back.jpg, en
  outputs/wardrobe-proof/. El visor quedó disponible en el navegador.

Esta entrega conserva diferencias visuales respecto a la ilustración. Revisar
acabado de cuellos, puños, bordes alrededor de orejas y combinaciones extremas
en teléfono; no certificar identidad exacta ni impresión. Los artículos nuevos
conservan su estado de previsualización, precios y propiedad existente. Peluca,
cuidado/crecimiento sin modelos y cobros/anuncios reales pendientes siguen ocultos
o inactivos. La impresión se trabajará posteriormente.

## Actualización posterior: el usuario pidió continuar e incorporar todo al APK

La pausa descrita más abajo quedó revocada. Se activó la transferencia V3 para
los veinte cuerpos y veinte complementos de cuello: suaviza los pesos de hombro
y unifica las costuras UV sin modificar posiciones, normales ni texturas.
Las 12 pruebas del vestuario actual pasan (outputs/wardrobe-final-runtime-tests.log)
y las 9 pruebas Python pasan (outputs/wardrobe-v3-surface-tests.log).

Se corrigió una causa concreta de los rasgados: la máscara eliminaba un triángulo
completo si solo uno de sus vértices quedaba bajo la manga. Ahora retira únicamente
caras enteramente cubiertas y conserva el borde del brazo. Prueba de regresión
en pet_sleeve_coverage_test.mjs, revisión visible en los cuatro personajes con
el vestido durante salto y el conjunto Dulce frontal.

Se ajustó además el trazado de los accesorios de cuello para excluir los brazos
del contorno del torso y acercar la banda del moño al cuello. Conservar los
maestros, regenerar y verificar sus miniaturas antes del commit de entrega.
El respaldo outputs/wardrobe-v2-delivery-backup conserva el estado anterior,
salvo que su vestido de cerdito ya contiene el candidato V3 probado.

La versión sigue siendo de prueba: no afirmar identidad exacta con la ilustración.
La entrega debe ser APK firmado y descargable; los archivos locales no bastan.

### Reparación estructural y carrera natural

La auditoría de las veinte superficies de cuerpo encontró uniones múltiples en
las mangas y algunos bordes abiertos. `wardrobe_shells.py` repara el volumen con
un remallado de 1,8 mm, suavizado moderado y límite de 12.000 triángulos para la
superficie principal, transfiriendo las UV originales. Adornos y materiales se
conservan. La prueba de sudadera/pollito quedó con cero bordes abiertos y cero
uniones múltiples, y conservó su aspecto en el visor.

Se completó la reparación de las veinte superficies mediante
`blender-repair-wardrobe-shells.py`, sobre el maestro editable, con registro en
`outputs/wardrobe-final-shells.log` (SHELLS_READY). El maestro, los veinte GLB,
las texturas compartidas y los catálogos se guardaron y registraron al finalizar.

La exportación glTF omitía 27 triángulos pequeños (hasta 0,278 mm² por abertura)
y conservaba dos caras internas coincidentes en la sudadera del cerdito.
`wardrobe_export_seams.py` restaura únicamente índices de esas costuras pequeñas,
sin cambiar posiciones, UV, normales, piel ni imágenes. Rechaza huecos mayores de
1 mm² / 3 mm y cualquier unión múltiple restante. La auditoría estricta del
archivo real pasa en las veinte superficies: cero bordes abiertos y cero uniones
múltiples (outputs/wardrobe-topology-audit.json). Esta comprobación digital no
certifica impresión 3D. El intento previo de limpieza numérica en Blender falló
sin guardar y se retiró del generador; no repetir el remallado costoso.

`pet-runner-run.js` conserva la zancada y el ritmo originales, limitando el giro
de hombros, brazos y antebrazos alrededor de la pose de encaje. No modifica el
clip fuente ni los demás movimientos. Su prueba pasa en las cuatro mascotas:
`outputs/wardrobe-natural-run-tests.log`. La carrera real y el visor usan este
clip; las pruebas de vestuario conservan además la carrera original como exigencia.

El visor de tienda ya usa Natural_Rest por defecto en Android y web; Idle_9 se
excluye en todos los visores de mascota. Se retiraron etiquetas antiguas de
versión en mensajes de carga fallida. La página principal del visor usa revisión
wardrobe-rig-9 para cargar el nuevo movimiento.

Pendiente de entrega: pruebas JS actuales tras el cierre de exportación,
miniaturas de las cinco prendas y cinco piezas de cuello, revisión real del
movimiento nuevo, commit/push y compilación firmada en GitHub Actions.
`verify-wardrobe-apk.py` verifica versión, 96 modelos, 24 miniaturas, módulos
empaquetados y misma firma que el APK 1.1.8 anterior.

El usuario pidió detener el perfeccionamiento por hoy, conservar lo logrado y entregar
un APK de prueba aunque queden fallos. La impresión 3D se trabajará después. No
certificar acabado idéntico a la imagen ni productos listos para venta.

## Estado conservado

- 24 artículos visibles con variantes para pingüino, oso, cerdito y pollito: 96 GLB.
  La peluca sigue oculta; los GLB originales de las mascotas permanecen intactos.
- Cabeza: gorra, gorro, sombrero y boina. Cuerpo: camiseta, chaqueta, abrigo,
  vestido y sudadera. También cinco artículos de ojos, cinco de cuello y cinco de patas.
- Cuerpos y complementos del cuello usan la transferencia de pesos V2 comprobada.
  Mangas unidas al torso, bordado de corazón con separación, tejidos con volumen,
  corrección del movimiento del pecho, calzado y ocultación reversible de piel cubierta.
- Se sustituyó el salto deformante del archivo fuente por una pose suave de salto.
- Miniaturas transparentes renderizadas desde el mismo GLB equipado: 24 artículos.
  Procedencia y huellas: assets/images/products/wardrobe-thumbnails.json.
- Texturas idénticas compartidas sin reducir resolución: 96 GLB ocupan 47,04 MiB,
  más 1,82 MiB de texturas compartidas. Esto no es el peso total del APK.
- Los artículos nuevos mantienen preview_only; no activar cobros ni propiedad ficticia.

## Taller y edición

Maestros locales editables (conservados fuera de Git):

- design/blender/fitting/NIDO-patronaje-prendas.blend
- design/blender/fitting/NIDO-complementos-prendas.blend

Catálogos: assets/runner/accessory-catalog.json, blender-wardrobe-models.json y
blender-complement-models.json. Sincronización Flutter: scripts/register-blender-wardrobe.py.
La vista real usa wardrobe-final-review.html, cosmetics.js y los módulos pet-garment-rig.js,
pet-sleeve-coverage.js, pet-footwear-coverage.js y pet-runner-jump.js.

## Pruebas realizadas

- 12 pruebas JS del vestuario, geometría, rig, accesorios, cobertura y salto aprobadas;
  outputs/wardrobe-runtime-tests.log. La última máscara de mangas pasó de nuevo:
  outputs/wardrobe-sleeve-coverage-tests.log.
- 10 pruebas Flutter de inventario y habitación aprobadas:
  outputs/wardrobe-flutter-tests.log.
- 8 pruebas Python de transferencia V2 aprobadas: outputs/wardrobe-surface-tests.log.
- Revisión visual real en reposo, carrera y salto, frontal, tres cuartos y espalda.
  Capturas en outputs/wardrobe-proof/: dulce-running-50.jpg, jardin-jump-25.jpg,
  pastel-running-75.jpg y chic-jump-50.jpg. Algunas capturas preceden el último
  ajuste de máscara; no usarlas como garantía visual de todos los estados finales.

Visor de continuación:
http://127.0.0.1:58104/assets/runner/wardrobe-final-review.html
Elegir conjunto/artículo, vista, movimiento y fase; pulsar «Ver selección».

## Pendientes reales para mañana

1. Bordes angulosos o solapas en puños/hombros de oso, cerdito y pollito durante
   movimiento; el pingüino se adapta mejor. Revisar todas las prendas, sin ocultar
   partes del cuello o mandíbula para tapar un error de encaje.
2. Todavía hay diferencias de silueta y riqueza de materiales frente a la ilustración.
   Revisar cada especie y combinación; no prometer identidad exacta.
3. Validación visual en teléfono y combinaciones extremas de accesorios.

## Historial del experimento en la pausa anterior (superado)

En la pausa anterior scripts/wardrobe_gltf.py contenía una propuesta V3 de suavizado de pesos de hombro,
y blender-refresh-wardrobe-skin.py admite selección por artículo/especie. Solo se
exportó un candidato de dress_petal para cerdito, sin aprobación visual:

- outputs/wardrobe-before-shoulder-smooth/candidate_dress_petal_pig_pattern.glb
- outputs/wardrobe-before-shoulder-smooth/candidate-catalog.json

En aquel momento se restauraron el GLB y el catálogo V2. Tras la petición posterior
de continuar se comparó, activó y verificó V3 para todos los cuerpos y cuellos;
las pruebas actuales esperan V3. Los respaldos V2 permanecen en esa carpeta.

## Entrega de hoy

Versión prevista: NIDO 1.1.9+14, APK de prueba con fallos visuales conocidos.
Compilación, enlace, firma y huella se añadirán al terminar la entrega.
