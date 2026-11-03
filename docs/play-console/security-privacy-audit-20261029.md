# Auditoría de seguridad y privacidad · 29 octubre de 2026

## Alcance y estado real
Revisión de código Flutter/Android, configuración Auth, metadatos/políticas de la base Supabase nbldsimuntfeeynaadak y depósitos de imágenes. No se descargaron contenidos privados para analizar fotografías ni conversaciones. No se borraron cuentas o archivos de testers. No constituye una certificación legal ni una prueba de penetración exhaustiva. La app de los testers todavía no incorpora los cambios locales de esta revisión.

## Correcciones aplicadas al servidor
Migraciones 20261029195312_privacy_authorization_hardening y 20261029200402_private_invite_lookup aplicadas y confirmadas mediante MCP.
- El cliente no puede insertar/borrar perfiles, modificar partner_id, email o invite_code, ni vaciar tablas con TRUNCATE. Sí puede editar las columnas de presentación permitidas mediante RLS de propietario.
- get_my_partner_id exige relación recíproca vigente. Las políticas de recuerdos, viajes, fechas y ubicación dejan de confiar en un partner_id histórico como autorización permanente.
- get_couple_id_for_user solo acepta el UID de quien llama o servicio autorizado; anon ya no puede ejecutarla.
- handle_new_user conserva su función de disparador pero no puede invocarse como RPC de cliente. Rutas de búsqueda de funciones antiguas fijadas.
- Mensajes nuevos solo hacia pareja recíproca; el destinatario no puede reescribir el remitente o el contenido original mediante UPDATE.
- Álbumes propios siguen accesibles tras desvincular; los de otra persona requieren vínculo actual y grupo vigente.
- La búsqueda por correo ya no puede ejecutarse desde clientes: devolvía el código privado que permite enlazar. Los clientes ya instalados deben usar el código que comparta personalmente el otro usuario.
- Mínimo de contraseña del servidor fijado en 12 caracteres, reabierto el panel para comprobar persistencia. No se cambiaron contraseñas existentes.

## Cambios locales listos para próxima actualización
- Android: eliminado WRITE_EXTERNAL_STORAGE; el selector de fotos y compartir imágenes no necesitan acceso amplio al almacenamiento. No se retiraron micrófono, ubicación ni notificaciones porque tienen usos existentes.
- Android: allowBackup=false y reglas de exclusión para copia cloud y transferencia de datos de la app. No garantiza borrar copias históricas ya creadas ni protege un dispositivo comprometido.
- Álbumes: decodificación y nueva codificación PNG antes de subir. Límite de entrada/salida 10 MB, rechazo de imágenes mayores de 40 megapíxeles y reducción a un máximo de 1280 por lado. No transmite EXIF/GPS, comentarios ni nombre original. En imágenes animadas se guarda la primera imagen decodificada.
- Ubicación: aviso previo explícito sobre destinatario, uso mientras la app está abierta, servidor, conservación del último punto y canal para solicitar eliminación. Cancelar no inicia el permiso.
- Enlace: sustituida la búsqueda por correo por explicación del intercambio privado de código.
- Errores de los servicios de perfil/álbum: retirados mensajes originales del servidor de registros y del mensaje mostrado al crear álbum.

## Controles observados que se conservan
- 0 tablas públicas sin RLS; no vistas públicas detectadas. Tablas sin políticas directas no se abren: varias se usan exclusivamente por RPC autorizadas.
- social-media, profile-avatars y memory-photos son privados, con límites de tamaño y MIME. Se revisaron sus políticas. Las fotos de recuerdos usan referencias y URL firmadas de 300 segundos; la política pública explica su vigencia residual.
- HTTPS obligatorio salvo loopback local necesario para escenas del juego.
- Avatar y foto de nota ya se recodificaban; dictado Android exige reconocimiento local disponible; no almacena audio original de dictado.
- Anuncios: UMP antes de solicitar, canRequestAds comprobado y opción de privacidad. Falta comprobar cada región en un Android físico.
- Compras: verificación del usuario, producto permitido, estado pagado y cuenta ofuscada coincidente. Oro virtual no es dinero ni criptomoneda. No se activaron cobros durante esta auditoría.
- Eliminación: solicitud autenticada idempotente y página web de solicitud externa. Proceso manual documentado, máximo 30 días. Cola sin solicitudes al consultarla; esto no certifica que el proceso completo de borrado haya sido ensayado.
- Patrón de claves privadas/secretas: sin coincidencias en los textos de cliente examinados. No cubre historial completo de Git ni garantiza ausencia de secretos de cualquier formato.

