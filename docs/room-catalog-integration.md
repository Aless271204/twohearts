# Nuestro rincón: integración visual

La colección aprobada contiene veinte conceptos: cinco de techo, cinco de pared, cinco de suelo y cinco muebles. `lib/core/room_catalog.dart` es el catálogo editable; los identificadores y referencias de imagen no dependen del orden de la lista.

La lámina aprobada está en `design/room-catalog/catalogo-habitacion-v1.png`. Se generó una versión de sus mismas piezas con fondo transparente para colocarlas en la habitación: `assets/images/ui/room-catalog-atlas.png`. Es una integración visual en capas 2D, junto a la mascota 3D existente; no se presenta como veinte modelos 3D nuevos. El recurso compartido pesa aproximadamente 1,8 MB y se decodifica una vez por sesión.

`RoomCatalogArt` comparte recortes entre tienda y habitación. Las piezas mantienen su proporción incluso cuando cambia el tamaño de la escena. Paredes y suelos usan sus texturas en la superficie; las piezas decorativas utilizan anclajes que dejan libre el centro para la mascota. Las opciones anteriores permanecen disponibles después de la colección nueva.

La tienda permite combinar pruebas temporales y volver a la ventana Mascota para verlas. Restaurar elimina únicamente esta prueba local. No se publicaron precios, compras, propiedad ni sincronización de los artículos nuevos con la pareja. Los artículos ya publicados conservan su estado del servidor.

Se verificaron categorías, identificadores únicos, recortes sin elementos vecinos, carga del atlas, posiciones sin invadir el cuerpo de la mascota y compatibilidad del inventario. La previsualización web se compiló y se probó el recorrido tienda → prueba → ventana Mascota. No se generó APK ni se aplicó una migración de catálogo.

Para añadir imágenes propias o localizar los módulos de toda la app, consultar `docs/GUIA_DE_EDICION.md`.
