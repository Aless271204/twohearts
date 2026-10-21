# Farolitos: jardín de farolitos · 21 de octubre de 2026

## Referencia y alcance
Las dos láminas de `design/farolitos-lantern-garden/` son conceptos aprobados por el usuario, generados con image_gen. No son capturas del juego. Implementación reproducible en `assets/runner/maze/garden.js`, sin modificar los GLB, texturas, rig ni animaciones originales de las mascotas. Se conserva Three.js y la perspectiva en primera persona.

## Mecánicas implementadas
- Tres estaciones de farolitos sustituyen visualmente a los cofres de llaves en partidas v2. La identidad interna key/keys se conserva para la liquidación existente.
- Iluminar, cerca de la estación y con linterna encendida, revela una combinación que valida el servidor. Una, dos o tres posiciones según dificultad. Girar símbolos y confirmar. Los errores no quitan salud. Una pista revelada es compartida, y otro participante puede resolverla.
- Un puente en la ruta garantizada, placa accesible desde el lado de llegada. Activación de 20 segundos solo / 14 segundos en pareja; permanecer sobre la placa también mantiene el paso en pareja. El primer cruce asegura el puente para todos permanentemente. No obliga a dejar un compañero atrás.
- Cofres con hoja: oro; marcas moradas: travesura de murciélagos 3D y audio existente. Intensidad de sorpresas configurable.
- Tres farolitos abren la puerta; ambos participantes deben llegar vivos en pareja. Revancha y salida conservadas.
- Indicador de avance, nombres de zonas, mapa explorado y brújula hacia la pareja. La brújula muestra dirección, no garantiza una ruta atravesando paredes.

## Arte y rendimiento
Setos redondeados con instancias; adoquines de color variable; luna y estrellas; hojas y luciérnagas; lámparas cálidas sin luces dinámicas individuales; farolitos con grabados revelados; puente y placa; murciélagos animados. Los materiales, mapas y geometrías se liberan al reconstruir la escena. Presupuesto comprobado sobre el generador real: menos de 220 objetos dibujables y 700 mil triángulos en difícil. No equivale a una medición de FPS en un teléfono físico.

## Compatibilidad
Motor cliente/servidor idéntico. Protocolo 2 enviado por el cliente nuevo. Los clientes antiguos pueden seguir creando partidas clásicas v1 y las salas ya iniciadas mantienen sus reglas. No hay migración de tablas ni cambio en el saldo o fórmula de recompensas.

## Evidencia actual
17 pruebas de motor, navegación, arranque y geometría pasan. 72 partidas completas por rutas legales, tres dificultades y ambos modos; 160 casos específicos de puentes y 1500 semillas revisadas con un puente presente. Prueba SQL aislada de dos participantes, autorización, CAS y liquidación única pasa. No representa una prueba manual en dos celulares.
Prueba de flujo completo por los manejadores reales de entrada: movimiento, revelación, rotación de símbolos, tres farolitos, puente asegurado y resultado de victoria pasa.
La función maze-adventure v2 está activa con JWT y validación de usuario conservados. Falta concluir inspección visual Android y publicación web; no se ha generado un APK nuevo.

## Revisión Android
- Run 39666292811: el test no pudo resolver el import dinámico desde JavaScript inyectado; no se aceptó como prueba visual. Se sustituyó por diagnóstico de estado de solo lectura.
- Run 39667726327: escena 3D y diez buffers de sonido cargados; captura `maze_explore.png` real. La imagen mostró iluminación insuficiente. La navegación sintética no abrió el acertijo; se mejoró selección explícita de interacciones y se hace esperar a un paso confirmado en vez de pulsaciones fijas de 80 ms. No se contabilizó como partida Android superada.
- Candidata posterior: luz ambiental cálida, materiales más claros, luna más alta y lejana, botones de acción secundarios cuando coinciden objetivos. Prueba nativa nueva en curso.
