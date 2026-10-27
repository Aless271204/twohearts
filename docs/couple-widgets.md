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

## Incidencia de empaquetado

El workflow 40412572537 se canceló por superar 45 minutos antes de crear el AAB.
Las pruebas Flutter y nativas de esa revisión sí pasaron. No se subió un archivo
ni se envió esa compilación a Google Play. El borrador Alpha 3 conserva las notas.
Se fija Ubuntu 24.04 y Flutter 3.47.6, se reduce el máximo de memoria de Gradle,
se desactiva el vigilante de archivos que registró una excepción y se prepara/cachea
el NDK antes de empaquetar. compileSdk 37 atiende el requisito del complemento
de permisos; targetSdk sigue en 36 y minSdk en 24. La nueva ejecución debe confirmar
si estas medidas resuelven la cancelación; no se certifica el resultado antes de terminar.

La comprobación posterior confirmó que sdkmanager no encuentra platforms;android-37
(workflow 40423612990). Se conserva compileSdk/targetSdk 36 y se fija
permission_handler 12.0.1 (implementación Android 13.x), con la API de notificaciones
que usa NIDO. Se mantiene pubspec.lock para resolver la misma combinación en CI.

La revisión 1ff6d57 pasó las pruebas nativas completas en API24 y API35
(workflow 40424472067), incluidos los cinco diseños en tamaño mínimo.
El empaquetado 40424472011 avanzó hasta compilar Java y falló por una referencia
al complemento integration_test dentro del registro generado de publicación.
La preparación de CI retira solo esa dependencia SDK de pruebas en su copia
desechable, después de ejecutar los tests; se conserva en el repositorio.
La compilación final debe confirmarse antes de considerar enviada la actualización.

## Candidato verificado 1.3.6 / 2034

El workflow 40441836952 terminó correctamente, fuente
492576a72b3c2a29c4ef35f9cc78178d1c75942e. El archivo firmado pesa
283.276.728 bytes y su SHA-256 es
c459225090d47e50635734d1d5388f503185661b7a768d39cc8b0ae32fd6beb9.
Se comprobó con jarsigner, el certificado de subida existente, los diez proveedores,
el catálogo nativo de 59 frases, 62 recursos de juegos y alineación ELF de 16 KB.
La descarga local coincide con ese hash y certificado.
Las pruebas nativas API24 y API35 volvieron a pasar en 40441836964.
Estas pruebas no sustituyen la comprobación en los teléfonos de los testers ni
garantizan widgets de bloqueo en fabricantes que no los admiten.

## Envío a Google Play

El 26 de octubre de 2026 se subió y aceptó el AAB 2034 (1.3.6), minSdk24,
targetSdk36. Console no registró dispositivos perdidos respecto a 2033.
Se guardaron las notas es-419 y se envió el único cambio del canal cerrado Alpha,
«1.3.6 · Widgets para nuestro Nido», con lanzamiento del 100 % del canal existente.
Tras completar las comprobaciones rápidas, una recarga independiente confirmó:
«Cambios en revisión» y «Tus cambios están en proceso de revisión».
Publicación gestionada desactivada: la disponibilidad queda sujeta a aprobación
de Google; no se certifica que los testers ya puedan descargarla.
Evidencia local: outputs/play-136/google-play-136-in-review.png.

No se modificaron listas de testers, productos, cuentas de pagos ni el banco.
La comprobación en teléfonos físicos y la disponibilidad de la familia de bloqueo
según fabricante siguen siendo validaciones posteriores a la distribución.
