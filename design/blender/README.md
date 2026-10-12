# Taller 3D de NIDO

Blender 4.5.9 LTS oficial, instalación portátil en `%LOCALAPPDATA%\NidoTools\blender-4.5.9-windows-x64`.
No necesita un plugin ni una cuenta. Codex puede ejecutar Blender mediante sus scripts Python.

Abre `NIDO-biblioteca.blend` con Blender o ejecuta `scripts/open-blender.ps1`.
Las colecciones del archivo separan:

- 4 mascotas, con sus esqueletos, materiales y clips importados.
- 5 accesorios de cabeza Meshy originales, con sus códigos de inventario.
- 25 prendas del catálogo previo, separadas para compararlas y sustituirlas.
- 20 objetos de habitación, generados desde la misma geometría usada en la app.
- La arquitectura base de la habitación.
- 11 modelos del paisaje.

Las colecciones grandes empiezan desactivadas en el Outliner para reducir el trabajo de la vista.
Actívalas con la casilla correspondiente. Los archivos GLB originales no se editan al importar.
Las texturas se empaquetan dentro del `.blend`.

## Trabajo y publicación

Esta biblioteca prepara el modelado; importar no significa aprobar el encaje.
Guarda tus modificaciones en otra copia del `.blend`. La app sigue utilizando su catálogo actual.
El pingüino importado es el GLB original; los retoques que aplica `pip-delicate.js` en la app
todavía no están trasladados al modelo editable. No sustituirlo directamente con esta importación.

`scripts/blender-export.py -- --item CODIGO` exporta la colección elegida a
`design/blender/exports/`, con un registro de procedencia y aprobación. Se ejecuta con Blender
y el archivo editado abierto, mediante `--background --python`. Nunca sobrescribe `assets/`
ni una exportación existente. Conserva el eje Y vertical al exportar a GLB.

Antes de incorporar un archivo a la app hay que revisar dimensiones, UV, materiales,
frontal, perfil, espalda, accesorios, carrera y salto. La miniatura debe salir de ese mismo modelo.

## Reconstrucción de la base

1. Ejecutar `scripts/prepare-blender-library.mjs` con Node para actualizar el manifiesto desde los catálogos.
2. Ejecutar Blender con `--background --factory-startup --python scripts/blender-project.py`.

El constructor se detiene si ya existe `NIDO-biblioteca.blend`, para proteger el trabajo manual.
El manifiesto, las exportaciones y los `.blend` son archivos locales; no se suben a Git por defecto.
