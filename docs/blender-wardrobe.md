# Taller de prendas confeccionadas en Blender

## Estado

Se crearon veinticuatro artículos y noventa y seis variantes: cuatro de cabeza,
cinco de cuerpo, cinco de ojos, cinco de cuello y cinco de patas. Son pruebas de confección,
no productos aprobados para venta. La peluca permanece retirada.

La comparación usa los modelos reales, el mismo motor de la habitación y el rig
de cada mascota. La nueva ropa incluye atributos de pesos por vértice; se enlaza
al esqueleto de la mascota en su postura de reposo, sin modificar su GLB original.

Los patrones nuevos de cabeza permiten cambiar geometría fácilmente, pero todavía
no igualan la riqueza de las texturas Meshy. Se conservan ambas alternativas.
Los nuevos cuerpos requieren revisión de mangas, cuellos, pliegues y materiales.
Las pruebas de rig no certifican que no haya intersecciones visibles.

El estado comprobado, los fallos pendientes y el experimento de hombros que no se
activó están registrados en [wardrobe-resume-1814.md](wardrobe-resume-1814.md).
Las miniaturas del catálogo se renderizan desde los mismos GLB equipados; su
procedencia está en `assets/images/products/wardrobe-thumbnails.json`.

## Organización y edición

- `design/blender/wardrobe-patterns.json`: nombres, códigos, colores y `visible`.
  Cambiar `visible` a `false` y regenerar retira esa pieza del taller sin borrar originales.
- `design/blender/head-tailoring.json`: dimensiones de referencia de cada cráneo.
- `design/blender/fitting/NIDO-patronaje-prendas.blend`: mallas editables separadas
  en colecciones por código y especie. No modificar los maniquíes de referencia.
- `scripts/blender-build-wardrobe.py`: patrones y exportación reproducible. Las
  funciones `head_piece` y `body_piece` separan la confección de cada categoría.
- `assets/runner/blender-wardrobe-models.json`: catálogo generado de previsualización.
  No editar este archivo como fuente; se reconstruye desde el catálogo de patrones.
- `assets/runner/accessories/CODIGO_ESPECIE_pattern.glb`: pieza exportada.
- `assets/runner/wardrobe-review.html`: comparación anterior/nueva; permite elegir
  artículo, especie, ángulo y animación.

Los códigos conservan la identidad de inventario. No hay cambios de precios,
propiedad, cobros ni registros de cuentas. La producción conserva las piezas previas
hasta que se compruebe que una sustitución mejora su acabado.

## Reconstrucción

1. Ejecutar `scripts/prepare-blender-fitting.mjs` para actualizar referencias.
2. Ejecutar Blender con `scripts/blender-build-wardrobe.py`.
3. Ejecutar `test/blender_wardrobe_test.mjs` y las pruebas de accesorios anteriores.
4. Abrir `assets/runner/wardrobe-review.html` y revisar visualmente.

Para conservar ediciones manuales: guardar el `.blend` y ejecutar Blender con ese
archivo, `scripts/blender-export-wardrobe.py` y los argumentos `ITEM SPECIES`.
Se exporta solo esa colección, se recalculan sus pesos y se actualiza su huella en
el catálogo. No vuelve a generar ni descarta las demás prendas. Por ejemplo,
`shirt_love penguin` exporta la camiseta del pingüino.

Para actualizar únicamente los pesos después de cambiar su algoritmo, ejecutar
`scripts/blender-refresh-wardrobe-skin.py` con Blender. Conserva geometría y
materiales, recalcula las huellas del catálogo y reutiliza los bloques de atributos
existentes para que repetirlo no aumente el tamaño del archivo.

Los pesos se derivan de las superficies cercanas del personaje y necesitan revisión
artística adicional en zonas sensibles. Un cambio manual en el `.blend` no se
preserva si se vuelve a ejecutar el generador: guardarlo en otra copia antes de
regenerar y exportar/registrar esa variante de forma explícita.

El defecto previo del cuerpo del pingüino en Running sigue pendiente. No certificar
el conjunto completo en carrera por el hecho de que sus prendas sigan el rig.

## Acabados textiles

Cada artículo declara `fabric` en `wardrobe-patterns.json`: cotton, denim, wool,
knit, poplin, straw o felt. `scripts/wardrobe_materials.py` contiene la trama,
rugosidad y fuerza del relieve. Las texturas PNG se generan en
`design/blender/fabrics`, se empaquetan en el `.blend` y quedan embebidas en cada
GLB; funcionan en el visor real sin depender de nodos exclusivos de Blender.
Hay pespuntes en cuello y dobladillo, bordados, bolsillos y un lazo en el vestido.
Los motivos son deliberadamente discretos para conservar la estética delicada.

## Ajuste por especie y volumen

`species_fit` en el catálogo de patrones controla la altura de las copas,
la altura de la boina y la holgura del cuerpo por especie. `padding` por artículo
 añade el volumen de prendas gruesas como abrigo y sudadera. En oso, cerdito y
pollito las mangas son paneles completos, redondeados y medidos sobre las secciones
de sus brazos; así no heredan los huecos del recorte de triángulos de piel. En el
pingüino se conserva el patrón de sus alas, suavizado y colocado fuera de la piel.
El abrigo incluye pequeños bucles de borreguito y el gorro
un pompón más voluminoso, sin sistemas de partículas.

Los pesos mezclan seis puntos cercanos en lugar de copiar un único vértice.
El torso, bordados y bolsillos reciben influencias de cadera y columna; en los
cuello se conserva además la mezcla gradual de cabeza/cuello de la piel del torso
del personaje, sin un corte brusco por altura, para que su pecho no atraviese la
tela en carrera. Las mangas y
puños usan las del brazo. Las pruebas verifican esa separación, el encaje en
reposo y la transformación durante carrera y salto en las cuatro mascotas.
La revisión visual sigue siendo necesaria: las pruebas numéricas no certifican
por sí solas la ausencia de todos los cruces durante cualquier animación.
