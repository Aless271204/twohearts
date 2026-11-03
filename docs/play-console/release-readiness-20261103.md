# NIDO · Cierre de correcciones · 3 noviembre 2026

Estado: candidata 1.3.7 (2035) en preparación, **no publicada**. Este informe no certifica ausencia de errores ni cumplimiento legal completo.

## Correcciones aplicadas en el servidor

- El reparto de oro al desvincular pasó del 10 % por persona al 50 %: migración `20261103203140_wallet_half_separation`. No descarta saldo. Si el total es impar, la moneda restante se asigna de manera estable al primer miembro según el orden UUID existente. La instalación no separó personas ni alteró saldos actuales.
- Vinculación privada: migración `20261103210407_private_invite_attempt_limits`. Máximo 5 intentos por minuto y 20 por día para cada cuenta autenticada. Los contadores no guardan códigos, correos ni IP, no son accesibles a clientes y se eliminan en cascada al borrar la cuenta. La instalación no creó ni cambió vínculos.
- Verificación posterior: RLS activo en contadores; `anon` no ejecuta vinculación; `authenticated` conserva la operación normal pero no puede leer contadores ni ejecutar el auxiliar privado; una llamada sin sesión devuelve `not_authenticated`.
- Se mantienen las correcciones de autorización aplicadas el 29 de octubre: perfil protegido, relación recíproca para compartir, consulta por correo retirada y mensajes restringidos a la pareja vigente.

## Cambios del cliente reunidos con 1.3.6

Rama `codex/launch-readiness-20261103`; integra `codex/widgets-visual-136` hasta `2425ae7` y las correcciones de mascotas de `ed5ffc4`. Fuente candidata: `3af8f6c3a4590ba5ced3080439b7cd8b3606469e`.

- Recuperación: solicitud por correo, código temporal comprobado por Supabase, contraseña de al menos 12 caracteres y cierre de sesiones de renovación al finalizar. El código y la contraseña no se persisten. Los JWT de acceso ya emitidos pueden durar hasta su vencimiento.
- El registro reconoce confirmación pendiente y no entra en la app si el servidor no devolvió una sesión.
- Eliminado `WRITE_EXTERNAL_STORAGE`; deshabilitada la copia de datos de la app y añadidas reglas de exclusión.
- Fotos de álbum recodificadas sin metadatos EXIF/GPS ni nombre original, límites de tamaño y resolución. Se impide reutilizar referencias de subida al cambiar de cuenta.
- Aviso previo al compartir ubicación; cancelarlo no solicita el permiso.
- Interfaz de separación muestra las dos cantidades exactas del servidor y exige la política `half_v1` antes de confirmar.
- Se conservan los widgets y los arreglos de adopción individual y carga con reintento. Los conjuntos de ropa experimentales no forman parte de esta candidata.

## Pruebas realizadas

- 18 pruebas Flutter correctas: recuperación, fotos privadas, álbumes, configuración de widgets, adopción individual y reintento de carga.
- 34 escenarios PostgreSQL aislados correctos para reparto de oro: autorización, confirmación, saldo cambiado, totales pares/impares/grandes, conservación exacta, repetición rechazada y perfiles ajenos intactos.
- 26 escenarios PostgreSQL aislados correctos para límites de invitación: rechazo anónimo, ventanas minuto/día, cuotas independientes, permisos, enlace normal y contadores privados. No es una prueba de carga ni de concurrencia entre conexiones independientes.
- Análisis dirigido de recuperación, rutas y servicio: sin errores; conserva cuatro avisos anteriores de estilo, variable sin uso y API de clave pública obsoleta. No afirmar análisis global sin avisos.
- Asesor de seguridad posterior: 36 avisos informativos RLS sin políticas directas, 28 avisos de RPC autenticadas SECURITY DEFINER y protección de contraseñas filtradas desactivada. Las tablas privadas se mantienen cerradas. Los avisos de RPC requieren revisión por operación, no revocación masiva.

## Correo: autorización recibida, instalación pendiente

El propietario autorizó crear `NIDO Supabase Auth` en Brevo y guardarla exclusivamente en SMTP privado de Supabase, sin contratar un plan. Brevo exige confirmar por correo la creación. **No se ha creado ni guardado la clave**, no se ha activado SMTP personalizado ni se ha activado confirmación obligatoria.

Preparado `design/auth-email/recover-password.html` con `{{ .Token }}`. No está instalado. Debe desplegarse de manera coordinada con el cliente que admite códigos, después de comprobar entrega. No sustituir la plantilla por código únicamente mientras los clientes existentes no tengan esa pantalla.

## Compilación y entrega

- Primera ejecución `41717298772` sobre `ebf438b`: iniciada, reemplazada lógicamente por la candidata que incorpora el límite de invitaciones.
- Ejecución vigente: https://github.com/Aless271204/twohearts/actions/runs/41718871878 . Última observación: pendiente.
- El flujo genera AAB firmado y verifica el archivo, sin subir a Play ni enviar a producción. El artefacto debe identificar la fuente y su SHA-256.

## Pendientes reales antes de afirmar que todo está terminado

1. Completar el código de identidad de Brevo; crear y guardar SMTP, verificar remitente y entrega real. Comprobar recuperación en el cliente y después activar confirmación para nuevos registros. No cambiar contraseñas de testers.
2. Terminar CI y verificar el AAB exacto. Instalar y ensayar Android: permisos denegados/aproximados, entrada/salida/cambio de cuenta, widgets privados, mascota, prendas y minijuegos, anuncios y compra de prueba.
3. Ensayo integral de eliminación con cuenta desechable y archivos. La solicitud autenticada existe; el borrado integral todavía no se ha ensayado. Nunca borrar testers o cuentas de revisión para esa prueba. Usar Storage API para el archivo real y Auth Admin para la cuenta, no DELETE de sus tablas internas.
4. Revisar retenciones y archivos huérfanos, datos compartidos y referencias no cubiertas por cascadas. El reparto de objetos al separarse no fue modificado en esta corrección de oro; debe comprobarse contra el acuerdo de repartir sin duplicación.
5. Reconciliar ficha, política pública y Seguridad de los datos con la versión exacta enviada, incluido Brevo cuando se active. No prometer funciones experimentales ni fotos efímeras todavía no implementadas.
6. MFA del responsable y flujo completo de reautenticación: requieren participación del propietario. Protección de contraseñas filtradas está restringida al plan Pro; no se contrató. CAPTCHA requiere integración previa, no activación a ciegas.
7. Publicar a la prueba cerrada y recopilar confirmación real de las incidencias de Gladys y Fausto. No confundir pruebas automáticas con confirmación en sus teléfonos.

La fecha de acceso a producción depende del contador oficial de Play y de la revisión de Google. El 3 de noviembre se observaron 12 testers y 7 días continuos: alrededor del 10 de noviembre se podría solicitar acceso si se mantiene el requisito; no es una fecha de lanzamiento garantizada.
