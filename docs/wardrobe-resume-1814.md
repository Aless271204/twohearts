# Punto de continuación: vestuario digital · 11 de octubre de 2026

> ESTADO HISTÓRICO SUPERADO. El usuario rechazó el vestuario de esta entrega
> y pidió reconstruir las prendas desde cero. Para retomar el trabajo leer
> `docs/wardrobe-restart.md` y los últimos mensajes del chat. No regenerar los
> nueve artículos antiguos ni reinstalar el rig R2 en los minijuegos: el usuario
> rechazó su carrera y salto. El recorrido conserva el rig original, con la
> corrección limitada del giro lateral del salto. Las prendas nuevas siguen
> experimentales; deben adaptarse a ese movimiento antes de activarlas.
>
> Auditoría de continuación: 12 de octubre de 2026, 18:38 (America/Bogota).
> No se ha generado ni publicado ningún APK adicional en esta reanudación.

## Entrega verificada · 12 de octubre de 2026

- APK publicado: NIDO 1.1.9+14, 247.399.846 bytes (247,4 MB).
- Código y activos de la app subidos: `2b761703bfb51f58809c34271e7052ce9c0de57a`.
- GitHub Actions 38208862649: verificación, Android y publicación aprobados.
- Descarga: https://github.com/Aless271204/twohearts/releases/download/nido-1.1.9/NIDO-1.1.9-actualizada.apk
- SHA-256: `68c2c3f9df8aaa2ce48aa4dbe194c19989650789ebf702fbc5f6d4c5835337a6`.
- Archivo descargado revisado: versión/código correctos, ZIP íntegro, 96 GLB y
  24 miniaturas con hashes exactos, 38 texturas compartidas idénticas y los siete
  módulos actuales del visor. Firma idéntica al APK 1.1.8 anterior.
- Evidencia en outputs/wardrobe-apk-verification.json y wardrobe-delivery-record.json.
- 13 pruebas locales de carga, encaje y movimiento, 4 pruebas de reparación de
  exportación y auditoría estricta de las 20 superficies de cuerpo aprobadas.
- Miniaturas regeneradas sin bajar resolución ni muestras; 24 procedencias
  comprobadas. Los diez archivos de cuerpo/cuello precedentes quedaron sustituidos.
- Capturas reales actuales: delivery-dulce-front.jpg, delivery-dulce-room.jpg,
  delivery-cozy-running-quarter.jpg, delivery-jardin-running-quarter.jpg,
  delivery-chic-jump-quarter.jpg, delivery-pastel-running-back.jpg, en
  outputs/wardrobe-proof/. El visor quedó disponible en el navegador.

Esta entrega conserva diferencias visuales respecto a la ilustración. Revisar
acabado de cuellos, puños, bordes alrededor de orejas y combinaciones extremas
en teléfono; no certificar identidad exacta ni impresión. Los artículos nuevos
conservan su estado de previsualización, precios y propiedad existente. Peluca,
cuidado/crecimiento sin modelos y cobros/anuncios reales pendientes siguen ocultos
o inactivos. La impresión se trabajará posteriormente.

## Actualización posterior: el usuario pidió continuar e incorporar todo al APK

La pausa descrita más abajo quedó revocada. Se activó la transferencia V3 para
los veinte cuerpos y veinte complementos de cuello: suaviza los pesos de hombro
y unifica las costuras UV sin modificar posiciones, normales ni texturas.
Las 12 pruebas del vestuario actual pasan (outputs/wardrobe-final-runtime-tests.log)
y las 9 pruebas Python pasan (outputs/wardrobe-v3-surface-tests.log).

Se corrigió una causa concreta de los rasgados: la máscara eliminaba un triángulo
completo si solo uno de sus vértices quedaba bajo la manga. Ahora retira únicamente
caras enteramente cubiertas y conserva el borde del brazo. Prueba de regresión
en pet_sleeve_coverage_test.mjs, revisión visible en los cuatro personajes con
el vestido durante salto y el conjunto Dulce frontal.

Se ajustó además el trazado de los accesorios de cuello para excluir los brazos
del contorno del torso y acercar la banda del moño al cuello. Conservar los
maestros, regenerar y verificar sus miniaturas antes del commit de entrega.
El respaldo outputs/wardrobe-v2-delivery-backup conserva el estado anterior,
salvo que su vestido de cerdito ya contiene el candidato V3 probado.

La versión sigue siendo de prueba: no afirmar identidad exacta con la ilustración.
La entrega debe ser APK firmado y descargable; los archivos locales no bastan.

### Reparación estructural y carrera natural

