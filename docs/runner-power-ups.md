# Power-ups del bosque

Reglas editables: `assets/runner/power-ups.js`. Duraciones: imán 12 s, escudo un golpe o 20 s, monedas dobles 12 s, velocidad doble con protección 5 s y triple salto 15 s. La misma regla va en `supabase/functions/forest-runner/power-ups.js`.

Desde 180 m aparece una cápsula cada doce filas, en un carril libre. Cada recogida renueva la duración sin acumularla. Tres impulsos por vuelo; el suelo reinicia el contador. Pausar congela tiempos. Nueva partida borra todos los efectos.

El HUD debajo del marcador muestra solo efectos activos. No hay botones ni ventanas emergentes. Sprites de 128 px y materiales compartidos; las cápsulas se reciclan.

Replay v6 conserva efectos y saltos entre checkpoints, calcula monedas y colisiones en el servidor. El cliente negocia v6 al iniciar; un servidor anterior usa v5 sin power-ups. Las versiones anteriores siguen compatibles. Se conservan los topes de monedas de 500 por partida y 1000 al día.
