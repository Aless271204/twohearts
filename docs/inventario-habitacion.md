# Inventario de la habitación

Catálogo implementado: 24 objetos, seis categorías y cuatro colecciones. Los valores actuales son LoveCoins, no dinero real. Los precios se validan en el servidor.

| Objeto | Categoría | Colección | LoveCoins | Identificador |
| --- | --- | --- | ---: | --- |
| Pared · Bosque | room_wall | Bosque | 80 | room_wall_forest |
| Suelo · Bosque | room_floor | Bosque | 70 | room_floor_forest |
| Cama · Bosque | room_bed | Bosque | 110 | room_bed_forest |
| Planta · Bosque | room_plant | Bosque | 55 | room_plant_forest |
| Lámpara · Bosque | room_lamp | Bosque | 65 | room_lamp_forest |
| Cuadro · Bosque | room_decor | Bosque | 50 | room_decor_forest |
| Pared · Rosa suave | room_wall | Dulce | 80 | room_wall_rose |
| Suelo · Rosa suave | room_floor | Dulce | 70 | room_floor_rose |
| Cama · Rosa suave | room_bed | Dulce | 110 | room_bed_rose |
| Planta · Rosa suave | room_plant | Dulce | 55 | room_plant_rose |
| Lámpara · Rosa suave | room_lamp | Dulce | 65 | room_lamp_rose |
| Cuadro · Rosa suave | room_decor | Dulce | 50 | room_decor_rose |
| Pared · Noche estrellada | room_wall | Noche | 120 | room_wall_night |
| Suelo · Noche estrellada | room_floor | Noche | 110 | room_floor_night |
| Cama · Noche estrellada | room_bed | Noche | 150 | room_bed_night |
| Planta · Noche estrellada | room_plant | Noche | 95 | room_plant_night |
| Lámpara · Noche estrellada | room_lamp | Noche | 105 | room_lamp_night |
| Cuadro · Noche estrellada | room_decor | Noche | 90 | room_decor_night |
| Pared · Miel | room_wall | Dorado | 80 | room_wall_honey |
| Suelo · Miel | room_floor | Dorado | 70 | room_floor_honey |
| Cama · Miel | room_bed | Dorado | 110 | room_bed_honey |
| Planta · Miel | room_plant | Dorado | 55 | room_plant_honey |
| Lámpara · Miel | room_lamp | Dorado | 65 | room_lamp_honey |
| Cuadro · Miel | room_decor | Dorado | 50 | room_decor_honey |

## Personalización

Decorar abre directamente el catálogo de la habitación. Se puede filtrar por categoría, buscar una colección, consultar los objetos propios y probar un artículo visualmente antes de comprarlo. La vista previa no guarda ni cobra. Comprar y colocar son acciones separadas; quitar o cambiar un objeto no cuesta monedas.

Un objeto por categoría. Pared y suelo definen el ambiente; cama en el lado izquierdo, planta junto a la ventana, lámpara a la derecha y cuadro en la pared. El centro queda reservado para la mascota fija. Equipar otro objeto de la misma categoría sustituye al anterior sin perderlo del inventario.

Las colecciones son Bosque, Dulce, Noche y Dorado. Se pueden mezclar libremente. La colección Noche cambia el cielo de la ventana. El ambiente inicial incluye pared, suelo, ventana y alfombra visual de base.

## Siguiente ampliación de catálogo

Sofás, mesas, estanterías, juguetes, alfombras intercambiables, ventanas y fondos panorámicos requieren nuevas categorías del catálogo del servidor y recursos visuales. No se anuncian como objetos comprables hasta integrar y validar esos cambios. Los combos con dinero real siguen pendientes de facturación y verificación de compras.

## Validación pendiente

Comprobar en Flutter/Android la composición con las cuatro mascotas, distintas relaciones de pantalla y cada combinación. Esta estación no dispone del SDK de Flutter; no se ha generado un APK de estos cambios.