La auditoría de las veinte superficies de cuerpo encontró uniones múltiples en
las mangas y algunos bordes abiertos. `wardrobe_shells.py` repara el volumen con
un remallado de 1,8 mm, suavizado moderado y límite de 12.000 triángulos para la
superficie principal, transfiriendo las UV originales. Adornos y materiales se
conservan. La prueba de sudadera/pollito quedó con cero bordes abiertos y cero
uniones múltiples, y conservó su aspecto en el visor.

Se completó la reparación de las veinte superficies mediante
`blender-repair-wardrobe-shells.py`, sobre el maestro editable, con registro en
`outputs/wardrobe-final-shells.log` (SHELLS_READY). El maestro, los veinte GLB,
las texturas compartidas y los catálogos se guardaron y registraron al finalizar.

La exportación glTF omitía 27 triángulos pequeños (hasta 0,278 mm² por abertura)
y conservaba dos caras internas coincidentes en la sudadera del cerdito.
`wardrobe_export_seams.py` restaura únicamente índices de esas costuras pequeñas,
sin cambiar posiciones, UV, normales, piel ni imágenes. Rechaza huecos mayores de
1 mm² / 3 mm y cualquier unión múltiple restante. La auditoría estricta del
archivo real pasa en las veinte superficies: cero bordes abiertos y cero uniones
múltiples (outputs/wardrobe-topology-audit.json). Esta comprobación digital no
certifica impresión 3D. El intento previo de limpieza numérica en Blender falló
sin guardar y se retiró del generador; no repetir el remallado costoso.

`pet-runner-run.js` conserva la zancada y el ritmo originales, limitando el giro
de hombros, brazos y antebrazos alrededor de la pose de encaje. No modifica el
clip fuente ni los demás movimientos. Su prueba pasa en las cuatro mascotas:
`outputs/wardrobe-natural-run-tests.log`. La carrera real y el visor usan este
clip; las pruebas de vestuario conservan además la carrera original como exigencia.

El visor de tienda ya usa Natural_Rest por defecto en Android y web; Idle_9 se
excluye en todos los visores de mascota. Se retiraron etiquetas antiguas de
versión en mensajes de carga fallida. La página principal del visor usa revisión
wardrobe-rig-9 para cargar el nuevo movimiento.

Pendiente de entrega: pruebas JS actuales tras el cierre de exportación,
miniaturas de las cinco prendas y cinco piezas de cuello, revisión real del
movimiento nuevo, commit/push y compilación firmada en GitHub Actions.
`verify-wardrobe-apk.py` verifica versión, 96 modelos, 24 miniaturas, módulos
empaquetados y misma firma que el APK 1.1.8 anterior.

El usuario pidió detener el perfeccionamiento por hoy, conservar lo logrado y entregar
un APK de prueba aunque queden fallos. La impresión 3D se trabajará después. No
certificar acabado idéntico a la imagen ni productos listos para venta.

## Estado conservado

- 24 artículos visibles con variantes para pingüino, oso, cerdito y pollito: 96 GLB.
  La peluca sigue oculta; los GLB originales de las mascotas permanecen intactos.
- Cabeza: gorra, gorro, sombrero y boina. Cuerpo: camiseta, chaqueta, abrigo,
  vestido y sudadera. También cinco artículos de ojos, cinco de cuello y cinco de patas.
- Cuerpos y complementos del cuello usan la transferencia de pesos V2 comprobada.
  Mangas unidas al torso, bordado de corazón con separación, tejidos con volumen,
  corrección del movimiento del pecho, calzado y ocultación reversible de piel cubierta.
- Se sustituyó el salto deformante del archivo fuente por una pose suave de salto.
- Miniaturas transparentes renderizadas desde el mismo GLB equipado: 24 artículos.
  Procedencia y huellas: assets/images/products/wardrobe-thumbnails.json.
- Texturas idénticas compartidas sin reducir resolución: 96 GLB ocupan 47,04 MiB,
  más 1,82 MiB de texturas compartidas. Esto no es el peso total del APK.
- Los artículos nuevos mantienen preview_only; no activar cobros ni propiedad ficticia.

## Taller y edición

Maestros locales editables (conservados fuera de Git):

- design/blender/fitting/NIDO-patronaje-prendas.blend
- design/blender/fitting/NIDO-complementos-prendas.blend

Catálogos: assets/runner/accessory-catalog.json, blender-wardrobe-models.json y
blender-complement-models.json. Sincronización Flutter: scripts/register-blender-wardrobe.py.
La vista real usa wardrobe-final-review.html, cosmetics.js y los módulos pet-garment-rig.js,
pet-sleeve-coverage.js, pet-footwear-coverage.js y pet-runner-jump.js.

## Pruebas realizadas

