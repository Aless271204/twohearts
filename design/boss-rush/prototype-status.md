# Guardianes del Alba — prototipo jugable, 16 de octubre de 2026

## Abrir
Desde la raíz del repositorio, servir archivos estáticos y abrir
`/assets/runner/guardian/index.html`. Servidor local preparado en puerto58104.
No requiere instalar paquetes para jugar; no tiene dependencias ni CDN.
El APK1.2.3 sigue mostrando Próximamente. Este prototipo está aislado, no cambia
el runner3D, la tienda ni las cuentas.

## Implementado
- Bosque lateral con saltos, tolerancia al borde, salto variable, esquiva y pulso.
- Cuatro mascotas con las seis poses originales, movimiento de presentación,
  enemigos, monedas, recursos en desvíos elevados y campamentos de mejora.
- Fácil, Medio y Difícil. Musgo anuncia onda/hojas, expone sello, y en Difícil
  se retrae completamente, rueda y rebota. Las plataformas altas permiten evitarlo.
- Dos runas: activación coordinada en pareja; ventana mayor en solo para cruzar.
  En Difícil no se puede eludir el sello esperando sin resolver el mecanismo.
- Pareja **local en el mismo teclado**, cámara compartida y límite de separación,
  rescate limitado del compañero. No simula un segundo usuario online ni un bot.
- Victoria/derrota/reintento, pausa, menú, controles táctiles para solo y teclado.
- Música instrumental procedural de cuatro capas sincronizadas y efectos;
  volumen de música/efectos independiente y persistido. Pausa al perder foco.
- Física fija60Hz, máximo5 pasos por cuadro, lienzo lógico960×540 sin elevarlo
  al DPR del teléfono, visibilidad/culling, menos redibujado en menús y pausa.
- Repetición determinista de entradas. Premios provisionales20/30/50 en pareja
  por jugador y10/15/25 en solo, más bonus par por botín, siempre mitad exacta.
  NO se abonan en la tienda: la UI lo indica y no existe llamada de crédito.

## Evidencia
13 pruebas `test/guardian_engine_test.mjs` pasan: semilla, replay, saltos, recursos,
robo recuperable, rescates, caparazón, runas, cámara y expediciones completas en
las tres dificultades, sin salud ni invulnerabilidad añadidas por el controlador.
La simulación con semilla17 completó47/57/78segundos en Fácil/Medio/Difícil.
Esto demuestra viabilidad de esa ruta, no diversión ni equilibrio de todas las semillas.

`scripts/render-guardian-review.mjs` ejecuta el renderizador Canvas real con el
runtime Canvas offline. Capturas en `outputs/guardian-review/`: ruta, aviso,
caparazón, sello y runas. Son renders del motor, no capturas verificadas en móvil
ni inspección de navegador. Los módulos pasan comprobación sintáctica.

## Pendiente antes de incorporar al APK
1. Prueba humana de controles en el navegador/teléfono y ajuste de ritmo/cámara.
2. Ciclos de animación con fotogramas intermedios; ahora son seis poses por acción,
   no carrera/salto completos dibujados cuadro a cuadro. Conservar el arte aprobado.
3. Cooperativo online con sesiones autenticadas y sincronización de entradas,
   reconexión y resolución de desconexiones. Pareja local no satisface ese requisito.
4. Recompensas validadas por servidor: semilla/nonce emitidos al iniciar, tiempo,
   repetición y participantes verificados, abono idempotente y topes compartidos.
   `rewardFor` y `replay` locales son reglas de prueba, no autorización monetaria.
5. Encuentros intermedios y dificultad de pareja: esta entrega cubre ruta y Musgo,
   no una campaña completa con todos los guardianes propuestos.
6. Personalización pixel art requiere sus propios sprites y anclajes por acción;
   no reutilizar modelos3D como pegatinas ni vender cosméticos sin animación válida.

## Dónde editar
`config.js`: dificultades, ruta, recursos, runas, fórmula provisional.
`engine.js`: simulación pura y repetición, sin DOM ni cuenta bancaria.
`render.js`: composición y recortes de las hojas originales, sin cambiar PNG.
`audio.js`: partitura, transporte y efectos. `main.js`: pantallas y entradas.
`style.css`: interfaz. PNG originales conservados en art-v1 y procedencia en manifest.
