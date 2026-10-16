# NIDO · Guardianes del Alba
Propuesta creativa v1 · 15 de octubre de 2026. Conceptos generados con image_gen integrado. No es un juego implementado ni una captura del APK.

## Identidad e historia
Aventura lateral 2D pixel art, lineal, con combates contra jefes. Tierna, aventurera y con desafío legible. Una tormenta apaga el Faro del Nido y dispersa cinco semillas de luz. Las mascotas recorren los dominios de sus guardianes para devolverles la calma y encender el faro. Los guardianes se liberan de la tormenta; al terminar cada combate ayudan a reconstruir el refugio. Relato visual breve, sin diálogos largos antes de cada intento.

Tres direcciones exploradas en la primera imagen: Bosque vivo, Sueños estelares y Taller de juguetes. Dirección inicial recomendada: Bosque vivo; los otros pueden ser capítulos futuros y no tres proyectos paralelos.

## Formato y ritmo
Pantalla horizontal completa durante la partida. Selección dentro de los minijuegos existentes, sin cambiar las cinco pestañas de NIDO. Se elige mascota, modo y etapa, se atraviesa un tramo de aventura de 20–40 segundos y se entra en la arena. Cada combate objetivo: 2–4 minutos. Guardado tras cada jefe; reintento inmediato desde la arena. Campaña inicial propuesta: cinco jefes, no un mundo abierto. Boss Rush continuo opcional después de completar la campaña.

## Controles
Izquierda/derecha a la izquierda; salto, esquiva y pulso de linterna a la derecha. Mantener pulso carga un ataque más fuerte. Salto con altura variable, pequeña tolerancia al borde y memoria breve del botón para que responda bien al tacto. Esquiva con recuperación visible; no se puede encadenar indefinidamente. Controles ajustables en tamaño y posición. Indicadores importantes lejos de dedos y controles.

## Combate
Observar aviso → esquivar → aprovechar apertura → recuperar posición. Tres patrones por jefe; segunda fase añade combinaciones de patrones conocidos. El ataque se anuncia con animación, sonido y forma además del color. Nada de golpes inevitables ni daño por contacto permanente con un jefe inmóvil. Cuerpos/hitboxes simples y consistentes para las cuatro mascotas, independientes de los cosméticos. Sin requisitos estadísticos de tienda para ganar.

## Jefes
1. Guardián Musgo, tortuga del bosque: pisotón con onda baja, hojas espaciadas y semilla que deja al descubierto su sello. Enseña salto, esquiva y apertura.
2. Bruma, nutria del río: corrientes que desplazan, burbujas que suben y troncos flotantes. Enseña aprovechar el escenario, no solo disparar.
3. Dalia, polilla del invernadero: franjas de polen, descensos diagonales y flores que sirven de cobertura. Alterna alturas y zonas seguras.
4. Orión, búho del observatorio: constelaciones anuncian dónde caerán estrellas; espejos devuelven pulsos hacia su escudo. Enseña leer el patrón antes de actuar.
5. Nimbo, ciervo de la tormenta: ráfagas y lluvia que combinan lo aprendido; calma intermedia y final luminoso. Desafío final con tres fases breves.

## Pareja y solo
En pareja, ambos son jugadores completos; no hay un acompañante reducido a soporte. Dos pulsos sincronizados llenan una barra de vínculo y permiten un ataque conjunto opcional. Un jugador caído deja una burbuja rescatable durante un intervalo, con límite por combate. Escala de dificultad según participantes, no simplemente duplicar la vida de los jefes. Modo solo plenamente viable, con aperturas adaptadas. Entrenamiento por jefe y asistencia opcional futura. Cooperativo online requiere sincronización real de jefe, daño y recompensas; una imagen no valida su implementación.

## Rejugabilidad
Orden de jefes fijo en campaña, pequeñas variaciones en secuencias legales, posiciones y tramos entre arenas. No mezclar ataques que eliminen todas las zonas seguras. Tras dominar: contrarreloj, retos opcionales y variantes de dificultad. Las recompensas por dominio son cosméticas y recuerdos del viaje; oro equilibrado con la economía existente, validado en servidor y sin cobros para reintentar.

## Arte y audio
Sprites de mascotas de aproximadamente 48–64 píxeles de alto como punto de partida, resolución lógica baja y escalado entero según dispositivo cuando sea posible. Paleta limitada por escenario, siluetas claras, fondos en capas, efectos cortos y avisos contrastados. Las imágenes de concepto deben traducirse a tiles/sprites de cuadrícula coherente: no son atlas utilizables directamente. Música de aventura por escenario, variación al cambiar fase y efectos diferenciados para salto, impacto, aviso y acción conjunta. Volúmenes separados, pausa al salir de la partida, ninguna barra o botón flotante de otras secciones.

## Inventario y personalización
Conservar las claves de inventario y el estado de propiedad de NIDO. Las prendas 3D NO se convierten automáticamente en ropa pixel art: requieren sprites por mascota, animación y punto de anclaje; pruebas en carrera, salto, caída y esquiva. Cosméticos no modifican colisiones ni potencia. No vender una apariencia del modo 2D antes de tener sus cuadros de animación completos. Prototipo puede empezar con las mascotas base y un atuendo bien revisado.