- 12 pruebas JS del vestuario, geometría, rig, accesorios, cobertura y salto aprobadas;
  outputs/wardrobe-runtime-tests.log. La última máscara de mangas pasó de nuevo:
  outputs/wardrobe-sleeve-coverage-tests.log.
- 10 pruebas Flutter de inventario y habitación aprobadas:
  outputs/wardrobe-flutter-tests.log.
- 8 pruebas Python de transferencia V2 aprobadas: outputs/wardrobe-surface-tests.log.
- Revisión visual real en reposo, carrera y salto, frontal, tres cuartos y espalda.
  Capturas en outputs/wardrobe-proof/: dulce-running-50.jpg, jardin-jump-25.jpg,
  pastel-running-75.jpg y chic-jump-50.jpg. Algunas capturas preceden el último
  ajuste de máscara; no usarlas como garantía visual de todos los estados finales.

Visor de continuación:
http://127.0.0.1:58104/assets/runner/wardrobe-final-review.html
Elegir conjunto/artículo, vista, movimiento y fase; pulsar «Ver selección».

## Pendientes reales para mañana

1. Bordes angulosos o solapas en puños/hombros de oso, cerdito y pollito durante
   movimiento; el pingüino se adapta mejor. Revisar todas las prendas, sin ocultar
   partes del cuello o mandíbula para tapar un error de encaje.
2. Todavía hay diferencias de silueta y riqueza de materiales frente a la ilustración.
   Revisar cada especie y combinación; no prometer identidad exacta.
3. Validación visual en teléfono y combinaciones extremas de accesorios.

## Historial del experimento en la pausa anterior (superado)

En la pausa anterior scripts/wardrobe_gltf.py contenía una propuesta V3 de suavizado de pesos de hombro,
y blender-refresh-wardrobe-skin.py admite selección por artículo/especie. Solo se
exportó un candidato de dress_petal para cerdito, sin aprobación visual:

- outputs/wardrobe-before-shoulder-smooth/candidate_dress_petal_pig_pattern.glb
- outputs/wardrobe-before-shoulder-smooth/candidate-catalog.json

En aquel momento se restauraron el GLB y el catálogo V2. Tras la petición posterior
de continuar se comparó, activó y verificó V3 para todos los cuerpos y cuellos;
las pruebas actuales esperan V3. Los respaldos V2 permanecen en esa carpeta.

## Entrega de hoy

Versión prevista: NIDO 1.1.9+14, APK de prueba con fallos visuales conocidos.
Compilación, enlace, firma y huella se añadirán al terminar la entrega.

### Continuidad 2026-10-13 — complementos
Ver sección Heartbeat 2026-10-13 de wardrobe-restart.md: nuevos lazos/zapatillas
bear/pig/chick, ocho pruebas de unión rígida aprobadas; capturas reales guardadas.
Queda recorte de pies del cerdito en visor y QA visual completo. No confundir
pruebas de unión con encaje final. Camisetas de otras especies aún pendientes.

### 2026-10-13: seguimiento de movimiento
Ver bloque «Continuación: auditoría y movimiento» en wardrobe-restart.md. 96
exports auditados, pero NO terminados artísticamente. Camiseta de reposo aprobada
restaurada; cage de movimiento guardado como experimento separado. No repetir
ensayos fallidos descritos allí. Próximo: raíz/corona en clips reales antes de
aplicar el patrón al resto. No APK, originales inalterados, peluca oculta.


## 2026-10-13 — revisión de los otros conjuntos, no aprobados
Se construyeron 15 candidatos cosidos para oso/cerdito/pollito (camiseta, denim, abrigo, vestido, sudadera), con maestros COSIDO y variantes sewn_ por especie en catálogo experimental visible=false. Nuevo visor wardrobe-outfit-review.html, originales intactos, carrera/salto de comparación y enlaces de prueba real. Pruebas estructurales pasaron 28; no acreditan acabado artístico. Usuario rechazó cuellos con pestañas y zapatos grandes y exige revisar todos los conjuntos.
Diagnóstico: compresión vertical posterior al cálculo de radios del torso y sisa invertida sobre las filas superiores; cuello independiente y campos de piel diferentes. En corrección: filas físicas uniformes .235-.524, sisa .455±.055, ribete cerrado de sección redondeada que contiene el corte, campos de cuello comunes. La cabeza medida por división Y no es su base real: oso Head>0.9 mínimo .5384. Ajuste oso todavía en comprobación visual; no extender afirmando éxito hasta revisar. No modificar GLB de mascotas.
Zapatillas de prueba: menor holgura lateral/profundidad, suela 34mm en vez de 50mm, empeine según alto real de pata, cordones más apoyados. Oso exportado; resto pendiente.
Máscaras: se ensayó proteger pesos Head>=.40 y produjo penetraciones visibles; se revirtió a .90, no repetir ese cambio. Hood bajada por debajo del cuello para eliminar banda elevada. Diagnóstico static/component en visor, exclusivamente experimental.
Pendiente: cerrar encaje cuello del oso, propagar a restantes prendas/especies, comprobar todas las vistas y fases, revisar otros complementos antiguos, incluir máscaras en paquete nativo antes de activación. No APK/publicación. Últimas capturas demuestran defectos, no versión final.


