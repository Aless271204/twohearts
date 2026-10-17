# Catálogo de Pincel en pareja

60 referencias activas: 20 fáciles, 20 medias y 20 difíciles. Cada nivel contiene exactamente 5 imágenes con mascotas y 15 de vehículos, paisajes, edificios u objetos. Otras cuatro imágenes con mascotas permanecen desactivadas como reserva.

- Fácil: formas grandes y uno o dos elementos sobre blanco.
- Medio: fondo mayormente blanco y pocos objetos. Se conservan las primeras referencias aprobadas.
- Difícil: fondo reconocible, objetos cercanos y una composición con contexto, siguiendo el pingüino en París. La pintura detallada de Kioto fue sustituida por una versión de dibujo sencilla.

La pantalla carga una bolsa aleatoria por nivel, persistida en el teléfono. Una referencia no vuelve a salir hasta agotar ese nivel; al remezclar tampoco repite inmediatamente la última. «Otra ronda» obtiene una imagen nueva. La selección del anfitrión se convierte en el mismo PNG privado para ambos jugadores usando el protocolo existente; el invitado no selecciona otra referencia. Cambiar de dispositivo o de anfitrión utiliza la bolsa local de ese teléfono.

Los dibujos nuevos conservan su composición y colores; el nivel no se simula degradando su calidad. Fotos propias y estilos experimentales siguen siendo una opción manual independiente.

## Agregar, ocultar o cambiar títulos

El catálogo que consume la app es assets/images/art_references/mobile/catalog.json. Cada entrada tiene id, level, title, asset, enabled y category. enabled=false oculta una imagen del sorteo. category=mascots distingue las imágenes con las mascotas de NIDO.

Los maestros PNG están en design/art-references/mobile-masters, fuera del paquete de la app. Cada archivo JSON en design/art-references/mobile-items conserva origen, tema, prompt cuando está disponible y categoría. Para que un cambio sobreviva a la regeneración, editar ese JSON y ejecutar scripts/prepare-mobile-art-catalog.py. Para cambiar una imagen se recomienda un id nuevo y desactivar la anterior. Las nuevas entradas se incorporan sin cambiar el código del sorteo. Revisar el reparto 20/5 cuando se amplíe el catálogo.

scripts/review-mobile-art-catalog.py comprueba cantidades, categorías, dimensiones y genera hojas de revisión de los recursos reales. El catálogo comprimido completo ocupa aproximadamente 3,3 MB, incluidos los cuatro de reserva. No incluye los PNG maestros.

## Portadas

Pincel usa una ilustración nueva en WebP. Guardianes utiliza una escena del renderizador real de su juego pixel art, con una mascota disparando; los otros tres conservan su familia artística. Las cinco tarjetas tienen la misma altura y ancho. Las cinco portadas tienen un movimiento suave que se desactiva con la preferencia de reducir movimiento. Se conserva la proporción de los personajes al encuadrar las tarjetas.

Estos cambios están incorporados en el proyecto. El APK 1.2.7 publicado anteriormente no los incluye; necesitan una compilación posterior.

## Verificación

- 60 entradas activas, 20 por nivel y exactamente 5 de mascotas por nivel; 4 en reserva.
- Las 64 imágenes empaquetadas son cuadradas de 768 px y suman 3.270.832 bytes.
- 13 pruebas de catálogo, sorteo persistente, capas de dibujo, referencias y navegación pasaron; una prueba adicional del menú comprueba las cinco portadas al desplazarse en 390 × 844 y pasó.
- Análisis final del catálogo y las portadas sin incidencias. El archivo existente de la pantalla de dibujo mantiene avisos de estilo, sin errores de compilación en el análisis inicial.
- Hojas reales de los tres niveles, capturas del menú y galería HTML en outputs/art-catalog-review. Son capturas del renderizador Flutter, no de un teléfono físico.
- No se ha publicado un APK nuevo en esta tarea ni modificado la base de datos.
