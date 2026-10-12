# Gorra corazón: derivado ajustado

**Estado actual:** el usuario rechazó el cambio de forma. Este derivado es un experimento archivado; la vista activa utiliza nuevamente `cap_pink_meshy.glb`, sin editar su malla ni texturas y con escala uniforme. No ejecutar `fit-meshy-cap.py` para actualizar la vista activa. `import-head-models.py` importa los cinco originales con sus ajustes por especie.

El original `assets/runner/accessories/cap_pink_meshy.glb` se conserva intacto. El derivado `cap_pink_fitted.glb` mantiene sus 4.089 triángulos, materiales, imágenes y UV; reduce la altura de la copa y la longitud de la visera y recalcula las normales.

Ejecutar `scripts/fit-meshy-cap.py` para reproducir el derivado y actualizar el registro de revisión. Los ajustes individuales se editan en `assets/runner/head-fit-profiles.json`; el script los incorpora a `head-models.json`. Ejecutar el importador de originales restaura el registro, por lo que después debe ejecutarse nuevamente este script.

La vista `assets/runner/accessory-review.html?meshy=1` usa el derivado. Cada instancia en oso y cerdito recibe aberturas para las orejas antes de unirse al hueso Head. Se interpolan las coordenadas UV en el borde; no se modifica la mascota ni el GLB original.

Verificado visualmente en tres cuartos y de perfil sobre las cuatro mascotas. Siete pruebas pasan, incluidas conservación del original, dimensiones del derivado, interpolación de aberturas y regresiones del sistema de accesorios. La animación completa de este derivado y el APK todavía no se han verificado. El catálogo principal de compras permanece separado de esta revisión.
