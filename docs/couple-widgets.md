# Widgets Android · NIDO 1.3.6

Hay dos familias independientes: **Inicio** y **Bloqueo**, con cinco tipos en cada una:
Para ti (foto, nota o dibujo), días juntos, próximo aniversario, frase diaria y distancia.
Los proveedores originales se conservan para actualizar los widgets ya instalados.

## Personalizar en cualquier momento

Ajustes → Widgets del teléfono enumera los widgets instalados y permite abrir su editor.
En Inicio también se puede tocar el lápiz; Android 12+ ofrece la opción de reconfigurar
según el lanzador. Se guardan por separado color/colección del marco, detalles y cero,
una o dos mascotas. Al eliminar el widget se eliminan sus preferencias locales.
La apariencia no modifica las mascotas adoptadas ni las compras del nido compartido.

## Datos de la pareja

Se usan las fechas reales del perfil y sus últimas ubicaciones consentidas. Sin datos
se invita a configurar, nunca se inventa cero distancia ni un aniversario. El contador
usa días naturales locales; el próximo aniversario es anual y no anterior al primero.
El 29 de febrero se celebra el 28 en años no bisiestos. La frase coincide con Flutter
mediante miembros ordenados y día UTC; el catálogo se incluye para funcionar sin red.

## Privacidad en bloqueo

Los cinco proveedores de bloqueo son distintos a los de Inicio. No muestran notas,
fotos ni distancia por defecto, aunque la pantalla estuviera desbloqueada al generarse
el bitmap. Revelar estos contenidos exige activarlo expresamente en el editor del widget.
Cerrar sesión o limpiar los datos de la pareja revoca ese permiso y borra la caché privada.
Tocar el contenido abre NIDO y deja al sistema pedir el desbloqueo; no se usa showWhenLocked.

## Compatibilidad y actualización

Base Android 7/API24, igual que la app. RemoteViews, imágenes estáticas y tipografía del
sistema; sin WebView, GL ni animaciones continuas. Imágenes de hasta 512×512 por widget.
Marcos ilustrados en nueve partes y mascotas separadas para adaptarse a rectángulos.
Android puede retrasar la actualización periódica de 30 minutos. La app actualiza
cuando está activa; cambios de fecha/hora/zona recalculan las tarjetas.
La posición mostrada se identifica siempre como **ubicación guardada** con fecha.

No todos los fabricantes/versiones admiten widgets de terceros en bloqueo. NIDO los
ofrece mediante la categoría keyguard; no puede forzar su aparición, alterar el reloj,
fondo, huella o distribución del sistema. En teléfonos sin fijación programática,
los widgets de Inicio se añaden desde el selector de Android.

## Evidencia

Primera revisión cb12adf: siete pruebas Flutter aprobadas y workflow nativo 40411100018
aprobado en API24 y API35. Incluye tres pruebas instrumentadas por versión (privacidad,
frases frente a Dart y carga real en AppWidgetHost), más pruebas unitarias de fechas.
Capturas de renderizado nativo en outputs/widget-native; no son fotos de teléfonos de testers.
La revisión posterior ajusta el primer aniversario, el encabezado y las mascotas y
requiere su propia ejecución antes de distribuir el AAB.
