# Seguridad de datos · inventario para completar el formulario

No es un formulario ya enviado ni una certificación. Confirmar las prácticas de Supabase y SDKs de Google con sus fichas antes de responder.

| Datos | Función / destino previsto | Revisión necesaria |
|---|---|---|
| Correo, nombre, identificador de usuario, perfil/foto | Autenticación y perfil en Supabase | Declarar recopilación, vinculación e identificación |
| Fotos, dibujos, textos, recuerdos, notas y mensajes | Álbumes, pareja, widgets y funciones sociales | Declarar contenido generado y compartido por decisión del usuario; revisar públicos/privados |
| Ubicación aproximada/precisa y última posición | Mapa y distancia con la pareja | Opcional; declarar ubicación y tratamiento de última ubicación; no prometer actualización constante en segundo plano |
| Grabaciones/audio | Funciones que utilicen micrófono o voz | Revisar guardado local/servidor por función antes de declarar |
| Partidas, puntuaciones, inventario, oro y salas | Juego online, recompensas y personalización | Declarar actividad de la app y datos asociados al usuario |
| Identificadores/dispositivo, diagnósticos e interacción con anuncios | Google Mobile Ads/UMP cuando se solicita un anuncio | Confirmar documentación del SDK; incluso una compilación de prueba incorpora SDK |
| Datos de pago | Compras reales desactivadas | No afirmar cobros habilitados; revisar de nuevo al integrar Play Billing |

- Tráfico remoto HTTPS; solo servidor local de recursos permite HTTP en localhost/127.0.0.1.
- No marcar “no se recopilan datos”.
- Comprobar uso compartido con proveedores frente a excepciones de proveedor de servicio de Google; no adivinar respuestas binarias.
- Anuncios: SDK y botón de anuncios presentes; candidata usa anuncios de prueba. No activar anuncios reales hasta configuración y revisión AdMob/UMP.
- Público objetivo: no seleccionar niños solo por las mascotas adorables. NIDO tiene relación de pareja, contenido social y ubicación; el propietario debe definir público, restricciones y moderación.
- Contenido social requiere reportes, bloqueo, moderación y normas públicas. Verificar funcionamiento real antes de producción.
- Solicitud autenticada de eliminación incorporada al perfil; página externa y proceso de ejecución todavía pendientes.