## 2026-10-14 — tienda, miniaturas y unión del calzado (revisión en curso)

Estado actual que sustituye los pendientes técnicos del bloque anterior:
- Catálogo local único `assets/runner/accessory-catalog.json`: 24 artículos activos,
  cuatro variantes por artículo (96 GLB). `visible`, precios, propiedad y claves
  permanecen estables; la peluca sigue oculta. Las variantes están enlazadas al
  probador y al equipamiento compartido mediante `species_models`.
- 96 miniaturas reales desde esos GLB, 512×448, tres cuartos, suelo de estudio
  cálido y sombra de contacto. Informe `assets/images/products/wardrobe-thumbnails.json`
  con especie, huellas de modelo/PNG y `render_style=warm_studio_v2`. Se verificaron
  las 96 parejas de archivos. Guardado temporal + reemplazo evita bloqueos de PNG
  abiertos en Windows. No sustituir con ilustraciones que difieran del objeto.
- Monturas de estrella: contorno redondeado en un plano óptico estable, lente con
  espesor y patillas siguiendo la cabeza. Collar corazón: contorno del cuello real
  de la camiseta, hilo continuo y dije apoyado en el pecho. Nuevos maestros:
  `COLLAR-GAFAS-ACABADOS.blend` y `CALZADO-COMPLETO-4-MASCOTAS.blend`.
- Sudaderas: capucha cosida por debajo del cuello con ribete continuo. Los estilos
  del pingüino proceden de su camiseta aprobada; ésta y los GLB originales no se
  modificaron. El estado Git de `assets/runner/play-models` continúa limpio.
- Sandalias: plataforma más ancha para los dedos; correas distintas para patas de
  oso/cerdito y dedos de pingüino/pollito. Un muestreo vertical dentro de una pata
  continua encontraba la cara inferior y enterraba las correas. No repetir ese
  método para oso/cerdito. La orientación ORIGINAL de las tapas de la suela era
  correcta: un ensayo de invertirla fue rechazado por pruebas y revertido.
- No usar skinning por vértice en las suelas: produjo picos y deformaciones durante
  movimiento y fue descartado. Todo calzado usa un único anclaje rígido por pata.
  `pet-footwear-anchors.js` toma el campo real de Leg/Foot/Toe y extrae una matriz
  rígida sin escala ni cizallamiento. El actual GLB de sandalia tiene JOINTS de su
  propio Foot, con metadatos de pesos de la pata; el anclaje se aplica en runtime.
- `skin-boundary-clip.js` y `pet-footwear-coverage.js`: se conserva la parte de los
  triángulos que sobresale del borde del zapato, con UV/normales/pesos interpolados.
  Antes se borraba toda una cara por tener un vértice cubierto y se vaciaba el tobillo.
  Se restaura la geometría original al quitar el calzado. Orden de equipamiento:
  los actualizadores de manga y pie ahora se componen, no se sobrescriben.
- El usuario autorizó corregir movimiento manteniendo dinamismo. Las copias
  Wardrobe_Run/Natural_Jump ahora moderan UpLeg, Leg, Foot y Toe suavemente,
  conservando tiempos, traslaciones y variación del ciclo. Esto supera la anterior
  garantía de pistas inferiores idénticas: los CLIPS ORIGINALES y GLB siguen
  intactos, pero sus copias vestidas sí moderan los giros de patas. Se seleccionan
  también al llevar sólo calzado. Revisiones JS: `wardrobe-ankles-7`,
  `ankles-dynamic-6`, `paw-rigid-2`, `ankle-boundary-2`, visor `sewn-ankles-12`.
- Pruebas actuales: 88 Node pasan; 5 pruebas Flutter de inventario pasan.
  Pruebas específicas incluyen visibilidad real de tapas, restauración de tobillo,
  matrices rígidas a través de carrera/salto y equipar ropa antes/después de zapatos.
  Compilación web de producción pasó antes; previsualización compilada de nuevo:
  `build/design-preview`, con entrada `lib/design_preview_main.dart`. Lee el
  catálogo del bundle antes de crear los datos de ejemplo, evitando fallback antiguo.
  Assets finales sincronizados allí. Sin APK, publicación, push ni cambios de cobros.

