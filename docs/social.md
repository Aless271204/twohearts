# Social: estructura y revisión

## Una estructura con responsabilidades separadas

- `lib/features/social/social_models.dart`: publicaciones, comentarios y páginas del feed.
- `lib/features/social/social_repository.dart`: único punto de comunicación con Supabase; incluye una demostración aislada sin llamadas al servidor.
- `lib/features/social/social_screen.dart`: presentación, publicación, comentarios y estados de carga/error. Conserva la posición de Social en la navegación.
- `lib/presentation/social_screen/social_screen.dart`: exportación de compatibilidad para las rutas existentes, sin implementación duplicada.
- `supabase/migrations/20261010221012_social_unified_secure_feed.sql`: permisos, funciones, almacenamiento y caducidad.
- `supabase/tests/social_security.sql` y `test/social_test.dart`: pruebas de acceso y de interfaz.

## Reglas aplicadas

El servidor asigna autor, fecha y caducidad. Las publicaciones desaparecen del feed y rechazan lecturas/interacciones al cumplir 24 horas. Una tarea cada cinco minutos limpia las filas caducadas y sus likes/comentarios asociados. La app utiliza el reloj del servidor y un contador monotónico para no prolongar la visibilidad al cambiar la fecha del teléfono.

Amigos incluye las publicaciones propias y las de personas seguidas; Descubrir muestra las publicaciones activas de la comunidad autenticada. Los campos públicos son contenido, alias, contadores y las fechas necesarias. Nunca se expone el perfil completo mediante un join público. Publicar anónimamente oculta el identificador del autor en la respuesta, incluso al bloquearlo mediante su publicación.

Likes son idempotentes por publicación/persona. Las cuentas no pueden fijar contadores ni extender la duración. Los comentarios admiten hasta 500 caracteres; los puede eliminar su autor o quien publicó el recuerdo. Los errores conservan el borrador. Reportar y bloquear están disponibles en cada publicación ajena.

Las fotos usan un bucket privado, máximo 5 MB, JPG/PNG/WebP. Se descargan autenticadas; la política excluye creación de enlaces firmados y listados. No se cargan enlaces externos. Las imágenes visibles sí pueden ser copiadas o capturadas por quien las ve: no se promete impedirlo.

La demostración está rotulada, no crea usuarios ni contenido real y sus cambios desaparecen al cerrarla. No sustituye las pruebas entre cuentas reales.

## Verificación realizada

La migración se aplicó con autorización del propietario. Las pruebas SQL se ejecutaron en una transacción con tres identidades temporales y ROLLBACK. No quedaron cuentas de prueba. Se verificaron feed propio, anonimato, perfiles privados, likes sin duplicados, rechazo de publicaciones caducadas, comentarios, seguidores privados, bloqueo y rechazo de llamadas sin sesión. Las pruebas Flutter cubren límite temporal, likes, borrador/reintento de comentarios, cambio de sesión y teclado a 320 px.

## Límites y siguientes comprobaciones antes de publicar

- Probar carga y descarga real de fotos y publicaciones entre dos dispositivos, incluyendo red lenta y cierre de sesión. La prueba SQL de política no sustituye este recorrido.
- Las filas caducadas se eliminan automáticamente; los archivos de fotos quedan inaccesibles, pero aún falta automatizar su eliminación física a través de la API de Storage. No borrar directamente `storage.objects`.
- Definir quién revisará reportes y cómo responderá. La interfaz permite reportarlos, pero no existe todavía un equipo ni un panel de moderación.
- Revisar los avisos de autenticación fuera de Social: protección de contraseñas filtradas desactivada, funciones antiguas con `search_path` mutable y `get_couple_id_for_user` ejecutable sin iniciar sesión. No se modificaron módulos ajenos durante esta corrección.
- Esta revisión no certifica toda la app ni equivale a una prueba de penetración. Los cambios de pantalla necesitan una nueva compilación; el APK 1.1.8 anterior no los contiene.