## Pruebas y límites
- scripts/check-privacy-authorization.mjs: 20 comprobaciones correctas en PostgreSQL aislado con identidades ficticias, sin tocar datos productivos.
- Verificación real de privilegios: partner_write=false, invite_write=false, nickname_write=true, profile_read=true, profile_insert/delete/truncate=false, anon_couple_lookup=false, auth_trigger_execute=false, normal_link=true, 0 permisos TRUNCATE de cliente en tablas públicas.
- Consulta posterior: email_lookup_enabled=false y code_link_enabled=true.
- Flutter: 7 pruebas correctas (fotos y pruebas existentes de ubicación/habitación).
- Solicitudes de eliminación: comprobación aislada correcta de autorización, privacidad de cola e idempotencia.
- Verificación de compra: prueba de política correcta.
- Análisis de seis archivos modificados: sin errores tras las reparaciones; persisten avisos de estilo/deprecación/elementos sin uso anteriores. PairingScreen sin incidencias del analizador.
- No prueba Android física, APK/AAB, publicación web ni actualización de testers generada en esta sesión.

## Pendientes que impiden decir “todo terminado”
1. Correo transaccional: Confirm email está desactivado y custom SMTP no configurado. Hay que configurar y verificar entrega y recuperación, adaptar el registro a confirmación pendiente y SOLO después activar verificación para nuevas cuentas. Se pidió al propietario elegir servicio existente u opción gratuita. No bloquear nuevos registros activando el ajuste sin entrega.
2. Prevención de contraseñas filtradas: desactivada; el panel la restringe a Pro. No contratar sin decisión de presupuesto. CAPTCHA desactivado; requiere proveedor y experiencia de registro compatibles antes de activar.
3. Cambios seguros de contraseña/reautenticación y MFA del responsable: revisión pendiente del flujo completo. No cambiados a ciegas.
4. Ensayar eliminación integral con cuentas dedicadas: Storage API, sesiones/JWT, datos compartidos, compras/retenciones y restauración. La solicitud manual no acredita que ese ensayo esté completado.
5. Revisión de retenciones y limpieza de archivos huérfanos: el ocultamiento/vencimiento no equivale a borrado físico. No eliminar archivos reales de testers sin confirmar titularidad y alcance.
6. Reconciliar ficha, política pública y Seguridad de los datos con la próxima versión exacta; no marcar “sin datos compartidos” por tener buckets privados (SDK de anuncios y funciones de pareja).
7. Antes de Android 17/API37, revisar el botón de ubicación para solicitudes puntuales y la justificación de acceso preciso persistente. Actualmente targetSdk36. No justificar precisión solo por mostrar kilómetros.
8. Instalar candidata y verificar permisos combinados de SDKs, sesión/cierre/cambio de cuenta, widgets privados, cámara/galería, GPS aproximado y denegado, anuncios, compra de prueba, desvinculación y eliminación. Después actualizar a testers.
9. Revisar todos los RPC privados y límites de intentos de vinculación/códigos. Se mantienen avisos de funciones SECURITY DEFINER autenticadas: varias son APIs intencionales, no se revocan masivamente sin auditar sus controles internos.

## Reversión y evidencia
Copia de esquema y permisos anteriores, verificación posterior y reversión de emergencia guardadas en:
C:/Users/Lenovo/.codex/visualizations/2026/10/08/01a119dd-fbd0-7490-9d7e-2daf0e5cab9d/nido-security-20261029/
La reversión restaura debilidades conocidas y solo se debe usar ante una regresión confirmada y autorización. Para revertir la retirada de búsqueda por correo haría falta además restaurar explícitamente su permiso anterior; no hacerlo como cambio rutinario.
La primera aplicación fue bloqueada por revisión automática; después de preparar pruebas y reversión el propietario autorizó expresamente y las migraciones se aplicaron correctamente. No queda bloqueada esa corrección.

## Fuentes de criterios
- Google Play, Datos de usuario: https://support.google.com/googleplay/android-developer/answer/10144311?hl=es
- Google Play, eliminación: https://support.google.com/googleplay/android-developer/answer/13327111?hl=es
- Google Play, ubicación: https://support.google.com/googleplay/android-developer/answer/17033915?hl=en
- Supabase, privilegios por columna: https://supabase.com/docs/guides/database/postgres/column-level-security
- Supabase, RLS: https://supabase.com/docs/guides/database/postgres/row-level-security