Visores:
- Tienda: http://127.0.0.1:58104/build/design-preview/?tab=1
- Conjuntos: http://127.0.0.1:58104/assets/runner/wardrobe-outfit-review.html
- Miniaturas por mascota/categoría: http://127.0.0.1:58104/assets/runner/wardrobe-thumbnail-review.html

Evidencia real en `design/wardrobe-restart/`: `sandals-surface-final-*.png`,
`shoes-rigid-paw-jump-bottom.png`, `pastel-ankles-soft-run-*.png` y capturas siguientes.
IMPORTANTE: algunas de esas capturas preceden el último control de muslo/tobillo;
no usarlas como prueba del movimiento más reciente. Las pruebas estructurales no
certifican que todo esté idéntico a la ilustración o artísticamente terminado.

Siguiente revisión concreta: comprobar el último ciclo en los cinco calzados y
cuatro mascotas de perfil/espalda, especialmente contacto de sandalias con patas
expuestas. Quedan siluetas y separaciones que deben valorarse visualmente; no activar
productos pendientes de aprobación ni certificar perfección. Revisar luego bordes
traseros de bufanda/pañuelo y todos los accesorios individuales. No repetir el ensayo
fallido de pesos por vértice ni modificar la identidad de las mascotas.

Para edición manual: cambiar visibilidad/nombre/precio en el catálogo JSON; cambiar
patrones y maestros para geometría; ejecutar `sync-sewn-accessory-catalog.py` para
actualizar Dart y huellas, y volver a fotografiar sólo los modelos modificados.


### Evidencia posterior: calzado en el último salto
Capturas `dulce-ankles-final-jump-top.png` y `dulce-ankles-final-jump-bottom.png`
corresponden a Natural_Jump .5, 40 grados, cuatro originales con conjunto Dulce,
tras moderar también UpLeg/Leg. La silueta de las zapatillas permanece coherente;
la revisión de pequeños contactos de cuello/axila sigue abierta, no certificar
igualdad con la ilustración. Última suite completa: 88/88, registro
`outputs/wardrobe-accessories-final-checks.log`. Los clips copiados conservan
los tiempos y una zancada alternante, pero ya NO las rotaciones inferiores exactas.


### 2026-10-14 — Moño Dulce a la altura del cuello
Pedido más reciente: el «smokin»/moño elegante debe ir sobre el cuello, no en el pecho.
Se corrigieron los cuatro restart_bow_neck_{species}.glb: altura y cinta derivadas
 del Cuello real de sewn_shirt_love, y contacto frontal calculado sobre el mentón
 original. Inclinación suave mantiene espesor de las lazadas. No se tocaron GLB de
 mascotas ni otros artículos. Maestros separados LAZO-CUELLO-{species}.blend;
 scripts/blender-restart-details.py admite --items bow_neck para evitar regenerar zapatos.
Catálogo y cuatro miniaturas reales sincronizados; SHA modelo/PNG verificados;
assets copiados al probador web existente. Pruebas de anclaje 24/24.
Capturas reales bow-collar-rest-top/bottom.png, bow-collar-jump-top/bottom.png:
frente en reposo, tres cuartos Natural_Jump .5. Carrera comprobada visualmente
 en pingüino/oso; no certificar todas las fases o prendas como finales. Persiste
 revisión artística de siluetas, contactos de axila, calzado y detalles anteriores.
El cambio del probador pet ampliado en inventory_screen.dart está guardado, pero
 su compilación anterior no se ejecutó tras analyze (info anonKey depreciado).
 No confundir ese cambio de interfaz con el probador web compilado existente.
Sin APK ni publicación. Continuar desde esta nota sin repetir el ajuste de altura.

### Continuación 2026-10-14: estado actualizado
Leer el último bloque «anatomía, personalización y entrega solicitada» de
`docs/wardrobe-restart.md`; sustituye este estado anterior. Se conserva el cuello
original, hay120 capturas reales de revisión y tintes, habitación/cofre y economía
implementados. El usuario pidió expresamente APK: compilación en GitHub autorizada,
con anuncios de prueba y pagos desactivados. No prometer todos los ajustes finales;
el hombro del pollito muestra piel que todavía debe cubrir el patrón. Registrar
el APK verificado y el resultado de Android antes de entregar su QR.

