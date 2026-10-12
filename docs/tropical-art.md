# Ambientación tropical del recorrido

> Historial de propuestas anteriores. La implementación vigente del bosque ligero se describe en [forest-art-integration.md](forest-art-integration.md). Las cascadas y el reino de geometría procedural de este documento ya no se cargan en el juego.

Los objetos nuevos están modelados con geometría de Three.js en `assets/runner/tropical.js`: monedas doradas con corazón en relieve por ambas caras, palmeras, flores y cascada. Se comparten geometrías y materiales entre instancias. El pingüino original y sus animaciones se conservan.

El camino utiliza una textura de vetas creada localmente, tablones separados y sombras suaves de 1024 píxeles. El fondo combina el cielo y las nubes existentes con agua animada mediante una textura desplazable. No requiere vídeos ni descargas de imágenes para reproducir el bucle.

La música original se sintetiza localmente a 96 BPM con melodía, bajo y percusión suave. Arranca al pulsar jugar y conserva silencio, pausa y suspensión al salir.

## Reacciones del recorrido

Las recogidas producen partículas doradas y un pulso del contador. Cinco recogidas consecutivas muestran una celebración visual sin cambiar la recompensa. Perder una moneda reinicia esa racha. El aterrizaje produce partículas y una deformación pequeña del grupo que contiene a Pip, sin editar su archivo ni su rig. El grupo recupera su escala normal; las reglas de salto y colisión no cambian.

Las palmeras mueven sus hojas, las plantas reaccionan a la proximidad y ocho mariposas animadas acompañan el camino. Los efectos usan una reserva fija de 32 partículas con geometría y material compartidos; se limpian al reiniciar. El movimiento se detiene al pausar.

La cascada está apoyada en un acantilado continuo con rocas irregulares y vegetación. Un río en la plataforma superior llega al borde, el agua cae delante de la pared y desemboca en una poza con ondas. Es decoración de fondo, no un obstáculo nuevo.

## Puente y bosque vivo

El puente utiliza tablones de grosor mayor con variaciones de anchura y orientación, clavos, vigas, postes de tronco y cuerdas curvas. La superficie de apoyo mantiene la altura de la física existente. A ambos lados, canales de agua con un shader animado muestran corriente y reflejos; su tiempo se detiene al pausar. Los frutos y flores son decorativos y no introducen otra economía.

Las orillas incorporan helechos de hojas emparejadas (50 hojas en una única malla instanciada por conjunto), flores de cinco pétalos, frutos y las rocas originales. Cinco aves de colores cruzan el bosque con movimiento de alas. Estos recursos se crean localmente en `forest-life.js` y no requieren servicios externos. Sigue pendiente medir rendimiento en dispositivos reales.

## Reino sobre la cascada

El agua utiliza materiales animados de la misma familia turquesa en río, poza, cauce superior y caída. Un único río de 15 unidades de ancho pasa bajo el puente y llega a la poza; la corriente avanza desde la cascada hacia el primer plano. La caída usa vetas verticales claras en lugar de ondas horizontales. Todo se pausa junto con el juego.

Un reino con cinco torres, techos violetas, detalles dorados, ventanas y puerta luminosa se ubica en la plataforma superior del acantilado. Es un destino visual de fantasía; esta actualización no añade una condición de victoria ni una transición jugable al castillo.

## Referencia de cañón fantástico

La nueva composición incorpora paredes rocosas a distintas distancias, coronas de vegetación, coníferas y rocas en las orillas. El fondo tiene tres caídas de agua sobre terrazas conectadas, con pequeños cruces de madera. El reino se desplaza a una cima lateral con soporte rocoso visible. Se retiran las palmeras de este bosque y se reutilizan los árboles originales. Son recursos 3D locales inspirados en la referencia, no una reproducción exacta del acabado de la imagen. La comprobación en Chrome verifica carga y composición; no acredita rendimiento móvil ni un nivel jugable del castillo.

La dificultad existente aumenta continuamente según la distancia acumulada durante el tiempo activo: velocidad de 8 a 14 y separación de obstáculos de 28 a 18. Llega al máximo a los 900 metros. Las pausas no avanzan el recorrido. Se conserva esta curva compartida con el servidor para no alterar la validación de recompensas.

Validación: pruebas de recursos, controles, audio y simulador; vista independiente en Chrome con tamaño móvil. Esta vista no acredita monedas. Antes de distribuir se debe probar rendimiento en Android físico y compilar Flutter; Flutter no está disponible en este entorno. Los cambios están en la copia local, sin publicación ni actualización de la app instalada.
