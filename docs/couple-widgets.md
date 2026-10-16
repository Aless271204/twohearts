# Widgets Android

- **Para ti**: última foto, frase o dibujo enviado desde Inicio. Actualización al abrir NIDO, manual y trabajo periódico de Android (30 minutos; el sistema puede retrasarlo). No hay entrega push instantánea con la app cerrada.
- **Nuestra historia**: aniversario real del perfil, días naturales transcurridos y distancia entre las últimas ubicaciones compartidas. No solicita ubicación por sí mismo. Muestra la fecha del punto más antiguo de ambos; nunca presenta un dato guardado como directo. Se consulta al abrir la aplicación y cada minuto mientras está activa. Sin datos muestra «no disponible», no cero inventado. El contador de días se recalcula al actualizar Android el widget.
- Ambos ofrecen las categorías home_screen y keyguard. El anfitrión de Android decide la disponibilidad en bloqueo; no se puede forzar desde NIDO. Añadir desde el selector del sistema. Mostrar información con el teléfono bloqueado es una elección del usuario al añadirlo allí.
- Cerrar sesión borra el caché privado de ambos widgets. El token de lectura de notas no contiene la sesión de Supabase; los datos de ubicación no se consultan usando ese token.
- Prueba pendiente: selección y apariencia en bloqueo en un Pixel físico con versión compatible. El emulador comprueba el canal nativo y el almacenamiento, no la interfaz de bloqueo de todos los fabricantes.