Entrega posterior verificada: NIDO1.2.0+15, commit96673d7, ejecución38627026593
correcta incluyendo Android offline. APK yQR están enoutputs; enlace ySHA en el
último bloque dewardrobe-restart.md. Peso547MB: incluye96 prendas actuales y96
anteriores para referencia. Mantener pendientes artísticos y monetización de
producción explícitos; no interpretar el APK de prueba como aprobación de todos
los artículos. Continuar con hombro del pollito y revisión de contactos móviles.
## Entrega acotada 1.2.1 — 2026-10-14
El usuario pidió ahorrar créditos y publicar únicamente recorrido, música y home. Commit 005b556. CI 38659138046. Supabase forest-runner versión 8 desplegada con JWT obligatorio: semillas derivadas de sesión, compatibilidad previa conservada. Pruebas locales 18 casos exitosos. Cambios textiles, selección de mascotas y optimización de assets permanecen locales, fuera de esta entrega. No considerar terminado el vestuario. El APK aún compila; comprobar firma y seis módulos JS contra este commit antes de entregar. No publicar en tiendas como listo para cobros: falta configuración de las cuentas y billing.

Entrega 1.2.1: corrida CI 38660699207 completada con éxito. Android smoke corregido con semilla de prueba 7; producción mantiene aleatoriedad. Instalación, recogida de monedas, sonido, pausa/reanudación y colisión pasan. APK publicado firmado: https://github.com/Aless271204/twohearts/releases/download/nido-1.2.1/NIDO-1.2.1-aventura.apk . Cambios de vestuario locales fuera de este APK.

## 1.2.2 — cambios de hogar, conexión y tamaño
- Usuario confirmó resuelto el arranque en Pixel 6. No cambiar arranque ni mascotas originales.
- Decorar: división animada 50/50, habitación arriba y panel claro abajo, categorías y equipamiento real; compras con confirmación.
- Código de pareja visible desde Nido y Perfil, flujo RPC existente. Foto con PNG sin metadatos y bucket privado; acceso propio/pareja con URL temporal.
- Ubicación de ambos en primer plano: permisos individuales, instantánea privada cada 8 s y GPS cada 15 m/30 s. Desactivar conserva el último punto; fuera de primer plano no rastrea. Prueba SQL rollback pasó lectura por pareja y rechazo de tercero.
- Mismos ping pong y preguntas: pareja, sala por código, aleatorio y práctica local sin oro. Nube tiene reacción limitada y no lee respuestas. Música original ligera y efectos para todos esos modos.
- Ocho retratos reales de las cuatro mascotas con atuendos masculino/femenino, elegibles en Perfil. No cambian anatomía ni mascota seleccionada.
- 96 miniaturas renderizadas de GLB reales en estudio blanco, con leve animación de tarjeta respetando reducir movimiento.
- 96 GLB optimizados comparten 43 texturas con bytes idénticos; auditoría de geometría, materiales, nodos, animaciones y texturas pasó. Históricos quedan en código pero fuera del APK.
- No incorporar los experimentos locales de hombro ni la modificación local del movimiento. Están fuera de esta entrega.
- Flutter: 22 pruebas de nuevas funciones y 3 del bot aprobadas. SQL online y retratos con dos cuentas y rechazo de tercero aprobado. Pendiente confirmar compilación Android y pruebas visuales de esta versión.

Correcciones posteriores: el Stack de habitación se encogía a 52 px; se forzó expansión y una prueba real mide viewport y ambas mitades, conservando el mismo elemento de escena. Captura real: outputs/room-split-preview.png. Se añadió desactivación local persistente de GPS para no volver a publicar si falla la red o se reinicia. Cinco pruebas de ubicación/panel aprobadas. Primer CI falló por Maven 429, no por código; se añadió caché Gradle y un único reintento con espera. No reincorporar cambios locales de vestuario/movimiento.

## Entrega confirmada 1.2.2+17
- Commit publicado: 268a07c. CI 38766607551: verify, android-smoke y publicación exitosos.
- APK firmado: https://github.com/Aless271204/twohearts/releases/download/nido-1.2.2/NIDO-1.2.2-ligera.apk
- Peso real 219.294.643 bytes frente a 546.936.067 de 1.2.1: reducción del 59,9 %.
- SHA256 ec3d1e22f468964b90b0555f27c9df914a5252b24fbb9595cb2d0c142bb53f95. Firma anterior conservada 6991bdb5af84789e9770c5cbe43b6bd0e9aec9a2d0a8c0947c1b8ee79cf908a5.
- Verificador examinó los 96 modelos, 96 miniaturas, imágenes compartidas, código de render y manifiesto del APK descargado.
- QR: outputs/nido-1.2.2-qr.png. Capturas reales: room-split-preview.png; training-pong-browser.png y training-quiz-browser.png (las dos últimas previas a los botones finales de audio y salida en cabecera).
- Ubicación solo en primer plano; comparte con pareja recíproca y conserva el último punto. Fotos privadas (propietario/pareja), no públicas.
- Versión de prueba para amigos: cobros y publicación oficial en las tiendas siguen pendientes. Notas de auditoría previa en outputs/new-features-security-notes.md. No afirmar cumplimiento absoluto de seguridad/producción.


