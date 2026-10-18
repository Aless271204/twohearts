# Trabajo autorizado — 2026-10-17 (continuación activa)

Base publicada: NIDO 1.2.8+23 /21edbe6. No perder el alcance cuando llegan mensajes adicionales.

## Solicitudes activas
1. Registro sin mascota; adoptar solamente después de enlazar pareja recíproca. Cuatro mascotas base en3D en pestaña Mascota, presentadas como cachorros separados de originales. Storyboard aprobado en design/adoption/seagull-arrival-storyboard.png. Tras adoptar, video de gaviota llevando mascota, nido, crecimiento y habitación compartida. Persistir primero; no duplicar al cerrar durante video. Preservar mascotas/compras existentes.
2. Oro en los cinco juegos: runner, Guardianes, ping pong, adivinar y pintar. Todo validado en servidor, idempotente; diagnóstico del fallo de Guardianes pendiente de cierre. Práctica no debe permitir declarar premios localmente.
3. Oro compartido: sumar saldos al enlazar, mismo saldo y gasto para ambos. Al separar, CADA UNO recibe10% del saldo compartido y el resto se pierde. Respuesta humana explícita. Confirmación de desvinculación debe mostrar cantidades. No borrar saldos de cuentas existentes durante migración.
4. Guardianes difícil: una prenda aleatoria de alrededor de50 oro, no poseída, al vencer al jefe final, una vez por victoria/partida, sin duplicar al reintentar guardado. Evitar atajo de quedarse disparando desde escalón: ataques altos telegrafiados o escalón reducido. Mantener kernel cliente/servidor idénticos y dificultad fácil/medio intacta.
5. Ping pong: power-ups con efectos temporales, reglas del servidor y modo práctica coherente. Adivinar: animaciones de fases, elección y revelación, música/sonidos y controles legibles.
6. Pintar: referencia misteriosa, oculta en preparación; revelada al entrar a partida y cronómetro de5min iniciado con revelación/carga de ambos. No filtrar referencia en respuesta de sala en espera. Recompensa moderada por completar legítimamente, no según un puntaje manipulable del cliente.
7. Recordatorios de actividades y avisos del ánimo compartido; preferencias y privacidad. Frase diaria aleatoria por pareja, misma para ambos ese día, citas verificadas con autor y obra (libros, poemas, versículos y citas breves de cine/series). No inventar atribuciones.
8. Correr con mascota: ropa debe seguir cuerpo y extremidades. Más velocidad desde comienzo. A1,5km lluvia/oscuridad y tramos con suelo que cae; a2km tormenta total y rayos. Suavidad, rendimiento móvil, reduce movimiento, reglas deterministas compatibles con validación de premios.

## Investigación completada
- Registro actualmente llama pet_family_change(choose) y snapshot crea mascota provisional antes de adoptar; falta cambiar también servidor, no soloUI.
- Supabase conectado: nbldsimuntfeeynaadak. Definiciones reales guardadas en outputs/economy-before.sql; no son datos de usuarios. Migración vacía creada conCLI:20261017225009_shared_wallet_game_rewards_and_mystery_art.sql.
- Cartera actual: saldos individuales en game_stats.love_coins. Diseño propuesto no destructivo: saldo compartido como suma de subcuentas mientras enlace recíproco; gasto atómico con bloqueos ordenados de ambos; no duplicar saldo almacenándolo dos veces. Compras/tintes/adopción deben usar mismo débito; UI de stats también debe leer suma.
- GuardianBridge.finish no refresca inventario tras abono; investigar además errores reales de validación. No asegurar que esto sea la única causa.
- Pintar hoy muestra referencia antes de partida y RPC inicia plazo al marcar listos; necesita fase de revelación/carga.
- VideoAI: cotización sin generar: Seedance2.5,8s cuesta56créditos; cuentaHiggsfield10. No se compró ni activó prueba. Buscar alternativa local gratuita adecuada antes de requerir créditos al usuario; no fingir que storyboard sea video animado.

## Estado
Implementación en integración y revisión. No afirmar que el lote esté incluido en APK1.2.8. Mantener los cambios de miniaturas boutique ya aprobados. Los scripts textiles viejos sin commit son experimentos, no incorporarlos automáticamente.

## Continuación verificada (17 de octubre; host UTC ya 18)
- Tres migraciones instaladas: cartera compartida y reparto confirmado 10 % por persona; premios idempotentes de pintura/Guardianes; lobby Listo/Iniciar; power-ups de pong; adopción posterior al enlace; aniversario compartido y ánimo opcional.
- Prueba local PostgreSQL/PGlite con usuarios sintéticos pasa: gastos, saldo insuficiente, confirmación obsoleta, permisos anónimos, revelación de referencia/carga/cronómetro, premio único, adopción única, recibo de llegada y compatibilidad de pong antiguo. No se usaron cuentas reales para estas pruebas.
- Guardianes Edge activa v6: nuevos ataques altos en difícil; mantiene motor anterior para clientes existentes. Runner Edge activa v9: acepta protocolo8 solicitado por nuevo cliente, mantiene7 para APK anterior. Replays/efectos/recorrido:12 pruebas pasan.
- Bienvenida 3D local: gaviota procedural, llegada y crecimiento con GLB original a escala pequeña; recibo persistente por usuario. Es una cinemática en tiempo real, no un video MP4 ni nuevas mallas de cachorro. Vista de galería y final de llegada revisadas en navegador.
- Registro ya no crea ni pide mascota; formulario obsoleto de selección eliminado.
- Home: indicadores, frase, pedacito del día, mapa y álbumes; enlace en ajustes. Indicadores usan fechas calendario y última posición consentida; no inventan1día ni0km.
- Recordatorios locales Android/iOS y ánimo opcional. Android: avisos en segundo plano mediante actualización existente del widget, no notificación push instantánea. iOS sin compilación/firma; no hay APNs en esta entrega.
- Compilación web completa correcta (376,5s). Cambios menores posteriores en formulario/citas/cartera requieren análisis final. Android/iOS aún sin nueva compilación.

