# Nuestro Nido: fondo y geografía real

La navegación Social → Tienda → Nido → Mascota → Actividades se conserva.

## Wallpaper
Asset: `assets/images/ui/nido-wallpaper.png`. Generado con la herramienta integrada ImageGen; sin texto ni elementos de interfaz incrustados.

Prompt: Create one wide landscape wallpaper image for a premium romantic couples mobile app TwoHearts. Warm welcoming safe haven: dreamy refined peach pink sunrise over a peaceful lake, misty distant rolling hills in muted sage, soft blush clouds, subtle glowing golden sunlight, delicate small white blossoms and sage foliage framing only the outer bottom corners. Elegant airy aesthetic, comforting chic editorial illustration with gentle painterly 3D depth, no characters, no text, no letters, no UI, no hearts in center. Very low visual contrast and large uncluttered pale cream-pink sky center area (top 70%) for dark burgundy quote text overlay. Wide horizontal 3:2 composition, beautiful but restrained, never saturated neon. This is a decorative background only, not a geographical map.

## Mapa
Flutter Map muestra cartografía de OpenStreetMap con atribución y marcadores geográficos. Photon resuelve nombres de ciudad/dirección a coordenadas; el selector permite confirmar el resultado y el perfil guarda su etiqueta en el campo city existente. Las coordenadas seleccionadas se conservan en la caché local. No hay migraciones del servidor. No se inventa una posición para lugares no encontrados. Las búsquedas se espacian un segundo y las peticiones tienen un tiempo máximo de 12 segundos. El mapa y nuevas búsquedas requieren internet. El GPS solo se solicita al activar la opción correspondiente.

El mapa no es una imagen generada: el wallpaper solo decora el entorno de la tarjeta. No se precargan regiones para uso offline. Para mayor escala, configurar un proveedor geocodificador y de tiles con capacidad y condiciones acordes a la publicación.

## Entrega
Cambios locales y previsualización web. No se genera ni publica APK por indicación del usuario.
