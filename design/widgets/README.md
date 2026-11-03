# NIDO · Widgets 1.3.6

Referencias visuales aprobadas por el propietario el 26 de octubre de 2026.
Son propuestas generadas con image_gen, no capturas de una app instalada.
Los cinco marcos de producción son PNG con centro y exterior transparentes,
sin texto ni mascotas, en android/app/src/main/res/drawable-nodpi/widget_frame_*.png.
Las cuatro mascotas usan las ilustraciones originales quiz-*-happy-v1.webp de NIDO.

Cada marco se dibuja en nueve partes para adaptar rectángulos sin estirar sus
esquinas. Las mascotas y el contenido se dibujan por separado. El renderizado
es nativo y estático: sin WebView, GL, animación continua ni dependencias gráficas nuevas.
Se limita cada bitmap final a un máximo de 512 × 512 píxeles.

Inicio: Para ti, días juntos, próximo aniversario, frase diaria y distancia.
Bloqueo: cinco proveedores separados, compactos; notas/fotos y distancia
ocultas por defecto. Consentimiento local explícito por widget para revelarlas.
El consentimiento se revoca al limpiar la sesión o cambiar de cuenta.
La pantalla de bloqueo puede no ofrecer widgets de terceros, según Android y fabricante.
No se promete alterar el reloj, el fondo, la huella o el lanzador mostrados en las referencias.

Editor accesible desde el lápiz en Inicio y desde Ajustes → Widgets del teléfono.
En Android 12+ también se declara reconfiguración del sistema. Android 7–11 mantiene
el acceso desde NIDO; añadir manualmente desde el lanzador si no admite fijación.
La apariencia se guarda por ID de widget y se elimina al retirar ese widget.

Los valores son del perfil compartido: aniversario, días naturales y últimas
ubicaciones consentidas. El 29 de febrero se celebra el 28 en años no bisiestos.
Frase: mismo catálogo, orden por pareja y día UTC que Flutter; funciona sin red
tras configurarse. No equivale a haber completado las 1.000 frases pendientes.
La ubicación se muestra como guardada con fecha, nunca como seguimiento en vivo.
Android puede retrasar el refresco periódico de 30 minutos; fecha/zona horaria
provocan recalcular los contadores.

Pruebas y evidencias: workflow widget-native-qa.yml (Android API 24 y 35), host
nativo aislado con los archivos de producción, pruebas de privacidad, fechas,
coincidencia de frases con Dart y carga de RemoteViews en AppWidgetHost.
Los resultados se registrarán tras completarse; este documento no certifica éxito anticipado.
