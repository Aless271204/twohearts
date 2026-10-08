# NIDO 1.1.2: correcciones y validación

## Implementado en el código
- Pip utiliza la misma escena 3D y el mismo inventario en inicio, tienda y runner. Los accesorios se unen a los huesos Head y Spine2 del GLB original. Se elimina la capa de accesorios pintada sobre la pantalla.
- Puente: siete dibujos compartidos para todas sus secciones. Sin sombras dinámicas; resolución adaptativa, reutilización de obstáculos y monedas, HUD limitado y cámara estable para el fondo pintado.
- Carrera: patrones deterministas variados, monedas iniciales en un carril seguro, ritmo cada 150 m, meta del reino a 600 m y validador versión 3 compatible con versiones 1 y 2.
- Fotos: referencias estables y enlaces autorizados de cinco minutos, renovación y reacción al cierre de sesión. Compatibilidad con enlaces antiguos.
- Audio deja de bloquear el arranque y se pausa al entrar al runner. Se elimina el permiso de ubicación en segundo plano y las credenciales de demostración visibles.
- Publicación: compilación de producción requiere secretos privados de firma; la firma de pruebas solo se permite explícitamente en CI y no puede publicarse como versión de producción.

## Cambios remotos pendientes de aprobación
La revisión automática rechazó la primera migración amplia y la creación/envío de una clave privada de firma. No se aplicaron por otra vía.

La migración reducida `supabase/migrations/20261008192545_privacy_and_server_authority.sql` vuelve privado memory-photos, limita subir/borrar a la carpeta del propietario, permite leer al propietario y su pareja, fija la configuración de siete funciones y retira privilegios estructurales y escrituras de monedas. Restringe la edición de partner_id e invite_code para impedir enlaces falsificados. Las cuatro fotos existentes tienen rutas compatibles. Las APK antiguas necesitarán actualización para abrir recuerdos privados.

Firma propuesta: PKCS12, RSA 3072, alias nido-upload; cuatro secretos cifrados en Aless271204/twohearts: NIDO_KEYSTORE_BASE64, NIDO_STORE_PASSWORD, NIDO_KEY_PASSWORD, NIDO_KEY_ALIAS. Copia local cifrada en outputs/signing/nido-upload.p12, fuera del repositorio. La contraseña se conserva en credentials.dpapi, protegida por el usuario de Windows, y debe respaldarse además en el gestor de contraseñas del propietario; no se publicará en archivos, logs o artefactos. No se ha generado ni enviado la clave.

## Catálogo
Se conservan propiedad y precios actuales; no se introducen pagos. Los 17 accesorios de Pip tienen formas 3D por estilo y anclajes comunes. Cabeza/gafas siguen Head; bufandas siguen Neck; ropa y mochila siguen Spine2. El ajuste visual de cada combinación necesita revisión; un test de geometría no demuestra que todas las combinaciones carezcan de intersecciones.

## Límites
No hay medición en un teléfono físico. Las suscripciones y precios nuevos quedan para el final, por indicación del usuario. La protección de contraseñas filtradas de Supabase requiere revisar la disponibilidad del plan; no se cambia el plan ni se contrata un servicio. Google nativo necesita configuración de proveedor/redirecciones; no se da por operativo.


## Evidencia
Primera revisión CI: Actions 37835122314, commit c2d13e3: 18 pruebas JavaScript, análisis y pruebas Flutter, web release, APK de pruebas y ejecución Android sin conexión correctas. Las últimas mejoras de ajuste y agrupación de monedas se verifican en una segunda compilación.
Carrera real del navegador: 600 m y 32 monedas, reproducidos exactamente por el validador versión 3. Se publicó la función forest-runner versión 4 con JWT obligatorio; rechazo sin sesión comprobado con HTTP 401. Reglas históricas 1/2 conservadas.
El catálogo visual `pip-catalogue-1.1.2.png` contiene renders reales de los 17 objetos. Se corrigieron gafas sobre la frente, ropa demasiado ancha y posición de la bufanda después de inspeccionarlos.
