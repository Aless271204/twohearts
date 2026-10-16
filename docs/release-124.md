# NIDO 1.2.4+19 — candidata Android

## Alcance
Guardianes del Alba disponible desde Juegos: solitario y pareja online por codigo
de sala en dos celulares. Conserva compras, mascotas adoptadas y equipo validado
del inventario. Integra las hojas nuevas de vestuario pixel art, dificultad5/3/1,
dos distribuciones tactiles y escena/audio de derrota. Logo nuevo en Android y
acceso de NIDO. La habitacion y el resto de la app conservan la base1.2.3.

La aplicacion sigue siendo una prueba distribuida mediante APK. No habilita cobros
reales ni sustituye una revision de las tiendas. El vestuario utiliza seis poses
por mascota y conserva limites de acabado documentados en la nota visual.

## Validacion antes de compilar
-24 pruebas del motor, sincronizacion, reglas y catalogo pasan.
-240 comparaciones del rostro al equipar/tenir calzado y240 vistas de vestuario
 generadas con el compositor de produccion. Son renders locales, no capturasAndroid.
-Prueba real con dos cuentas: canales privados, controles cruzados, equipo del
 inventario, especie bloqueada rechazada y tercero no autorizado rechazado.
-Victoria cooperativa real validada por servidor: ambos reciben oro una sola vez;
 reintento idempotente y rechazo de invitado/replay falsificado.
-Analisis de Flutter sin errores;143 avisos informativos/advertencias existentes.
-CI debe compilar web/APK, pasar pruebas y humoAndroid antes de publicar. Este
 documento no declara un APK final mientras esas tareas no hayan acabado.

## Datos de entrega
Version1.2.4+19, paquete com.example.twohearts, mismo certificado que1.2.3.
Enlace previsto (validar existencia antes de comunicar):
https://github.com/Aless271204/twohearts/releases/download/nido-1.2.4/NIDO-1.2.4-ligera.apk
Firma y contenido se verifican despues de descargar el APK de CI.
