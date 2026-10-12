# Prendas según la referencia aprobada

La lámina `penguin-outfits-approved.png` es el objetivo visual. Las mallas actuales del catálogo no se certifican por coincidir en nombre o color con esa imagen. La referencia es un render generado, no contiene geometría, UV ni pesos de un esqueleto.

## Archivos que necesitamos

Cada pieza por separado en GLB, con sus texturas incluidas: color, normal y rugosidad. Mantener el detalle de las costuras, tejido, bordados y herrajes de la referencia. Los detalles pequeños de tejido deben ir en texturas para no aumentar innecesariamente las caras. Entregar también el archivo editable de modelado cuando esté disponible.

Para accesorios rígidos, origen deliberado y unidades consistentes. Para ropa del cuerpo, cuello y mangas con aberturas reales, sin partes del personaje dentro del archivo de la prenda. La chaqueta debe tener abertura frontal, solapas y bolsillos; el abrigo ribetes mullidos; el vestido capas y volantes; la sudadera capucha y bolsillo; la camiseta cuello y mangas cortas, con corazón sobre el tejido.

Una generación en Meshy es una base de modelado, no una garantía de que la prenda encaje. El acabado aceptado requiere comparar el modelo cargado en el motor, no solo el render de la plataforma.

## Mascotas a conservar

Usar el esqueleto real de los GLB de `assets/runner/play-models/`: `Meshy_AI_Pip_the_Penguin_All_Animations.glb`, `bear.glb`, `pig.glb`, `chick.glb`. La variante de habitación del pingüino aplica `pip-delicate.js`; su contorno también debe tenerse en cuenta al ajustar las prendas. No sustituir ni deformar al personaje para forzarlo dentro de la ropa.

La prenda del torso debe adaptarse y ponderarse por especie para seguir los huesos reales durante las animaciones. Una prenda rígida escalada al tamaño de la caja del torso no cumple este requisito. Los demás accesorios usan anclajes de cabeza, cuello y pie, con ajustes por especie y validación de combinaciones completas.

## Integración y validación

Reemplazar cada archivo referenciado en `accessory-catalog.json` conservando el identificador de artículo y su estado de propiedad. El catálogo continúa siendo editable y conserva `visible` y `preview_only`. No convertir un artículo en vendible por recibir el archivo: primero validar los criterios de `approved-outfits.json`.

La fotografía de producto debe renderizar el mismo GLB, materiales y versión que se equipa. Revisar desde varios ángulos las cuatro especies, en reposo, carrera, salto y con varios accesorios simultáneos. Los tests de carga y límites finitos no demuestran ausencia de intersecciones ni semejanza con el render aprobado.

La impresión física queda fuera de esta entrega y requerirá posteriormente escala, espesor, cierre de mallas y revisión específica para fabricación. Un GLB de juego no se declara imprimible automáticamente.
