# Cinco accesorios Meshy: adaptación a mascotas

## Previsualizaciones

- Galería de las 20 combinaciones: http://127.0.0.1:58104/assets/runner/head-fit-review.html
- Modelo individual con perfil, posterior, carrera y salto: http://127.0.0.1:58104/assets/runner/accessory-review.html?meshy=1

## Archivos editables

Los GLB originales se conservan sin cambios y sus hashes se comprueban en los tests. head-fit-profiles.json contiene posición, inclinación y escala de cada accesorio por especie. scripts/import-head-models.py reproduce head-models.json y define los acabados y modificaciones de geometría. No editar el catálogo generado para cambios permanentes: editar el importador y los perfiles y volver a ejecutarlo.

head-conform.js modifica exclusivamente copias de las mallas de accesorios. Corrige altura de copa, longitud y curvatura de visera, profundidad del pelo y contacto con la superficie real de la cabeza en reposo. El contacto está limitado a 0,045 unidades y se desvanece suavemente al salir del borde. Los accesorios siguen el hueso Head; no se altera el rig de la mascota ni se modifica el archivo fuente.

La superficie de contacto se muestrea en una cuadrícula con interpolación continua y reutiliza las muestras dentro del ajuste. La peluca conserva libres sus puntas; no se proyectan contra el cráneo. La galería permite revisar frontal, tres cuartos, perfil y posterior, conservando el tamaño del cuerpo al cambiar de prenda.

accessory-subdivision.js suaviza boina y peluca con una pasada Loop. Suelda la topología geométrica, conservando los vértices separados de las costuras UV. Las texturas de color se conservan, el relieve se suaviza y se utiliza acabado de tela sin brillo metálico. La peluca incorpora una base interior de geometría 3D que toma su textura del pelo importado.

## Presupuesto geométrico

| Pieza | Original | Versión visual aproximada |
|---|---:|---:|
| Gorra corazón | 4.089 | 4.089 |
| Sombrero jardín | 4.054 | 4.054 |
| Gorro nube | 3.657 | 3.657 |
| Boina chic | 4.103 | 16.412 |
| Peluca pastel | 3.177 | 13.444, incluida la base interior |

Las texturas se cargan y liberan por pieza durante la fotografía. La galería renderiza secuencialmente con un solo contexto WebGL y conserva únicamente las imágenes resultantes, con enlaces al visor 3D interactivo.

## Estado

Revisión visual, no aprobación comercial. La imagen de concepto tiene diferencias de silueta, detalles y materiales respecto a los GLB suministrados; la adaptación actual no debe describirse como idéntica. La galería permite comparar los cinco modelos sobre las cuatro especies sin ocultar diferencias. Los tests comprueban conservación de fuentes, UV y topología finitas, seguimiento durante carrera/salto y crecimiento. No sustituyen una revisión visual de intersecciones. El catálogo principal de la tienda y los pagos no se han cambiado ni se ha generado un APK.

Última validación: 9 tests pasan, incluyendo los 20 pares importados, carrera, salto y crecimiento. Duración local de la suite tras optimizar el contacto: 15,05 segundos, frente a 125,90 segundos en la ejecución anterior. Son medidas de pruebas locales, no de FPS del dispositivo.
