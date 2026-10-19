# NIDO 1.3.1+26 — entrega Android corregida

Incluye el lote de 1.3.0 documentado en release-130.md. Además corrige el servidor
local de recursos de Android: los juegos HTML ahora pueden cargar las imágenes
estáticas de assets/images/ui y los audios de assets/sounds, con lista de rutas
y extensiones permitidas. Las rutas ajenas a los juegos, archivos de configuración
y recorridos con separadores o «..» permanecen rechazados.

La comprobación de empaquetado anterior confirmaba que los archivos existían,
pero no detectaba su rechazo por el servidor local de Android. Se añadieron
pruebas de esas rutas y una comprobación real de imagen WebP y audio MP3 en el
WebView Android. Cinco pruebas locales de rutas/rangos pasan. La comprobación
del título se actualizó a Senderos del Nido; el primer fallo de 1.3.0 era una
expectativa antigua de ese nombre, no un fallo de carga del bosque.

1.3.0 se retiró a borrador para evitar entregar esa versión. Fuente corregida:
4f69d7292424585ca19e66a2474a13cca685f195. Compilación:39190126840. Registrar al
terminar firma, huella, tamaño y resultados de Android/publicación.

El usuario confirma que mañana se configurarán los cobros y se publicará en
Google Play. No se han activado cobros reales ni publicado en Play hoy. Para
el AAB de Play usar un versionCode superior a2026 (el APK64 usa el desplazamiento
de2000 de Flutter), y conservar/planificar la identidad de firma al activar
Play App Signing. No entregar simplemente un AAB con código26 a quienes ya
instalaron los APK de64bits.

Social por ID y ajustes artísticos completos de vestuario siguen documentados
como alcance previo pendiente; no afirmar que esos trabajos se completaron.