## 2026-10-15 — habitación como pestaña y catálogo disponible
- PetRoomScreen conserva las cinco pestañas y elimina la X de salida. No hay una ruta adicional para entrar en la habitación. AppScaffold conserva barra en Mascota incluso ante notificaciones de navegación internas; juegos continúan inmersivos.
- Cofre y decoración ocupan la mitad inferior dentro de la misma pantalla, transición 360 ms con reducir movimiento respetado. Escena no se recrea al abrir/cerrar. Iconos laterales izquierdos en oro, lavanda y salvia.
- 96 fotografías de los GLB reales renderizadas de nuevo en Blender sin fondo; PNG RGBA con alpha y hashes comprobados. Tarjetas con oscilación y escala más visibles; reducir movimiento desactiva la animación.
- Rotación del calzado en runtime conserva el giro completo del anclaje, sin el límite que causaba retraso respecto a la pata. 11 pruebas de anclajes/orden y 25 pruebas de catálogo/cuerpos/complementos aprobaron. No se reincorporaron cambios experimentales de hombro ni salto.
- 24 productos visibles habilitados para comprar/equipar con oro en catálogo local y servidor; peluca continúa oculta. Migración publish_tailored_pet_catalog aplicada. Prueba SQL con cuenta temporal: 24 compras, equipamiento y descuento correcto; rollback sin datos de prueba persistentes.
- 10 pruebas Flutter de inventario, habitación y ubicación aprobaron. Web preview compilado en build/design-preview. Activos actualizados posteriormente. La herramienta de navegador rechazó la inspección: no se certifica una revisión visual completa en minijuegos ni perfección artística.
- No se generó APK nuevo; la versión instalada 1.2.2 no incluye estos cambios de UI hasta la siguiente compilación.


## Pausa de diagnóstico: ropa en carrera, nueva idea de Boss Rush
- Usuario reporta camiseta del oso que no sigue al cuerpo; no está resuelto visualmente.
- Nuevo diagnóstico scripts/check-garment-follow.mjs compara desplazamientos de 20 combinaciones. Ajuste actual rígido del torso difiere del movimiento de la superficie original. La métrica usa vértice cercano, no es criterio artístico absoluto.
- Prueba de transferencia de pesos en scripts/blender-transfer-garment-motion.py y helper pet-garment-binding.js guardados como experimentales. Mejora parcial numérica; no verificada visualmente. NO publicar ni certificar como solución.
- Se restauró el GLB del oso desde before-motion-transfer y se retiró el enlace experimental de cosmetics.js. Catálogo/hashes activos conservados.
- Usuario dirige ahora una propuesta de nuevo minijuego 2D pixel art Boss Rush: imágenes, historia y mecánicas antes de implementar.

### Retomar después de entrega 1.2.3
Leer docs/release-123.md antes de volver a modificar prendas. Código de entrega ff40893; nueva vinculación al skin original y APK separadas por arquitectura. Hay experimentos antiguos sin commit en scripts/blender-sewn-shirt.py, scripts/wardrobe_gltf.py y test/pet_wardrobe_jump_test.mjs: NO incorporarlos automáticamente. Guardianes tiene arte y prototipo aislado sin publicar; el APK solo lleva tarjeta Próximamente. Instrucción más reciente humana: optimizar y compartir APK con amigos. La impresión sigue aplazada.


## Continuación automática 2026-10-17: evitar regresiones tras 1.2.8
- Entrega vigente: NIDO 1.2.8+23, commit21edbe65598e6b3d65cec272d1d00a93a18e2916. Ver docs/release-128.md. No rehacer entregas antiguas ni el diagnóstico de vinculación ya resuelto en1.2.3.
- Las 24 miniaturas boutique y el sillón ya se generaron, revisaron e incorporaron. Son ilustraciones de presentación; no equivalen a cambios de malla ni cierran los pendientes artísticos. Maestros locales en design/store-boutique, mapa lib/core/boutique_thumbnails.dart y procedimiento docs/store-boutique.md.
- No se alteraron prendas ni mascotas en esta revisión automática: los activos de ropa siguen siendo los verificados en la entrega actual. No volver a aplicar experimentos locales antiguos.
- Pendientes artísticos que deben revisarse con evidencia nueva antes de tocar geometría: hombro del pollito, bajo/entrepierna de cerdito, abertura superior de boina de pingüino y orientación de sandalias, documentados en release-123. No presentar las métricas técnicas como aprobación visual.
- La preferencia de movimiento dejó de estar pendiente: el usuario autorizó una prueba dinámica; respetar lo publicado y sus mensajes posteriores. La automatización se actualizó para leer las entregas actuales y evitar trabajo repetido.
- Siguiente: inspección focalizada de una de esas zonas sobre el estado actual en un visor experimental. Si sigue bloqueada la inspección de navegador, no eludirla; los renders offline deben identificarse como tales. No publicar nuevos APK desde el heartbeat.

