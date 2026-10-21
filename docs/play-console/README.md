# NIDO · Preparación Google Play · 20 de octubre de 2026

Estado: candidata de pruebas, NO apta todavía para producción ni enviada a Google.

## Archivo Android

- Flujo `.github/workflows/google-play-candidate.yml`.
- Nombre 1.3.2; versionCode 2030; App Bundle firmado con la identidad existente.
- Identificador Play propuesto: `app.nido.twohearts`. Es permanente una vez publicado: comprobar disponibilidad al crear la app.
- Las instalaciones laterales antiguas conservan `com.example.twohearts`. No afirmar que el paquete de Play actualiza esas instalaciones; es una instalación distinta. La cuenta online conserva sus datos.
- Android objetivo36; Java17; SDK compilación36; firma de depuración prohibida.
- No activa compras reales ni anuncios reales. `purchasesEnabled=false`; `NIDO_LIVE_ADS` no definido.
- El flujo solo genera artefactos; no publica fichas ni sube a Play.

## Antes de enviar la candidata a revisión

1. Datos públicos confirmados por el propietario: Alessandro BC; alessandroproyectos@gmail.com. Nombre público distinto de la identidad legal que Google verifique en su perfil de pagos.
2. Completar y publicar web de privacidad y solicitud externa de eliminación, accesibles sin instalar la app; enlazar la política desde el perfil de la app. Los documentos adjuntos son borradores, no URLs publicadas.
3. Atender las solicitudes de eliminación: la app registra peticiones autenticadas en `nido_private.account_deletion_requests`, pero NO hay un borrado automático ni una garantía de plazo. Definir responsable y proceso probado antes de publicar. Revisar datos compartidos, archivos de Storage, relación de pareja y dependencias de Auth; no borrar cuentas manualmente sin resolver esos vínculos.
4. Confirmar Google Play App Signing y guardar una copia segura de la clave existente; nunca adjuntar el P12 ni contraseñas a esta carpeta.
5. Completar Seguridad de datos, anuncios, clasificación de contenido, público objetivo y acceso a la app con credenciales de prueba creadas expresamente. No usar credenciales del propietario.
6. Capturar al menos dos pantallas reales Android de esta compilación y revisar el informe previo al lanzamiento. Las imágenes conceptuales no son capturas.
7. Comprobar páginas de16KB de todas las bibliotecas nativas y la firma del AAB. El control ZIP no sustituye ese análisis. El flujo ahora verifica el certificado esperado, recursos de juegos y alineación ELF de bibliotecas de64bits. Falta la prueba en un dispositivo/emulador16KB y el informe de Play.
8. Probar dos teléfonos: vinculación, inventario/ropa, ubicación consentida, salas y recompensas. La revisión visual de Chrome quedó bloqueada por la herramienta y NO se ha certificado.
9. Revisar versión nueva y límites de descarga en el explorador del App Bundle. El tamaño bruto de recursos no equivale al tamaño de descarga por dispositivo.
10. Cuenta personal nueva: prueba cerrada con12 participantes inscritos continuamente14 días; luego solicitar acceso a producción. La prueba interna es opcional y no sustituye esa prueba cerrada.

## Pagos

La candidata permite oro obtenido jugando. Para vender oro se necesita perfil de comercio, banco/verificaciones, productos de Play y facturación real con verificación de compra en servidor. No activar el interruptor del cliente para simular cobros. Los paquetes previstos1000/2000/5000 no están habilitados para pagos reales.

## Límites de esta entrega

- La compilación no certifica el encaje artístico de todo el vestuario. Las prendas nuevas temáticas siguen como candidatas sin activar en la tienda; los problemas artísticos documentados siguen requiriendo revisión real.
- Los renders e ilustraciones de concepto no son pruebas de funcionamiento ni capturas Android para la ficha.
- La sala de Guerra de Nieve conserva su código para repetir partidas; la integración completa con una única sala transversal entre todos los minijuegos requiere prueba y conciliación con el sistema de grupo existente. No afirmar que se verificó entre cuatro celulares.
- El inventario Excel, el refinamiento legendario y los drops semanales solicitados previamente no se consideran terminados por preparar esta candidata.
- La eliminación de cuenta registra solicitudes, pero la operación de borrado y la vía web siguen pendientes. No declarar la función de eliminación como un proceso completo en Seguridad de datos.

## Referencias oficiales revisadas

- https://support.google.com/googleplay/android-developer/answer/11926878
- https://support.google.com/googleplay/android-developer/answer/14151465
- https://support.google.com/googleplay/android-developer/answer/13327111
- https://support.google.com/googleplay/android-developer/answer/10787469
- https://support.google.com/googleplay/android-developer/answer/10841920
- https://play.google/developer-distribution-agreement.html