### Corrección concreta de ropa en carrera
- Causa comprobada: pesos copiados de la superficie asignaban muslos/pies/cabeza al bajo de la camiseta. En oso a fase75 % aparecían tiras dentadas bajo la manga.
- scripts/fix-torso-weights.py corrige20GLB (5 prendas×4 mascotas): muslos/pies a cadera, influencia de cabeza limitada al cuello y brazos reservados para mangas.
- scripts/smooth-garment-weight-field.py crea campo común de pesos con interpolación espacial para suavizar uniones de tela y bordillos; horneado en exportación, sin cálculo por fotograma.
- Originales de prendas guardados en outputs/cloth-weight-backups; mascotas originales sin cambios. scripts/check-torso-weight-preservation.py confirma geometría, índices, UV, normales, imágenes/materiales idénticos (antes del último suavizado; repetir tras él).
- Catálogos y huellas sincronizados con scripts/sync-motion-binding-metadata.py, también catálogo Dart. Pruebas de20exportaciones y8clips pasan.
- Carrera usa delta real del ciclo de brazos sobre descanso natural: evita que el límite angular consuma todo el movimiento en una compensación constante. El oso a fases25/75 y perfil fue revisado visualmente; ya no presenta tiras colgantes en el bajo.
- Vista conjunta de cuatro camisetas revisada a75 %, tres cuartos. Aún hay pequeños quiebres en sisa del pollito y pingüino; el suavizado los reduce pero NO se certifica acabado final ni igualdad con referencia. Continuar revisión de las20variantes desde otros ángulos, salto y movimiento continuo antes de empaquetar.
- Visor actual: /assets/runner/wardrobe-outfit-review.html (sudadera, espalda, carrera75 %, cuatro mascotas). No repetir búsquedas iniciales ni el suavizado costoso en runtime rechazado: el archivo temporal fue retirado.
- Análisis final de6archivos: sin errores ni advertencias;12avisos de estilo por llaves opcionales. Preservación repetida tras suavizado:20/20correctas. Nuevas huellas sincronizadas.
- Diagnóstico adicional: sudadera del pollito presenta mal acabado de hombros TAMBIÉN en reposo, no solamente en carrera. Vista estática `static=1&component=cloth&species=chick&item=hoodie_nido&angle=180` revela zonas de piel por encima de la manga principal. Hay que corregir patronaje de esa unión en Blender, no seguir cambiando límites de animación para ocultarla. Ocultar el forro auxiliar no lo resolvió; ese experimento fue revertido. Sudaderas de las otras tres especies tienen espalda continua a fases0/75en estas capturas.
- Visor conservado para próxima revisión: cuatro camisetas, tres cuartos, Wardrobe_Run25 %. No hay nuevo APK ni publicación del código de este lote todavía.
- Punto local guardado636affe. Se añadió disparador de CI para rama de integración (sin publicación), pero el comando commit/push no se ejecutó: revisión automática rechazó subir nuevo lote público sin autorización específica. Pregunta async pendiente del usuario; NO repetir push ni usar otra herramienta hasta recibir aprobación.
- Prueba de ajuste localizado del hombro de pollito creada con Blender: scripts/blender-chick-shoulder-fit.py y maestro CHICK-SHOULDER-shirt_love.blend. El visor se bloqueó antes de poder comprobar esa forma. Se retiró del activo y quedó en design/wardrobe-restart/experiments/chick-shoulder-fit-1.glb. El GLB activo fue restaurado desde outputs/before-chick-shoulder-fit y sus hashes sincronizados. Script ahora genera experimento por defecto; --apply solo después de verificarlo visualmente.
- Prueba técnica adicional:24/24 de skin original y20exportaciones, incluida prueba experimental, pasan. Esto NO valida su acabado artístico. El kernel CUA se reinició al cerrar pestañas y abrir una nueva; usar inventario antes de continuar, no asumir handles antiguos vivos.
- Usuario autorizó explícitamente «subelo para usar en android». Se puede subir este lote a la rama pública de integración y compilar Android. Añadió «pero si funciona incluyelo»: incluir ajuste experimental solo tras comprobar reposo/carrera/salto. Versión de preparación1.2.9+24.

## Guardianes: patas en movimiento
- Causa: una sola pose de carrera; disparar seleccionaba otra pose igualmente estática.
- Añadido ciclo de ocho fases en el compositor final, con desplazamiento alternado creciente desde tobillo a punta; incluye el calzado equipado. Se aplica avanzando tanto corriendo como disparando; no se activa quieto, saltando o derrotado.
- Caché acotada a32 imágenes para evitar generar lienzos cada fotograma.
- Pruebas: scripts/check-guardian-gait.mjs verifica las cuatro especies, descalzas y con los cinco calzados, poses correr/disparar; torso idéntico e inmovilidad en reposo. test/guardian_wardrobe_test.mjs:4/4.
- Evidencia: outputs/guardian-gait/contact.png, render con Canvas nativo del compositor real; no es captura de dispositivo. Falta comprobar en celular y empaquetar en próximo APK.
