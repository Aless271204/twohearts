# Guardian: encaje de calzado, 16 de octubre de 2026

Prioridad del usuario: adaptación anatómica, contacto con el tobillo y seguimiento
de la pata; no basta con mejorar la imagen aislada del producto.

## Cambios implementados

- Cinco estilos de calzado con dos zapatos independientes y vistas específicas de
  reposo, carrera, salto, deslizamiento, disparo y caída.
- Límites de las patas editables por especie y pose en `FOOT_BOUNDS`, dentro de
  `assets/runner/guardian/wardrobe.js`.
- Suela colocada debajo de la pata, no por encima; tamaño ligado a su anchura.
- Limpieza local de dedos/pezuñas originales al equipar el calzado, sin recortar
  rectángulos del cuerpo ni cambiar la mascota sin equipamiento.
- Extracción del componente de cada zapato para evitar fragmentos del compañero
  en la misma celda. Sandalias, zapatos chic y pantuflas utilizan la vista de suela
  separada en el salto porque la otra vista generada tiene pares superpuestos.
- Maestro conservado en `design/boss-rush/art-v1/footwear-poses-v1.png`.
  Atlas WebP integrado en el mismo renderizador de Guardian y su visor.

## Evidencia y límites

`scripts/render-guardian-wardrobe.mjs` genera 120 combinaciones de calzado
individual y 120 combinaciones de conjuntos con el compositor de producción.
Se inspeccionaron las cinco hojas de calzado (cuatro mascotas, seis poses) y
los conjuntos Dulce y Pastel después de la última corrección. Son renders Canvas
locales, no capturas de navegador ni pruebas de Android.

Las 23 pruebas de motor, red y catálogo pasan. No sustituyen la aprobación
visual ni una prueba final en teléfono. No se ha generado un APK nuevo aquí.

## Pendiente separado del calzado

Los maestros nuevos de gorro, sombrero y boina están guardados, pero desplazan
algunas caras y contienen fragmentos que cruzan filas. NO activar esos tres
maestros todavía. `head-fit-manifest.json` mantiene únicamente `cap_pink`, cuyo
encaje se comprobó. Los otros conservan su render anterior hasta registrar sus
celdas correctamente. No confundir existencia del archivo con encaje aprobado.

La versión 1.2.4 y su publicación siguen pendientes de cerrar la revisión visual,
la validación Android y la compilación. No entregar la 1.2.3 como si incluyera esto.


## Revisión posterior a «siguen sobre la imagen»

La solución anterior con productos aislados y transformaciones fue rechazada por
el usuario. Se sustituyó por cinco hojas completas `integrated-feet-*-v1.png`:
la pata, el tobillo y el calzado están dibujados dentro de la misma pose del animal.
`feet-fit-manifest.json` enlaza los cinco artículos con estas hojas en el juego.
El renderizador ya no coloca los productos de los atlas anteriores sobre las patas.
Se retiraron los dos atlas de zapatos aislados del paquete de la app; los maestros
anteriores se conservan en diseño como referencia.

El torso/rostro superior procede del sprite original o de la prenda equipada,
conservando cuellos y capuchas. La ropa se extrae sin los antiguos pies desnudos,
para que no vuelva a tapar la unión del tobillo nuevo. La máscara conserva
bordados y botones mediante relleno de regiones cerradas.

Errores de generación detectados y corregidos en la composición:

- Cerdito: el generador también calzó una mano en botas y sandalias. Se restaura
  el antebrazo original por pose, antes de componer la prenda correspondiente.
- Oso saltando: el generador confundió la cola con la pata izquierda. Se conserva
  la anatomía original y se traslada el contexto de tobillo/calzado a la pata real.
  La segunda generación de corrección del oso tampoco solucionó esto y NO se usa.
- El teñido se limita a componentes de material del calzado. Se excluyen los
  componentes de pelaje conectados al cuerpo.

Comprobaciones actuales:

- 24 pruebas de motor/red/catálogo pasan.
- El render Canvas produjo 120 vistas individuales del calzado y 120 de conjuntos.
- 240 comparaciones verifican que equipar y teñir los cinco estilos no repinta el
  rostro original (cuatro especies, seis poses, con y sin color personalizado).
- Inspección de las cinco hojas de calzado y de Dulce, Pastel, Cozy y Chic; se
  corrigieron la mano del cerdito, el salto del oso y un cuello de sudadera que
  había quedado recortado al separar las prendas.

Esto sigue siendo evidencia local del compositor de producción, no una prueba de
Android ni una aprobación visual del usuario. No hay APK nuevo publicado.
Los gorros/boinas/sombreros anteriores todavía pueden verse flotantes y deben
revisarse por separado; no anunciar todo el vestuario como final.