## Revisión focalizada de boina —18octubre, candidata v5

Se confirmó una abertura grande en la parte superior de la boina de pingüino mediante geometría posada con las funciones reales de equipamiento y render offline. El patrón anterior aplastaba la corona antes de recortar la cabeza y dejaba el centro abierto. scripts/blender-fit-beret-v5.py construye una corona cerrada con forro de9mm y banda continua, conservando el material y recolocando corazón/rabito sobre la superficie. No modifica la mascota original.

Maestro y procedencia: design/wardrobe-restart/experiments/beret-fit-v5/penguin.blend y penguin.json. Candidata NO incorporada al catálogo: assets/runner/accessories/experimental_beret_chic_penguin_v5.glb. Vista tres cuartos en outputs/beret-review/penguin-Rest-0-after-40.png; es Blender, no el renderizador de la app, y su material aparece más pálido. La corona está cerrada; todavía requiere frente/perfil/espalda y carrera/salto antes de activar o extender a otras especies. No reincorporar experimentos antiguos ni presentar el conjunto del vestuario como final.

## 2026-10-21: proporción pequeña y forma de boina
- El usuario reiteró que la boina debe ser menor que la cabeza. V8 cerró la abertura y redujo la copa; sus renders offline están en outputs/beret-review/small-fit-8.
- El usuario rechazó expresamente la forma lisa de v8: parece un gorro religioso. No activar ni recuperar ese diseño como terminado. Pidió relieve y formas onduladas, conservando el tamaño pequeño.
- V9 experimental: copa asimétrica ladeada, volumen superior y pliegues de fieltro que se extinguen en una banda estrecha. Generador scripts/blender-fit-beret-v9.py. Primero pingüino, sin tocar las mascotas originales. Renders offline en outputs/beret-review/small-fit-9, pendientes de inspección al guardar esta nota.
- Las pruebas nativas de v8 se cancelaron por quedar superadas por esta corrección artística; no son aprobación de v9. Comprobar el diseño nuevo en el renderizador real y movimiento antes de activar.
- Tienda: once imágenes completas WebP guardadas y carrusel corregido, prueba de ocho habitaciones ida/vuelta sin errores. Commit de publicación fd2c5306414459a0491a80cda34b545fc11f3b5a; confirmar despliegue antes de anunciarlo disponible.

- V9: frente y perfil del pingüino inspeccionados; también contacto frontal de las cuatro mascotas en outputs/beret-review/small-fit-9/all-Rest-0-after-0.png (Blender offline). Copa ladeada y ondulada; banda interior al ancho del cráneo. Prueba test/small_beret_test.mjs pasó: cuatro especies, anchura inferior al 82% del perfil de cráneo y anclaje estable al hueso original durante 45 muestras de carrera y salto.
- Prueba nativa v9: commit c648c5102d2388817c3503978b858c756f0409bc, run39629426173. El visor Android aislado usa los mismos assets y JS del renderizador de la app; no es la app completa ni una captura de navegador de Windows. Esperar capturas, no convertir un test geométrico en aprobación visual.
- Tienda publicada y comprobada: run39627883369 SUCCESS, once WebP públicos con hashes idénticos a los locales; recibo outputs/store-previews-20261021/web-verification.json. Las cuatro pruebas de Flutter de carrusel/escena/economía pasaron. La boina v9 todavía no está activada al escribir esta nota.

- Cierre de boina v9: veinte capturas nativas válidas revisadas; las tomas de carrera que mostraban carga quedaron excluidas. Runs39629426173 (reposo/perfil/espalda/salto),39631697533 (carrera de oso/cerdito/pollito),39634660827 (carrera de pingüino). Recibo completo design/wardrobe-restart/experiments/beret-fit-v9/native-validation.json. El visor estático necesitaba doce dibujados antes de congelarse para completar la transición de visibilidad; no se cambiaron las animaciones jugables.
- Se aplicó la copa pequeña, ladeada y ondulada en los cuatro archivos activos de boina, manteniendo los mismos nombres de recurso y actualizando hashes/revisión. Materiales/fuentes antiguos archivados en design/wardrobe-restart/experiments/beret-fit-v9/sources; maestros .blend individuales en el mismo directorio superior. No recuperar v8 lisa rechazada. Las mascotas originales conservan exactamente sus bytes.
- Pruebas geométricas y eventos por kilómetro: tres aprobadas. Continuar con los otros pendientes artísticos documentados, sin rehacer esta boina como si siguiera abierta. Publicación web de este cierre todavía pendiente al escribir la nota.
