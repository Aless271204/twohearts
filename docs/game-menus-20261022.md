# Menús y estabilidad · 22 de octubre de 2026

- Farolitos no figura en GameHubScreen. Su ciudad sigue como experimento privado; no se añade a esta publicación.
- Ping pong sustituye a Peloteo con amor en catálogo, partida, ranking y guía.
- Los menús usan verde bosque, crema y oro. Nieve muestra retratos y tres escenarios ilustrados; sus tarjetas eligen el escenario de entrenamiento (las salas online mantienen la selección del servidor).
- Se corrigieron dos gradientes de proyectiles/escudos sin variable declarada que interrumpían el bucle de nieve. Prueba del render con proyectil especial, escudo y rescate; partida completa de un minuto comprobada en el navegador integrado.
- Música original de nieve a 144 BPM con bajo, campanas y percusión; no se cambia el audio de otros juegos.
- El Río de Guardianes exige una victoria del Bosque en Difícil y en pareja. Se reutiliza el recibo privado de premio de victoria, incluso sin prenda disponible; ambas cuentas conservan el acceso. Un cliente no puede concederse el desbloqueo. El servidor comprueba crear/unirse y el menú muestra el candado. Victorias anteriores válidas cuentan.
- Se retira el service worker antiguo del ámbito de esta aplicación para evitar la interfaz anterior. No se eliminan cuentas, preferencias ni partidas guardadas.

## Verificación

- 10 pruebas de nieve: simulación, cuatro jugadores, cuenta atrás, un minuto, power-ups, rescate y render.
- Prueba SQL aislada: victoria válida, negativa en solitario/fácil/medio/derrota, acceso de ambos, rechazo a terceros y a crear/unirse sin desbloqueo.
- Comprobación en la base activa: perfil actualizado, guardas instaladas y sin permiso directo para conceder/consultar progreso ajeno.
- 12 pruebas de bienvenida, noticias, ranking y social; dos pruebas de los nuevos menús en teléfono.
- Revisión visual local en el navegador integrado. No se certifica rendimiento en todos los dispositivos Android con esta comprobación web.

El pañuelo salvia requiere todavía una nueva pieza textil y revisión 3D antes de activarlo. No se sustituye la geometría de ninguna mascota en este cambio.
