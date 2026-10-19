# NIDO 1.3.0+25 — lote Android solicitado

Cambios preparados: acceso directo a Juegos, sin la antigua pestaña interna de
Actividades/ruleta; se conserva su ruta para los enlaces guardados. Bienvenida
general de cinco imágenes después del inicio de sesión, separada de la llegada
de la mascota. Esta última usa cuatro imágenes de cigüeña de la especie adoptada,
sonidos de cachorro suavizados y transición a la habitación real. Las despedidas
mantienen a las mascotas erguidas sobre dos patas. No es un video.

Penales conserva los movimientos aprobados; el arco queda centrado en la vista
del pateador. Farolitos orienta la puerta hacia el corredor de llegada, articula
su hoja, ilumina sus tres sellos y muestra la llave dorada con destellos. Incorpora
el audio de murciélagos aprobado para el cofre incorrecto, respetando la opción
de sorpresas reducidas. Menús sin música de fondo; cada juego conserva su audio.

Guardianes: diez puntos de botín restante por moneda para la expedición en pareja;
solitario mantiene la mitad. Los siete juegos incluyen 10% extra sobre el premio
al superar un récord previo, redondeado hacia arriba dentro de sus límites diarios.
Distancia en correr; mejor tiempo de victoria por dificultad/mapa/modalidad en
Guardianes; menos pasos por dificultad/modalidad en Farolitos; mejor racha de
victorias en Pong, Quiz y Penales. Pintura usa la racha por voto coincidente de ambos,
no una puntuación visual enviada por el cliente. Primer resultado fija la base;
empates y guardados repetidos no generan extra. Permisos de liquidación reservados
al servidor y libro de abonos por partida/generación.

Migraciones 20261019014026 y 20261019015436 aplicadas; guardian-adventure v11 activo
con JWT obligatorio. Pruebas PGlite de las siete liquidaciones, redondeo, récord,
empate, límite, guardado repetido, saldo compartido y permisos de service_role:
correctas. No se usaron cuentas ni saldos reales para esas pruebas. Consulta remota
confirma helpers no ejecutables por el cliente. Auditoría: dos notas informativas
por RLS sin políticas en tablas privadas deliberadamente cerradas; sin avisos nuevos.

Treinta y tres pruebas Node focalizadas y tres Flutter correctas; análisis de
navegación/bienvenida sin incidencias. Evidencia de centrado mediante proyección
de la cámara de los modelos reales; no equivale a una captura del teléfono.
El usuario comprobó y aprobó los juegos antes de este lote.

Arte nuevo integrado desde assets/images/ui, con maestros/prompts en
design/welcome-v4 y design/adoption-story-v3. Cinco imágenes de bienvenida suman
906560 bytes. Los originales GLB de las mascotas y el catálogo activo se conservan;
las boinas experimentales siguen fuera del catálogo y del APK.

Pendientes de alcance previo: Social por ID/Descubrir y revisión artística completa
de todas las prendas. No presentar este APK como publicación en Google Play,
pagos reales habilitados o validación artística perfecta. La cuenta Play aún no
se ha creado. Registrar al terminar el resultado real de compilación y firma.
