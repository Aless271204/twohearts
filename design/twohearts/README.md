# TwoHearts · Especificación de diseño

Ocho pantallas independientes de 390 × 844. index.html es un prototipo visual navegable local; screen-01.svg a screen-08.svg conservan textos, tarjetas, botones y formas vectoriales editables. Las imágenes son los únicos elementos rasterizados. No es un archivo Figma nativo y no incluye Auto Layout o componentes nativos de Figma. Los SVG se pueden importar en Figma; allí hay que crear los componentes y restricciones. El prototipo usa la mascota aprobada del proyecto, sin nombre asignado.

## Sistema reutilizable
Header, PrimaryButton, SoftButton, SegmentedControl, ContentCard, FeatureCard, ListRow, PetStage, BottomNavigation. Tokens en tokens.json. Navegación constante: Nido, Tienda, Mascota, Actividades, Social. Álbum y Viajes dependen de Nido; Juegos depende de Actividades. La navegación debe ocultarse en la partida y en los editores inmersivos, como ya se implementó en la app. No hay botones flotantes de música.

## Interacciones y estados
La navegación y el selector cambian de pantalla. Los segmentos cambian estado activo. La ruleta entrega una propuesta de ejemplo. Los demás botones indican su acción de diseño, no ejecutan compras, publicaciones o viajes. Hover, pressed y focus están presentes; en producción añadir loading con spinner y etiqueta, disabled con explicación y error cerca del campo. No mostrar éxito antes de confirmar la operación. Los datos de pareja, fechas, conteos, contenido social y planes son ejemplos; los precios siguen por definir.

## Adaptación a desarrollo
Usar Column/Row/Flex y listas desplazables en Flutter, no coordenadas absolutas del SVG. SafeArea superior e inferior; objetivos táctiles de 44 pt iOS / 48 dp Android. En 320 px reducir la cantidad de columnas, nunca comprimir textos. Las tarjetas pueden crecer con accesibilidad y escalado de texto. Inter como opción; SF Pro / Roboto como alternativa nativa. El coral de marca se conserva para superficies y decoración; validar contraste WCAG AA para cada texto y usar un coral oscuro en etiquetas pequeñas sobre blanco cuando sea necesario. Fotografías del álbum deben sustituirse por las del usuario, no por escenarios de muestra. El mapa mostrado es una composición de diseño, no un mapa conectado a ubicación real.

## Alcance
Este paquete diseña la interfaz. No modifica todavía el APK, no añade modos de juego nuevos y no afirma que las acciones de ejemplo estén conectadas a Supabase. Requiere traslado y revisión visual en las pantallas reales de Flutter antes de publicar otra versión.