## Primer prototipo verificable
Una arena de bosque, un Guardián Musgo, una mascota controlable, tres ataques legibles, movimiento/salto/esquiva/pulso, derrota/victoria y reintento, música/efectos y pausa. Primero validar claridad, ritmo y respuesta en teléfono. Después incorporar las otras tres mascotas, cooperación y siguientes jefes sobre esa base. No construir cinco escenarios antes de comprobar que la primera pelea es divertida.

## Artefactos
- direcciones-visuales-v1.png: exploración de tres mundos.
- guardian-musgo-concepto-v1.png: intención visual de una pelea en horizontal.
Herramienta: image_gen integrada; dos generaciones originales, sin sustituir modelos ni editar el juego existente.

## Prompts de dirección visual (resumen de producción)
1. Tríptico original de aventura Boss Rush 2D pixel art para NIDO: pingüino negro/blanco con pañuelo coral y oso marrón con pañuelo salvia; arenas laterales contra tortuga de musgo, búho estelar y zorro de peluche mecánico. Píxeles visibles, siluetas adorables, avisos de ataque legibles; sin render 3D ni marco de móvil.
2. Concepto horizontal de combate Guardián Musgo: puente continuo de ruinas en bosque salvia, pingüino saltando onda de hojas y oso protegiéndose; gran tortuga con sello luminoso; HUD de corazones y barra de jefe arriba, dirección/salto/esquiva/pulso en esquinas inferiores. Pixel art original, atractivo, tierno y jugable; no es captura de un juego ya implementado.


## Dirección aprobada — arte primero y dificultades
Antes de integrar en la app, producir las referencias de cada mascota, jefes y ataques, enemigos, objetos y escenario. Estas hojas son referencias, no atlas animados listos para producción.
Dificultades exactas: **Fácil, Medio y Difícil**. No usar nombres alternativos. Las recompensas aumentan con dificultad, manteniendo límites y validación de servidor al integrar. El aumento se obtiene al completar retos, no por elegir Difícil y abandonar.
- Fácil: avisos amplios, ataques separados, más oportunidades de recuperar vida; recompensa base.
- Medio: patrones completos, menos pausas y más enemigos; recompensa intermedia.
- Difícil: combinaciones que exigen coordinación, aperturas más breves, rutas de tesoro más arriesgadas; mejor recompensa. Siempre conservar zonas seguras y avisos distinguibles.
- Enemigos ladrones solo afectan botín no asegurado de la expedición; permitir recuperarlo. No retirar compras ni oro ya guardado.
- Música adaptativa instrumental: ambiente al explorar; añadir pulso y percusión al acercarse peligro; bajo, tambores, cuerdas y melodía energética al entrar en jefe y fases avanzadas. Difícil debe sentirse más intenso, sin tapar avisos, sonidos útiles ni fatigar con volumen permanente.
- Separar música y efectos, controles de volumen, pausa de audio al salir. No reiniciar una canción en cada cambio de intensidad: transiciones musicales coherentes y capas sincronizadas.


## Decisiones posteriores del usuario (prioridad sobre los borradores)
- Jefe final: Guardián Musgo, la tortuga. Expresión con cierta malicia/desafío, sin terror ni violencia gráfica. La versión amable de la hoja v1 no es la dirección definitiva del villano. Nimbo/ciervo de la propuesta inicial deja de ser el jefe final.
- Ataque distintivo en Difícil: aviso, retraer cabeza y patas, rodar encerrado completamente en el caparazón, posibles rebotes, ventana de vulnerabilidad al terminar. Los avisos y las zonas seguras siguen siendo legibles.
- Modos obligatorios: solitario y cooperativo en pareja. Solitario entrega el 50 % de la recompensa equivalente de pareja para la misma dificultad/reto completado. No repartir automáticamente todo el premio al abandonar/desconectarse ni permitir duplicados al reconectar. Los objetivos que requieran dos jugadores necesitan una alternativa de un jugador.
- Dificultades: Fácil, Medio, Difícil (nombres exactos). Mejores premios al aumentar dificultad. No está aprobado aún un importe concreto de oro.
- Arte primero: no integrar el nuevo juego en la app hasta producir y revisar mascotas, jefe/ataques, enemigos, power-ups y entorno. No confundir hojas de poses con GIF o animaciones temporizadas listas.
- Música: ambiente que crece en suspenso/energía, especialmente en Difícil; mezcla adaptativa y avisos audibles.

## Primera entrega artística guardada
Cuatro hojas individuales de mascota (6 acciones cada una), fondo del bosque, hoja del guardián v1, 12 objetos y 6 enemigos. PNG en art-v1/. Transparencia comprobada en hojas de personaje; hay halos suaves que requieren limpieza por herramienta de imágenes antes de usarlos como atlas pixel-perfect.
Generación: herramienta image_gen integrada. Son conceptos originales y no activos de animación ya aprobados ni código de juego.
