# NIDO 1.1.3: bosque y mascota compartida

La habitación utiliza la pose Idle_9 del modelo original de Pip. La posición, la rotación y el contacto de los pies con el suelo se mantienen fijos; arrastrar la mascota no desplaza la cámara. Se eliminó el movimiento vertical decorativo del contenedor.

El recorrido utiliza un bosque dentro del mismo renderizador Three.js del puente: árboles, helechos, flores, rocas, río y cascada animados, con un reino sobre una plataforma de roca. El puente continúa fuera de la distancia visible. La cámara conserva al personaje dentro de la pantalla en los dos carriles exteriores, también en formato vertical estrecho.

La carrera nueva no termina a los 600 metros. Guarda progreso por tramos, conserva los récords y aumenta la dificultad. Los límites de recompensa por partida y por día siguen vigentes. El servidor valida los tramos y los reintentos; guardar un tramo no entrega monedas anticipadas.

Los dos miembros de una pareja con vínculo mutuo comparten cuidado y equipamiento. Los mensajes contienen texto y se reproducen mediante una voz de mascota; pueden dictarse en dispositivos compatibles. La quinta recuperación del mensaje lo elimina de la base de datos. La prueba usa el motor de voz de Android, por lo que el timbre depende de las voces instaladas. El contador se consume al recuperar el contenido para reproducirlo, incluso si la reproducción falla después. No se guarda la grabación original.

## Verificación

- Pasaron las 20 pruebas JavaScript, incluidas reproducción de partidas antiguas, carrera nueva y división en tramos.
- Se comprobó en navegador la pose fija de Pip tras arrastrar y esperar, y la visibilidad completa en ambos carriles exteriores.
- Una carrera real de navegador superó 1.400 metros sin finalizar ni acumular un historial ilimitado en memoria.
- La prueba de guardado con respuesta demorada y colisión simultánea terminó con índices y resultado coherentes.
- En Supabase se verificaron con datos temporales y reversión el cuidado compartido, el aislamiento entre parejas, las cinco escuchas y la denegación de acceso directo a los mensajes.
- La prueba completa de tramos en la base de datos detectó una ambigüedad SQL que se corrigió mediante una segunda migración. Los reintentos posteriores del ensayo remoto expiraron; su ejecución completa queda pendiente. Las pruebas locales de reproducción y concurrencia sí pasaron.

Las cifras de rendimiento del navegador no garantizan rendimiento en un teléfono físico. La calidad de voz y el uso simultáneo por dos usuarios reales requieren pruebas en dispositivos.

## Cambios pendientes de aprobación

La migración `20261008215554_pet_balance_and_runner_activity.sql` está preparada localmente y no se ha aplicado. Hará depender el crecimiento de aportes de ambos y renovará la caducidad de 24 horas con cada tramo validado. Actualmente el crecimiento cuenta aportes acumulados y sigue vigente la caducidad original para finalizar sesiones muy largas.

La migración de privacidad anterior `20261008192545_privacy_and_server_authority.sql` tampoco se ha aplicado. Esta versión no confirma la conversión del almacenamiento de fotos a privado.
