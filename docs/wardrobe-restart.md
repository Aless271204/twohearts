# Reinicio artístico del vestuario digital

## Decisión del usuario · 12 de octubre de 2026

El usuario rechazó el acabado del vestuario y las animaciones de carrera y salto
de la versión 1.1.9. Las verificaciones técnicas anteriores no constituyen
aprobación visual. Se cancela la estrategia de seguir puliendo esas prendas.

La versión anterior se conserva: commit
`9ce32073cc47dfa6ee43f083ce5d5594e0e28b3c`, modelos originales en
`assets/models/` y maestros anteriores en `design/blender/fitting/`.
No eliminar ni sobrescribir esos originales para esta nueva propuesta.

## Orden del trabajo

1. Una mascota a la vez, empezando por el pingüino.
2. Presentar una imagen del conjunto completo, conservando identidad y facciones.
3. Tras validar la dirección visual, presentar cada prenda individualmente.
4. Crear nuevas prendas en Blender a partir de esas referencias, en archivos
   separados de los anteriores.
5. Revisar y reconstruir rig, pesos y texturas donde sea necesario, conservando
   estilo artístico. Probar primero reposo, carrera y salto del personaje.
6. Verificar el conjunto real desde varios ángulos y durante movimiento antes
   de incorporarlo a habitación y minijuegos.

La prioridad es ternura, volumen, materiales cuidados y un encaje orgánico.
No certificar identidad exacta con la imagen ni un resultado final a partir
de pruebas automáticas. La impresión 3D queda aplazada; la peluca permanece
oculta. Esta nota no cambia productos, compras ni modelos activos de la app.

## Primera propuesta

Pingüino con conjunto Dulce: gorra coral con corazón, camiseta crema con corazón
bordado, lazo coral y zapatillas coral/crema. La referencia del personaje es
`assets/images/pets/penguin.png`; la referencia de acabado es
`design/penguin-outfits-approved.png`.

Referencia creada con la herramienta integrada de generación de imágenes:
`design/wardrobe-restart/penguin-dulce-reference-v1.png`.
Muestra frente, tres cuartos y espalda del conjunto completo.

El usuario aprobó la dirección y pidió imágenes individuales antes de modelar.
Los cuatro PNG ya están guardados en esta carpeta: `cap-coral-reference-v1.png`,
`shirt-ivory-reference-v1.png`, `bow-coral-reference-v1.png` y
`sneakers-heart-reference-v1.png`. Son referencias artísticas, no capturas de GLB.

## Herramientas gratuitas y nuevo prototipo

Blender 4.5.9 LTS está disponible. Material Maker 1.7 se descargó desde el
repositorio oficial enlazado por su web, con SHA-256 verificado:
`deb4416bc939861d48097a866a8b2bf0363c29ff64874f2e04478658ff900808`.
Está en `.tools/material-maker-1.7/material_maker_1_7_windows/material_maker.exe`.
Krita no se instaló: el instalador devolvió cancelación de Windows (0x800704c7).
Substance Painter y Marvelous Designer no están instalados; no se activó ningún
pago ni prueba con cobro. El usuario pidió alternativas gratuitas y autorizó
seguir mientras duerme y retomar mañana si se termina la cuota.

Nuevo generador: `scripts/blender-restart-wardrobe.py`. Crea una gorra de algodón
con copa redondeada, espesor, visera curva, doble pespunte y corazón volumétrico.
Exporta variantes independientes y un rig cartoon nuevo de siete controles con
reposo, carrera y salto. Conserva las superficies y texturas de las mascotas.
Los maestros `.blend` están en `design/wardrobe-restart/models/`; los GLB en
`assets/runner/restart/`. No están activos en tienda ni en juegos.

Visor: `assets/runner/wardrobe-restart-review.html`, puerto local 58104. Usa los
GLB reales; la referencia artística está debajo para comparación. No usa las
prendas rechazadas. El catálogo experimental tiene `visible: false`.

Prueba inicial detectó texturas con UV vertical invertida tras pasar de glTF a
Blender. Se corrigió con `(u, 1-v)` y se comprobó visualmente en el pingüino:
la cara y el pecho vuelven a estar intactos. Continúa la regeneración del resto
con esta corrección. No certificar todavía encaje, movimiento ni acabado final.
Pendientes: orejas y bordes de gorra desde varios ángulos, carrera/salto de las
cuatro mascotas, camiseta/lazo/zapatillas nuevos, sus pruebas e incorporación.

## Revisión de la gorra · comentario más reciente del usuario

El usuario pidió ver primero la gorra y rechazó la primera revisión: el material
parecía plástico barato. Se detiene la creación de otras prendas para revisar
esta pieza. No avanzar al resto por una automatización antigua.

La revisión del pingüino incorpora mapas de algodón PBR de 1024 px: color,
normal y rugosidad, con hilos entrelazados y fibras suavizadas. Se reduce el
brillo especular y el tinte blanco del sheen que lavaba el coral. UV envolvente
para la copa y UV de superficie para la visera, en escala de 20 cm por muestra.
Se añadieron ribetes de tela en los contornos reales, copa con seis paneles,
visera con canto redondeado, doble pespunte, ojales y corazón acolchado apoyado
en la superficie por rayos BVH. Las puntadas tienen geometría propia.

La exportación con combinación de texturas necesitó Blender fuera del aislamiento
para escribir sus imágenes temporales. Terminó con código 0. El script conserva
los temporales de trabajo dentro de `outputs/blender-temp`; no toca originales.
Maestro de esta gorra: `design/wardrobe-restart/models/GORRA-R2-penguin.blend`.
Las otras tres gorras todavía tienen el material anterior y el visor lo indica.

Se comprobó la revisión nueva en tres cuartos, frente, perfil y espalda con el
GLB real. También se revisaron la carrera en fase 0,25 y el salto en fase 0,5;
son muestras de postura, no una certificación de todas las fases ni del juego.
El material usa tejido con menor contraste y normal más suave para reducir
líneas al alejar la cámara. La cinta posterior ahora es curva, acolchada y
cosida, con una hebilla redondeada apoyada sobre la tela. El visor incorpora
iluminación de estudio suave y filtrado anisotrópico de los mapas de tela.

Capturas reales de esta revisión (no imágenes generadas):
`design/wardrobe-restart/gorra-algodon-penguin-espalda.png`,
`design/wardrobe-restart/gorra-algodon-penguin-perfil-carrera.png`,
`design/wardrobe-restart/gorra-algodon-penguin-frente-salto.png` y
`design/wardrobe-restart/gorra-algodon-penguin-tres-cuartos.png`.
GLB de gorra: 8.414.652 bytes. Está pensado para revisión del acabado; todavía
falta optimizar su peso sin perder detalle antes de integrarlo en la app.
Falta opinión del usuario sobre el material y comparación artística completa.
La referencia tiene una textura más rica y un bordado más denso; no declarar
identidad exacta con la imagen. Las otras tres mascotas conservan el material
anterior, según el aviso del visor. No avanzar a otras prendas todavía.
El nuevo torso del pingüino también es experimental: se conservó la cabeza/UV
original y se sustituyó la superficie de torso plegada por una silueta limpia;
no está incorporado al juego. No presentar estas pruebas como versión final.

## Gorra cubierta y contacto real · 12 de octubre

El usuario pidió cubrir mechones/orejas con la gorra, rechazó de nuevo el material
por parecer plástico y señaló que el problema principal era la integración: el
modelo parecía flotante. Estas observaciones sustituyen el criterio anterior de
abrir huecos para las orejas en esta gorra.

Se exportaron las cuatro copas continuas, sin cortes para orejas. La utilidad
`assets/runner/pet-headwear-occlusion.js` mantiene dos geometrías por malla: la
original y una variante que oculta triángulos sobresalientes sobre el borde de
la gorra. Conserva atributos UV, normales, pesos y grupos de material. Solo se
activa con la gorra puesta; quitarla restaura la geometría original. El perfil
por especie está en `headwear_occlusion` del catálogo experimental y procede de
los ajustes del generador. Se comprobó de frente la ocultación/restauración en
pingüino, oso, cerdito y pollito. Evidencia de restauración:
`design/wardrobe-restart/gorras-occlusion-retirada.png`.

Solo el pingüino tiene la nueva revisión de material y contacto. La parte baja
de su copa ahora sigue por rayos BVH la superficie real de la cabeza posada,
con 6 mm de margen en la superficie media y 12 mm de espesor. La visera pasó
de 145 a 110 mm de profundidad, con el centro levantado. La cinta y la abertura
posteriores también siguen la superficie real. Se redujo el desplazamiento de
sombras del visor para que las sombras de contacto pequeñas no desaparezcan.
No se cambió la cabeza ni se regeneraron los GLB de las mascotas en este paso.

Se creó una muestra de algodón coral con ImageGen integrado, guardada en
`design/wardrobe-restart/models/cotton-coral-albedo-ai-v1.png`, y se aplicó como
mapa difuso real. Relieve y rugosidad se derivan aproximadamente de luminancia;
no es un escaneo PBR ni demuestra igualdad física con la referencia. Se añadió
más densidad al bordado y mayor relieve en las uniones de paneles.

Prompt de la textura: “Create a production game material texture: a square
seamlessly tileable ALBEDO/BASE COLOR swatch of soft coral pink cotton twill for
an adorable premium animated penguin's baseball cap. Entire image edge-to-edge
is the same fabric, photographed orthographically at macro distance with
perfectly flat uniform diffuse illumination, no shadows, no vignette, no
highlights, no objects, no border, no words. Warm coral base #EC6276. Dense
diagonal cotton twill weave with organic slightly irregular spun yarn, tiny
pale twisted fibers and subtle soft lint, gentle mottled dye variations. Should
unmistakably read as real soft cotton canvas, NOT a regular square grid, not
plastic, not rubber, no knitted large loops. A 20 cm cloth swatch seen close up.
Extremely detailed natural textile surface. Repeat seamlessly on all four
edges. Soft pastel animated-realism art direction but physically credible
material.” Revisar juntas de repetición y peso antes de activar en producción.

Pendiente: validación visual de espalda del último ajuste, comparación final
con la referencia y opinión del usuario; luego llevar el contacto/material a
las otras tres especies. No pasar a otra prenda ni declarar acabado final.
La tienda/juego activos siguen intactos y no se generó ningún APK.

## Camiseta abrazo: corrección de mangas · 12 de octubre

El usuario aceptó la gorra del pingüino como suficiente por ahora y autorizó
continuar con las demás prendas. Se construyó una camiseta nueva, independiente
del vestuario rechazado, en `scripts/blender-restart-shirt.py`. Patrones por
especie editables en `design/wardrobe-restart/garment-patterns.json`.

La primera prueba tenía un hueco visible sobre el ala y facetas en la tela.
Se corrigió el sentido del anillo del puño, creando cuatro vueltas conectadas
de tejido con espesor, y se subdividió el patrón antes de unir los hombros.
La revisión 13 mostró la abertura cubierta de perfil y una silueta más redonda
de frente. Evidencia: `design/wardrobe-restart/camiseta-manga-perfil-r13.png`.
El usuario no ha aprobado esta camiseta. Quedaban puntas pequeñas en el puño;
se está regularizando la distribución del borde antes de comprobar movimiento.

Solo está exportada la camiseta del pingüino. Las otras tres especies siguen
pendientes de construcción y revisión. Maestros `CAMISETA-R2-penguin.blend` y
`shirt_love_r2_penguin.glb`, todavía experimentales y ocultos en catálogo.
El visor desactiva temporalmente la recepción de sombras de la camiseta para
diagnóstico; no presentar ese ajuste como integración final de iluminación.
La malla ronda 97.000 vértices antes de optimizar; no es todavía un activo móvil
terminado. Pendiente: revisar frente/perfil/espalda y carrera/salto del último
export, corregir penetraciones si aparecen, luego adaptar las otras mascotas.

Última revisión de esta sesión: puño con pliegue de algodón de 9 mm, transición
suavizada y patrón redondeado. La subdivisión final completa se descartó: elevaba
el total a 321.820 vértices sin resolver las pequeñas puntas del puño. Se volvió
a una superficie menor y se reemplazó la búsqueda de vértices por KDTree para
evitar repetir el coste de ajuste. Exportación completada sin errores, cuatro
bordes intencionales antes de añadir espesor. Prueba real final de frente y perfil
en reposo; carrera en fase .25 y salto en .5 probados en la revisión precedente.
Evidencia actual: `design/wardrobe-restart/camiseta-volumen-r15.png`.
La abertura grande está cubierta, pero quedan pequeños extremos en el puño y
falta revisión de espalda y ciclos completos de la última versión. No está final
ni incorporada al catálogo activo. No avanzar a las otras mascotas atribuyendo
a esta prueba una validación completa que todavía no tiene.

## Petición de camiseta corta y holgada

El usuario pidió acortar el largo y evitar el aspecto ajustado al cuerpo.
Se elevó el bajo del patrón del pingüino de .175 a .235, conservando cuello y
mangas. El panel inferior ahora cae con holgura en vez de estrecharse siguiendo
la barriga: transición suave desde `loose_from`, amplitud `hem_ease` y ondulación
textil pequeña `fold_depth`. El bordado se coloca más alto (`heart_y`). Estas
propiedades están en el patrón editable; no se cambió la anatomía de la mascota.
Es caída modelada, no simulación física de tejido. Validación visual pendiente
del export de esta revisión; no se trasladó el cambio a otras especies todavía.

Export y revisión 16 completados: comprobados tres cuartos, espalda en reposo y
perfil en carrera fase .25 en el visor real. El bajo ahora deja visible la barriga
y cae separado en vez de pegarse al estrechamiento del cuerpo. Evidencia:
`camiseta-corta-holgada-r16.png` y `camiseta-corta-carrera-r16.png` en la carpeta
de diseño. Siguen pendientes el ciclo completo, salto de esta versión, ajuste
de pequeños extremos de puño y las otras tres especies. No se activó en producción.

## Algodón más grueso · petición siguiente

El usuario aprobó largo y holgura pero indicó que trama/tela se veían demasiado
finas. Se añadieron parámetros `fabric` al patrón para mantenerlos editables:
espesor de 6 a 10 mm en unidades del modelo, puño de 9 a 11 mm de radio, cuello
y bajo de 4,8 a 8 mm, hilo de 0,9 a 1,2 mm. La muestra UV aumenta de 20 a 32 cm
para que la trama sea perceptible, con normal strength .85 y material separado
`Algodón crema grueso`. El corazón se recoloca sobre la nueva cara externa;
no se modifica el largo aprobado ni la mascota. Revisión de export pendiente.

Revisión 17 exportada (86.744 vértices, 83.150 caras, cuatro bordes intencionales)
y vista en el navegador. Se añadió `Detalle de tela` al encuadre y filtrado
anisotrópico también a las texturas de la camiseta. Evidencia real:
`design/wardrobe-restart/camiseta-algodon-grueso-r17.png`. El relieve se aprecia
más y los bordes tienen más cuerpo. A gran aumento hay bandas onduladas de la
trama en hombro/pecho: revisar UV y filtrado antes de declarar textura final.
Esta revisión solo se comprobó visualmente en tres cuartos/reposo; falta probar
los ciclos de movimiento del material nuevo. Conserva la holgura y el bajo corto.

## Dobladillos anchos en lugar de cordones

El usuario rechazó los bordillos finos y pidió bandas gruesas como la referencia,
con líneas de costura. Se reemplazaron los tubos de borde por bandas de tejido
de 26 mm (24 mm en puños), ocho filas siguiendo la superficie real por BVH,
pliegue de 4 mm y espesor propio de 3 mm. Dos filas paralelas de pespuntes
apoyadas sobre cada banda. Parámetros de anchura/pliegue/hilo en `fabric`;
se conserva el largo y la caída aprobados. Export y validación pendientes.

El usuario vio la revisión 18 y dijo que le gusta más; solicita pulir acabados.
Se conserva la dirección de bandas anchas. Ajuste siguiente: perímetros
remuestreados a separación uniforme, suavizado de borde y normales interpoladas
para evitar dientes al elevar la banda sobre caras del patrón. UV de bandas
orientadas a lo largo del dobladillo y doble pespunte regular (misma proporción
de puntada/hueco alrededor de toda la vuelta). Validación visual pendiente del
último export; no llamar este ajuste final sin comprobarlo en el navegador.

Revisión 20 exportada y comprobada en frente/reposo, cuerpo entero y detalle.
Puños reconstruidos con perfil continuo, evitando el pequeño bulto causado por
saltos de proyección cerca de la axila. Pespuntes agrupados en mallas de cilindros
para conservar relieve sin cientos de objetos Blender separados; el primer
proceso lento se detuvo y se reconstruyó con esta optimización. Export actual:
106.840 vértices / 97.950 caras, sin errores de Blender. Evidencia real guardada
en `camiseta-acabados-frente-r20.png` y `camiseta-acabados-detalle-r20.png`.
El usuario aprobó la dirección de diseño, no el vestuario completo. Pendientes:
pequeños extremos del patrón bajo puños, UV del torso en ángulos oblicuos y
validación de movimiento del último export. Todo sigue experimental, oculto
en producción, sin APK nuevo y sin ajustes validados para las otras mascotas.

## Prueba real de recorrido y rechazo del movimiento R2

Se probó el pingüino con camiseta/gorra R2 en `index.html?wardrobe_review=r2`.
El conjunto cargó y corrió hasta 123 m; no se verificó el salto antes de que el
usuario rechazara carrera/salto por rígidos y pidió mantener los anteriores.
Se restauró íntegramente `assets/runner/game.js` a HEAD (su diff contenía solo
la ruta experimental de esta prueba). Los archivos nuevos de prendas y maestros
Blender se conservan; el juego vuelve al personaje y animaciones anteriores.
Respaldo del experimento en `outputs/game-wardrobe-r2-before-motion-rollback.js`.
`restart-game-wardrobe.js` permanece separado e inactivo: no activarlo con el rig
R2 rechazado. Pendiente adaptar el nuevo vestuario al rig/movimiento original,
sin cambiar de nuevo carrera/salto, y verificar salto/carriles antes de afirmar
integración final en el juego. El resto de prendas/especies sigue pendiente.

Se recortaron vértices bajos de la boca de manga y se exportó la camiseta del
pingüino; aún falta evidencia visual del último recorte. Se amplió la trama de
la gorra a una muestra física de 28 cm y normal strength .75, manteniendo su
encaje. Solo está regenerada la gorra del pingüino; revisar antes de extender.

El usuario volvió a rechazar el salto restaurado: HEAD todavía reemplazaba el
clip original por `createRunnerJump` y limitaba la carrera con `createRunnerRun`.
Se retiraron ambos reemplazos de `game.js`. Ahora usa directamente `Running` y
`Regular_Jump` importados de cada GLB, con los controles/física existentes.
Se comprobó por lectura de los cuatro GLB que ambos clips existen. No confundir
la restauración a HEAD anterior con esta restauración real de clips originales.
Pendiente validar visualmente el salto completo, las prendas nuevas sobre este
rig original y todas las mascotas. No reconstruir de nuevo el movimiento por
comodidad para el vestuario: se debe adaptar la ropa a él.

El clip original del pingüino también giraba de lado: `Regular_Jump` contiene
rotación Y de cadera de aproximadamente -45 grados y deriva X/Z, a diferencia
de `Running`. El usuario rechazó ese giro. Nuevo helper `pet-jump-heading.js`
clona el clip y elimina solo el twist Y de Hips/Root y su traslación lateral,
conservando flexión/articulación y traslación vertical del original. No vuelve
a la animación estática R2 ni al reemplazo rígido `createRunnerJump`.
Validación visual pendiente de la última revisión; no afirmar que el salto
quedó aprobado antes de que el usuario lo vea.

Comprobación del helper con los cuatro GLB reales completada: conserva todos los
tracks de articulación y la traslación vertical, elimina el twist de root relativo
al heading de reposo y fija X/Z. Se detectó además que el runner aplicaba
`refinePip` y `stabilizePetTorso`, alteraciones concebidas para el patrón de la
habitación. Se limitaron a la habitación sin review_motion: el recorrido y la
revisión de clips ahora usan la geometría/rig originales. Se vio un salto real
en el bosque (inicio a 3 m) y se guardó `salto-frontal-recorrido.png`; la mascota
mira hacia el recorrido. No afirmar aprobación artística del usuario ni
validación de prendas R2: están todavía separadas del juego. Queda revisión
de todas las fases/mascotas y adaptación de vestuario al rig original.

## Conjunto Dulce nuevo y mangas sobre la mascota real

El usuario pidió terminar los otros conjuntos y después pidió ver Dulce ahora.
Se construyeron lazo y zapatillas nuevos en `blender-restart-details.py`, con
maestros editables y pesos del rig original. Solo pingüino exportado en este paso.
La camiseta admite `--original-rig`, con ruta separada ORIGINALFIT y transferencia
de piel. `wardrobe-original-review.html` usa el renderer real: en reposo la
apariencia de habitación, en carrera/salto el cuerpo original del recorrido.
Esta diferencia aún impide certificar un solo encaje en todos los modos.

Primera captura `dulce-conjunto-prueba-original.png` no está aprobada: la camiseta
parece chaleco. El usuario pidió arreglarla. Las alas de habitación tienen centro
x±.257/y.387/z.025 y radios .08/.158/.068, distintos del maniquí R2. Se añadió
`original_fit` al patrón, ensanchando hombros/puños sin cambiar la mascota ni la
camiseta aprobada R2. El primer export detectó seis bordes: el corte del cuello
abría las dos copas altas de manga. Se están cerrando exclusivamente esas dos
copas; cuello, bajo y puños deben conservar cuatro bordes intencionales.
Validación del último export pendiente. No activar catálogo ni emitir APK.

## Corrección de origen: preservar el GLB entregado (12 de octubre)

El usuario rechazó toda la camiseta y las modificaciones de la mascota. Esta
instrucción sustituye la autorización anterior para reconstruir el rig: conservar
geometría, pesos, rig y texturas originales. No usar las mascotas R2 como maniquí
activo. Se retiraron `refinePip` y `stabilizePetTorso` del renderer en todos los modos;
también se excluyeron las texturas de mascotas de la reducción de mapas del juego.
La pose de reposo solo anima huesos existentes; no reconstruye anatomía.

El pingüino de play-models y el GLB suministrado tienen SHA256 idéntico:
`5EA59A0B7C43B753FD8D40FD9CB865A6851ADEDAA00AB8BD721E893519987B5B`.

`snapshot-original-pet.mjs` captura superficie posada y pesos originales sin
refinamientos. Solo pingüino capturado por ahora. `blender-shirt-original-surface.py`
crea exclusivamente ropa a partir de ese molde, con holgura, espesor y acabados.
El primer prototipo falló: solo dos bordes en vez de cuello, bajo y dos puños.
Se bloqueó su activación. Segunda prueba une la copia de tejido para construir
un patrón continuo; pendiente de resultados y revisión visual. Nunca reemplazar
una prenda por pasar una comprobación de topología sin verla en la app.

Se capturaron ahora las cuatro mascotas originales. El molde completo con las
alas pegadas al torso no produce puños independientes; se recorta exclusivamente
la copia de tela al torso y se cosen volúmenes de mangas al molde. La cuarta prueba
tiene cuatro aberturas previstas. Se eliminó una cara diminuta aislada, no se
ocultó un agujero grande. Algodón de 10 mm, holgura de 14 mm y bandas de 24 mm;
exportación y revisión visual aún pendientes. La camiseta anterior sigue rechazada.
Se corrigió también el cálculo repetido de normales que ralentizaba el modelado.

## Estado real de la camiseta al cerrar las pruebas del 12 de octubre

La camiseta original-surface sigue siendo experimental, **no está aprobada**.
La copia literal de superficie también copiaba las uniones de alas/patas y producía
formas indeseadas. El patrón actual usa las medidas originales con un torso textil
suave, holgura y copas de manga redondeadas. Cuello abierto solo en el centro;
no cortar las copas con el mismo plano. Bajo y bordado se subieron para dejar más
libres las alas. Conserva cuatro aberturas y la malla con espesor es manifold en
Blender. Los acabados están separados y heredan la deformación de la tela.

Pesos de ropa: torso estable en Spine2; transición suave a una superficie BVH
exclusivamente de Shoulder/Arm/ForeArm originales. Se descartaron arrastres desde
cabeza/patas, el corte brusco a y=.30 y la cobertura por franja de altura. La
cobertura experimental actual se calcula contra el volumen de prenda: elimina
caras completamente interiores y caras de brazo que cruzan su borde. Necesita
revisión de todas las fases, especialmente huecos del puño y laterales de cintura.
No usar este mecanismo para certificar que no hay penetraciones visuales.

Maestro actual: `design/wardrobe-restart/models/CAMISETA-SUPERFICIE-ORIGINAL-penguin.blend`.
GLB: `assets/runner/accessories/original_surface_shirt_penguin.glb`.
Cobertura reversible: `assets/runner/restart/shirt-original-coverage-penguin.json`.
Se exporta primero a `.building.glb` y solo se sustituye el visor tras transferir
los pesos correctamente. El catálogo de producción permanece sin activar esta pieza.

Evidencia real: `design/wardrobe-restart/camiseta-original-frente-prueba.png`.
El frente en reposo tiene ahora tela con volumen y puños completos. En el perfil
de carrera a fase .25 se vieron todavía intersecciones y formas raras cerca de
la cintura; la última revisión sube el bajo, pero no se ha comprobado todavía esa
revisión en carrera ni salto. No afirmar versión final ni todas las mascotas listas.

Pruebas de regresión: 5/5 pasan en `original_wardrobe_coverage_test.mjs` y
`pet_jump_heading_test.mjs`. La primera usa el GLB real y comprueba que quitar
la ropa restaura todos los índices, conservando posiciones, UV, normales, pesos
y huesos. Las otras cuatro conservan articulación del salto original y corrigen
solo el giro lateral de raíz. Estos tests no constituyen aprobación estética.

Siguiente paso: verificar esta última camiseta en perfil/espalda, todas las fases
de Running/Regular_Jump y sus acabados; corregir interferencias antes de seguir
con el resto del conjunto o generar las tres variantes. Los originales de las
cuatro mascotas están capturados en `design/wardrobe-restart/fitting/*-original.json`.

## Continuación, noche del 12/13 de octubre

Se construyeron las cuatro camisetas originales con patrones independientes en
`original-shirt-patterns.json`. Todos los modelos son experimentales y no están
activados en la tienda. El motor del patrón comprueba cuatro aberturas, grosor
cerrado/manifold, bordes cosidos y holgura mínima contra la superficie original.
La prueba frontal del oso detectó que el pecho atravesaba la tela: se corrigió
muestreando también superficies con pesos de cuello/cabeza debajo del cuello.
Se revisaron en navegador los frentes de oso, cerdito y pollito. El oso conserva
algo de piel visible por encima del cuello; revisar su forma y no declarar final.

Lazos y zapatillas nuevos: exportados para las cuatro especies, maestros
`COMPLEMENTOS-NUEVOS-{species}.blend`. Lazo ligado rígidamente a Neck, zapatos
a cada Foot original. Necesitan revisión real de todas las vistas y poses.
`blender-original-cap.py` exporta solo gorras sobre datos originales, nunca
mascotas. Su trabajo de cuatro especies estaba en curso al guardar esta nota.

El salto original levanta hombros hacia la cabeza y deforma/oculta mangas. Se
probó seguimiento de superficie con `pet-sleeve-anchors.js`: articulaciones
exclusivas de la ropa, escala unitaria, sin alterar el esqueleto original. La
orientación del puño se cambió para apuntar a la salida del ala, con su borde
continuo y grosor. El salto original aún revela deformación: NO darlo por resuelto.

Se añadió `Natural_Jump` **solo al visor experimental petOnly**, conservando
Regular_Jump y el recorrido sin sustituir su movimiento. Es un clon con límites
suaves de rotación en torso/cabeza/hombros, conservando tiempos y movimiento de
las patas. El GLB original nunca se reescribe. En la prueba de pingüino fase .5,
tres cuartos, mantiene el torso erguido y la camiseta con volumen. Se preguntó
al usuario si prefiere corregir la animación o conservar exactamente el salto
original; la respuesta aún está pendiente. No presentarlo como preferencia
aprobada ni activarlo silenciosamente en el juego publicado.

Regresión 9/9: restauración exacta de la malla al quitar ropa, cuatro saltos
originales conservados salvo giro de raíz, y cuatro pruebas de inmutabilidad,
timing y patas para Natural_Jump. Faltan tests de anclajes de ropa y evaluación
visual de carrera/salto en las otras especies. Fotografías reales guardadas:
`camiseta-original-chick-frente-prueba.png`, `camiseta-original-pig-frente-prueba.png`.

Prioridad siguiente: revisar y corregir el conjunto Dulce de las cuatro mascotas,
incluidos gorras, lazo y zapatillas; después empezar la siguiente prenda con su
referencia. No reutilizar los modelos R2 de mascota ni las prendas rechazadas.
No certificar todos los outfits terminados, idénticos o listos para venta.

### Último estado guardado

Las cuatro gorras originales terminaron de exportarse. Se integró cobertura de
orejas/tufo reversible al equipar headwear, calculada sobre la superficie posada,
sin reescribir los GLB originales. Necesita regresión de quitar/cambiar conjuntos,
porque se combina con máscaras de mangas y zapatos. `pet-rest-pose.js` ahora
excluye esqueletos de cosméticos al restaurar el reposo de la mascota.

El último render del conjunto Dulce del pingüino carga gorra, camiseta, lazo y
zapatillas originales en el renderer real. Las zapatillas parecían demasiado
planas; se elevó el empeine a un mínimo de .145 unidades y se reconstruyeron las
cuatro variantes. No se ha revisado visualmente este último cambio. Los patrones
de camiseta son editables por especie en `original-shirt-patterns.json`; no usar
un escalado genérico. El cerdito y pollito se vieron con cuello y pecho cubiertos.
El oso mejoró después de incluir el volumen del cuello en el muestreo del cuerpo,
pero su cuello y hombros necesitan acabados más limpios.

La continuación existente quedó activa para esta semana a las 18:14, con el
objetivo actual de preservar originales y concluir cada prenda con evidencia,
sin APK ni activación de productos pendientes de validación. No se ha terminado
todo el inventario; prioridad sigue siendo cerrar Dulce antes de los otros outfits.

## 13 de octubre: camiseta casual, corrección solicitada por el usuario

El usuario rechazó las mangas infladas porque parecían hombreras de NFL.
La variante del pingüino ahora usa un torso de camiseta con hombro caído y
mangas tubulares cortas, en lugar de las esferas acolchadas. Se conserva la tela
con grosor, corazón, pespuntes y originales de la mascota. Las otras especies
TODAVÍA mantienen el patrón previo: no reconstruirlas como si este diseño ya
estuviera aprobado. El patrón editable sigue en original-shirt-patterns.json.

Se corrigió la orientación de la manga reflejada, se suprimió la rotación
posterior de los puños casuales y se separaron las capas de tejido y bordes.
Para este patrón casual no se proyecta el torso sobre alas ni cabeza; el patrón
se mantiene independiente. Se interpolan normales de la superficie exterior
para los dobladillos. El cuello se bajó a .510 para reducir contacto con la cara.

Prueba real en reposo: frente y tres cuartos muestran mangas reducidas sin
hombreras redondas. Evidencia: camiseta-casual-penguin-frente.png y
camiseta-casual-penguin-tres-cuartos.png. NO afirmar aprobación artística final.
La prueba Running, perfil, fase 0 muestra pliegues excesivos en mangas y
calzado deformado/desordenado. Evidencia de fallo:
camiseta-casual-penguin-carrera-pendiente.png. Prioridad siguiente: aislar
transformaciones/bindings del calzado y la transición torso-manga durante
Running sobre el modelo original; no seguir acumulando prendas sin resolverlo.
No afirmar que este conjunto está listo para los minijuegos.

Las zapatillas del pingüino tienen un empeine modelado, lengüeta acolchada,
cordones, borde de tobillo y pespuntes. Solo se reconstruyó esta especie con
ese cambio; las otras aún no. No están activadas en catálogo de producción.

pet-sleeve-anchors.js preserva el contacto autorizado en reposo: el despeje de
cabeza compara contra el contacto inicial, sin empujar mangas ya encajadas.
Test pet_sleeve_rest_contact_test.mjs usa las cuatro mascotas originales y
metadatos de GLB reales para comprobar identidad de anclajes en reposo,
escala unitaria y ausencia de cambios en huesos originales. 13/13 regresiones
pasaron antes del último ajuste geométrico; repetir solo la cobertura cambiada
y estos anclajes al concluir. SHA del pingüino original sigue siendo
5EA59A0B7C43B753FD8D40FD9CB865A6851ADEDAA00AB8BD721E893519987B5B.

El visor original admite diagnóstico inspect_static=1 e inspect_finish=0
(solo pet=1) para separar geometría y binding; no usar capturas de esos modos
como validación de animación. La captura de piel sin máscara no mejoró los
salientes, por lo que se restauró la cobertura medida. Los GLB se exportan
atómicamente, los maestros se guardan y no se publica APK.

## 13 de octubre: restauración de la camiseta aprobada y hombro caído

El usuario pidió recuperar la camiseta aprobada R20, conservando su mascota
original. La prueba actual del pingüino usa approved_shirt_love_penguin.glb,
generada por scripts/blender-restore-approved-shirt.py desde la camiseta R20
archivada. NO recuperar el avatar R2 junto con la prenda. El maestro editable
es design/wardrobe-restart/models/CAMISETA-APROBADA-ORIGINAL-penguin.blend.
Las otras tres especies siguen pendientes; el ajuste del pingüino no implica
validación del inventario ni activación en producción.

Se conservaron corazón, tejido, UVs y torso corto de la referencia. Las mangas
se reconstruyeron alrededor de las aletas: hombro inclinado desde el cuello,
puño inclinado y espesor textil. Se rechazó la corona horizontal tipo hombrera.
La unión superior se introdujo bajo el contorno de la cabeza para eliminar los
salientes negros vistos en reposo. Capturas reales: camiseta-hombro-caido-
frente-20261013.png, camiseta-hombro-caido-tres-cuartos-20261013.png y
camiseta-hombro-caido-perfil-20261013.png, bajo design/wardrobe-restart.

El cálculo de holgura incluye ahora el torso geométrico incluso donde el GLB
original asigna piel del abdomen a UpLeg. Recortar mangas DESPUÉS de ampliar
esa holgura cortaba también el lateral de la camiseta: ahora se recorta primero
la prenda archivada y después se ajusta el torso. No repetir esa inversión.
No usar booleanos sobre todas las islas de costura: una prueba previa generó
cubos enormes. El exportador rechaza límites no finitos o fuera del tamaño de
la mascota, y reemplaza el GLB de manera atómica.

En carrera se detectó que el anclaje de la manga giraba también su raíz como
una pieza rígida. Se añadió sleeve_root_fade, opcional por prenda, en
wardrobe_gltf.py: la unión superior permanece con el torso y el movimiento
crece hacia el puño. La máscara de piel cubre solo superficies encerradas en
la camiseta y es reversible al desequipar; conserva vértices, UVs y pesos
originales. La carrera completa y el salto todavía requieren evidencia visual
después de esta última corrección; no certificar minijuegos listos.

Seis pruebas de activos, reversibilidad de cobertura y contacto en reposo
pasaron DESPUÉS del último cambio de pesos. La prueba visual Carrera, Perfil,
fase 0 aún muestra penetración en la raíz y pliegue excesivo de manga: evidencia
camiseta-hombro-caido-carrera-pendiente-20261013.png. La unión inclinada se ve
mejor en reposo, pero NO está resuelta durante carrera. Próximo trabajo:
construir una unión topológica y un campo de pesos continuo torso-sisa-manga;
no volver a presentar las pruebas de reposo como aprobación de minijuegos.
El original del pingüino conserva SHA256
5EA59A0B7C43B753FD8D40FD9CB865A6851ADEDAA00AB8BD721E893519987B5B.
No APK, publicación ni sustitución del catálogo de producción en esta sesión.

## 13 de octubre: nuevo patrón cosido según la referencia del usuario

Referencia guardada en design/wardrobe-restart/references/dulce-20261013.png.
La variante experimental del pingüino ahora apunta a
assets/runner/accessories/sewn_shirt_love_penguin.glb. Generador:
scripts/blender-sewn-shirt.py. Maestro: models/CAMISETA-COSIDA-penguin.blend.
NO continuar desde el generador de hombreras ni volver a reemplazar el avatar.

Se construyó un torso paramétrico con dos sisas y lofts de manga unidos a sus
mismos vértices. Blender comprueba exactamente cuatro contornos abiertos antes
de dar espesor: cuello, bajo, dos puños. La tela tiene espesor .014; los bordes
y pespuntes están por fuera de ese espesor. El corazón conserva el material
coral de la camiseta aprobada, proyectado sobre la nueva superficie. La unión
superior tiene holgura lateral bajo la cabeza, evitando los salientes vistos
en reposo. Capturas: camiseta-cosida-frente-20261013.png,
camiseta-cosida-tres-cuartos-20261013.png, camiseta-cosida-espalda-20261013.png.

wardrobe_gltf.py acepta sewn_sleeve_field y sewn_surface_skin solo para este
patrón: campo de pesos continuo, contacto real de cabeza/cuello/hombro y
muestreo de aleta original, sin arrastre de huesos de pierna. Se relajan ocho
pasadas los pesos entre vértices cosidos; NO se modifican los vértices del pet.
La identidad de posición en reposo se mantiene al enlazar sobre la pose
normalizada que usa realmente la app. Los ayudantes NidoSleeve siguen en el
GLB por compatibilidad, pero esta nueva manga usa el campo de superficie.

El límite de cobertura anterior era de otra manga: el puño nuevo está en
.402+.012*(abs(x)-.267)/.055. approved_shirt_coverage.py usa sewn=True para
este patrón y añade __clips: caras que cruzan puño o bajo se recortan de forma
reversible en una copia de geometría en memoria, con UVs, normales y pesos
interpolados. pet-sleeve-coverage.js restaura la geometría exacta al quitar la
prenda. Se conservan todos los vértices/atributos originales; solo se añaden
vértices en el borde recortado a la copia temporal. No eliminar piel de cabeza
con peso Head >= .5 para ocultar un fallo de ajuste; preservar cara completa.

Seis regresiones pasaron DESPUÉS de la última relajación de pesos y transferencia
directa de superficie. Prueba visual de carrera perfil fase .5 mostró
plegado excesivo; se redujo con transferencia directa, pero hay que seguir
revisando esa fase y el salto original. En Salto original frente fase .5 la
animación suministrada lleva las aletas horizontales y cabeza hacia abajo:
la ropa queda excesivamente estirada en las sisas. NO certificar minijuegos
ni cuatro mascotas por las capturas bonitas en reposo.
scripts/check-sewn-shirt-motion.mjs dejó una medida anterior en
outputs/sewn-shirt-motion-intersections.json; su cálculo no contempla todavía
las caras __clips nuevas, por lo que no usar esas cifras para certificar esta
versión. El GLB del pet sigue con su SHA original. No APK ni publicación.

## 13 de octubre: cuello aprobado, sisas, lazo y zapatillas

El usuario aprobó el nuevo bordillo del cuello y pidió conservarlo mientras
se retocaban las uniones de manga. La banda visible empieza en .514, mide
.026 de ancho y .008 de espesor, con relieve redondeado y pespuntes. Sigue la
elipse del torso, no los rayos de las mangas: así no se extiende hacia hombros.
La firma de los atributos de cuello antes/después de añadir sisas coincide:
outputs/collar-approved-signature.json, SHA
bc47c5d64beec666bb207d796dbbb4e236ae443ba0ba2e914cd7a31241a01edb.
No cambiar ese cuello aprobado en la siguiente iteración.

Las sisas ahora tienen una unión textil y puntadas separadas, colocadas sobre
la superficie real de la camiseta. Se redondeó solo la trayectoria de costura;
la forma primaria y el cuello se conservaron. Los objetos de puntada son una
curva con múltiples tramos, para evitar un objeto/draw por cada puntada.

También se rehízo el lazo: lóbulos de tela más amplios en los extremos,
pliegue en el centro y nudo rectangular con esquinas suaves, en lugar de tres
formas circulares. Generador scripts/blender-restart-details.py -- --species
penguin. Maestro COMPLEMENTOS-NUEVOS-penguin.blend; claves de inventario
bow_neck y shoes_heart conservadas.

Zapatillas: suela marfil biselada de base plana, puntera marfil, lengüeta,
ojales, cordones cruzados y pespuntes; parche de lona y corazón coral siguen
la curvatura real del lateral. Se corrigió data.name: antes no incluía el pie
en algunas mallas y el exportador transfería pesos del cuerpo a esos detalles.
Cada zapatilla está ahora unida por pie/materiales y todos sus vértices usan
el Foot correspondiente, evitando estiramientos independientes de piezas.
wardrobe_gltf.py tolera prendas rígidas sin garment_skin_profile; no volver
a asumir que todo Patrón cuello es una camiseta con perfil sewn.

Tres pruebas pasaron: activos de camiseta y dos casos de enlaces rígidos
(lazo a Neck y calzado a su Foot). Prueba visual: frente/tres cuartos en
reposo y zapatillas en Running .5. Capturas dulce-cuello-sisas-complementos-
frente-20261013.png y dulce-cuello-sisas-complementos-20261013.png.
Los cambios son del pingüino de referencia; no implican nueva validación de
las otras especies ni cierre de los problemas anteriores de animación de
camiseta. El cuello sí tiene aprobación del usuario; lazo/zapatillas/sisas
esperan revisión artística. Todo queda en el visor experimental.

## Heartbeat 2026-10-13: complementos de las otras tres mascotas

Rehechos bow_neck y shoes_heart de bear/pig/chick con el generador nuevo de
Blender, conservando los GLB originales. Copia previa de los seis GLB y catálogo:
outputs/details-before-rigid-foot-20261013/. Maestros editables:
design/wardrobe-restart/models/COMPLEMENTOS-NUEVOS-{species}.blend.

Causa concreta corregida: nombres de datos de malla de los zapatos no indicaban
Left/Right aunque sí lo hacía el objeto. Eso impedía asignar todos los detalles
al Foot correcto. Ahora calzado, cordones, ojales y parches se agrupan por pie y
usan exclusivamente su Foot; el lazo usa Neck. Se ajustó la abertura de tobillo
al menor eje del pie para oso/cerdito/pollito, preservando el patrón del pingüino.

Verificación: node --test --test-isolation=none test/wardrobe_details_fit_test.mjs:
8/8 casos pasaron, cuatro especies por lazo/calzado. El runner de pruebas con
subproceso falló por EPERM; aislamiento desactivado ejecutó las mismas pruebas.
No basta para aprobar encaje artístico ni penetración durante toda la animación.

Capturas reales en design/wardrobe-restart/: zapatillas-oso-reposo-20261013.png,
zapatillas-cerdito-reposo-20261013.png, zapatillas-cerdito-carrera-20261013.png,
zapatillas-pollito-reposo-20261013.png, zapatillas-pollito-carrera-20261013.png.
Pollito reposo/carrera .5 muestra puntera, cordones y suela juntos al pie. Las
capturas del cerdito recortan los pies: NO cuentan como verificación visual del
calzado completo. Tampoco se comprobó aún salto/perfil/espalda de los seis nuevos
complementos. Dos intentos de cambiar el encuadre (margen y bounding box de pose)
no resolvieron el cerdito y se REVERTIERON; evitar repetirlos sin diagnóstico.

Siguiente paso: resolver el recorte del visor del cerdito mediante diagnóstico
real de cámara/posición de mallas, comprobar los complementos desde atrás y en
salto y después portar el patrón de camiseta cosida a las otras tres especies.
Camiseta del pingüino conserva cuello aprobado y unión de sisas; persiste revisión
de deformación en carrera/salto. No se alteró movimiento publicado, no se activó
producto, no se generó APK. Peluca oculta y automatización sigue pendiente.

## Ajuste localizado hombro-cuello, 2026-10-13
Usuario detecta unión rara entre hombro y cuello posterior. Capturas reales
camisa-hombro-{perfil,espalda}-antes.png muestran corona de manga por encima
del bordillo del cuello. Se bajó de forma gradual 0.019 unidades la zona superior
lateral del patrón (factor angular + smoothstep vertical), manteniendo inalterada
la construcción del bordillo aprobado y los GLB originales. Generador:
scripts/blender-sewn-shirt.py; maestro/GLB/catálogo actualizados. Respaldo:
outputs/sewn-shirt-before-shoulder-yoke.glb.
Verificación visual: camisa-hombro-{perfil,espalda}-ajuste.png. En perfil la
corona termina junto al bordillo en vez de elevarse sobre él; espalda conserva
bordillo y continuidad. Sigue pendiente revisar esta modificación durante toda
la carrera/salto y no equivale a cierre del vestuario. Dos pruebas de activo y
restauración exacta de piel original aprobadas. Siguiente: refinar si usuario
señala otro detalle de unión; no bajar el cuello aprobado ni alterar mascota.

### Cuello posterior: sobrante eliminado (2026-10-13)
El usuario confirma que tras bajar hombros todavía sobresale espalda sobre el
bordillo. Causa: borde superior del patrón a .575, bordillo termina a .540.
Se comprimió únicamente el escote posterior desde .515 a un máximo .537 con
transición angular gradual hacia los costados; bordillo separado sin cambios.
GLB/maestro/catálogo regenerados. Captura real camisa-cuello-posterior-recortado.png
muestra que el sobrante posterior desaparece en reposo. Dos tests de activo y
restauración de mascota original pasan. No aprobación de movimiento ni otras
especies implícita; siguiente verificar costados/carrera/salto con este escote.

### Hombro y unión superior suavizados (2026-10-13)
Tras petición del usuario, se suavizó el factor angular del hombro y se amplió
la transición del recorte posterior a todo el costado. La antigua transición
solo posterior causaba un cambio brusco en la corona de manga. Bordillo conserva
geometría/grosor aprobado. La costura de sisa reduce progresivamente su relieve
de .0095 a .003 cerca del cuello para entrar debajo de su ribete en vez de
superponer relieves. GLB/maestro/catálogo regenerados; capturas reales:
camisa-hombro-suave-perfil.png y camisa-hombro-bordillo-union-suave.png.
Revisión de reposo perfil/espalda; movimiento aún pendiente. GLB originales
inalterados. Pruebas de activo y restauración de cobertura ejecutadas.

### Redondeo de sisa real y ribete discreto (2026-10-13)
Pedido: pequeño ajuste en perfil/tres cuartos, separación de hombro natural.
Se redondearon las esquinas del borde de sisa en los vértices compartidos
(3 pasadas locales .38); antes se redondeaba solo la costura decorativa y
quedaba el patrón rectangular debajo. Campo de pesos actualizado en esos puntos.
Ribete de sisa pasa de radio .0011 a .0018, conservando su entrada bajo el cuello.
Sin hombreras ni cambio de cuello/mascota. Capturas reales:
camisa-sisa-redondeada-tres-cuartos.png y camisa-sisa-redondeada-perfil.png.
Cambio visual leve, no certificación de igualdad artística. GLB/maestro/catálogo
actualizados. Dos tests de activo/restauración originales pasan. Movimiento y
las otras tres especies siguen pendientes de la revisión completa.

### Bordillo cóncavo superior solicitado (2026-10-13)
Usuario solicita solo costura con bordillo cóncavo siguiendo la aleta superior.
Se añadió cinta real de algodón de 6 mm de ancho/3 mm de espesor, proyectada
sobre la superficie de manga, arco bajo la corona y hilo fino .0007. No modifica
la silueta primaria ni el cuello aprobado. Primera ubicación junto al cuello
quedaba poco visible; arco recolocado sobre la manga visible (.500-.022*sin).
GLB/maestro/catálogo regenerados; captura real camisa-bordillo-concavo-hombro.png
muestra línea separadora curva en tres cuartos en reposo. No certifica movimiento.

### Corrección de interpretación: arco de sisa (2026-10-13)
Usuario rechaza la línea horizontal y pide seguir el trazado superior de aleta.
Se sustituyó por arco frente inferior -> corona -> espalda inferior, proyectado
a superficie real: x lateral .247, y .435+.090*sin(pi*u), z -.025+.135*cos(pi*u).
Cinta de 6 mm con ancho perpendicular al contorno; espesor 3 mm e hilo .0007.
Captura real de perfil camisa-costura-contorno-aleta.png muestra arco en la raíz
superior de manga, desaparece anterior franja transversal. Maestro/GLB/catálogo
actualizados. Dos tests de activo/restauración pasan. Se conserva cuello y mascota.
Revisión artística pendiente del usuario; no declarar final ni aprobado en movimiento.

### Diagnóstico aleta vs manga y nueva sisa (2026-10-13)
Usuario señala que aún se ve igual y autoriza corregir aleta si malformada.
Comparación real sin camiseta (solo lazo): aleta-original-perfil-diagnostico.png,
contorno de aleta continuo; no se modificó GLB original. Causa del hombro cuadrado:
abertura rectangular primaria. Los pasados cambios eran costuras y redondeo local,
insuficientes. Se recortó la abertura compartida como elipse de raíz de aleta,
centro y .465, radios y .067/z .130; x sigue elipse de torso. Loft de manga utiliza
los ángulos normalizados de ese contorno. Mantiene conexiones/topología continua,
cuello aprobado, puños y textura. GLB/maestro/catálogo regenerados.
Captura camisa-abertura-aleta-reconstruida-perfil.png muestra arco de unión
realmente visible, a diferencia de la línea anterior. Dos tests activo/cobertura
pasan. Pendiente aprobación artística y revisión de carrera/salto; no certificado
final ni generalizado a otras especies.

### Remate de bordillos tras aprobación de forma (2026-10-13)
Usuario aprueba forma actual; solo bordillo de hombro superpuesto al cuello.
No cambiar patrón/cuerpo/puño/aleta. Cinta cóncava termina debajo y=.513;
cordón de sisa y puntadas terminan debajo .511 (cuello comienza .514).
Se suprime solo el tramo de acabado oculto bajo cuello, no se corta tejido.
Maestro/GLB/catálogo regenerados. Dos tests activo/restauración pasan.
Captura de control camisa-bordillos-sin-cruce-perfil.png. Forma primaria conserva
aprobación; movimiento/globalización a otras mascotas sigue pendiente.

### Pico del cuello identificado por captura (2026-10-13)
Captura del usuario señala elevación diagonal de tela bajo el ribete, no solo
superposición de costuras. Se eliminó dependencia angular de altura del escote:
todo el borde primario llega a .537 por debajo del cuello .540. Se conserva el
arco de manga ya aprobado, cuello separado y mascota original. GLB/maestro/
catálogo regenerados. Captura real camisa-cuello-uniforme-perfil.png muestra
eliminación del pico señalado. Dos tests activo/restauración pasan; revisión de
movimiento no cerrada. Mantener este escote uniforme en adelante.

## Continuación: auditoría y movimiento, 2026-10-13
Pedido activo: terminar todas las prendas y comprobar uso. NO completado.
Auditados 24 artículos x 4 especies: 96 archivos presentes, hashes acordes a
catálogo, enlaces de huesos reconocidos. outputs/current-wardrobe-audit.json.
Cero fallos estructurales NO implica aprobación artística/movimiento.

Se comprobó camiseta actual en Running .5/tres cuartos: hombro se retuerce y
aparecen huecos bajo cuello. Captura camiseta-uso-carrera-actual.png. Ensayos:
1 helper sleeve + Neck uniforme: no resuelve, camiseta-uso-carrera-anclas.png.
2 forro interior + quitar empuje de cabeza: no resuelve, -contacto.png.
3 cage de triángulos sobre todo el tejido: pecho se arruga mal, -superficie-
actualizada.png. Rechazado para producto.
4 cage limitado por campo de manga, torso por skinning estable: inicialmente
faltó actualizar bindMatrixInverse del proxy al moverse el root (torso desaparecía).
Corregido en pet-cloth-wrap.js; test de traslado de root añadido. Pecho estable
pero aún pliegues de hombro incorrectos: -superficie-mangas-corregida.png.
NO repetir estos mismos ensayos como si fueran soluciones verificadas.

Se restauró camiseta aprobada de reposo: SHA73f842ce59c088c5fecca8fab2c62abeb7ac5ec435f087c57948c91e2cac0d8a.
Experimento separado sewn_shirt_love_penguin_surface_experiment.glb y maestro
CAMISETA-COSIDA-penguin_surface_experiment.blend. Generador opt-in --surface-wrap;
sin ese argumento reconstruye la camiseta aprobada sin forro/cage.
Nuevo código: wardrobe_surface_wrap.py, pet-cloth-wrap.js, prueba
pet_cloth_wrap_test.mjs. Aplicación opt-in vía atributo nidoSurfaceWrap; ningún
producto de tienda obtiene ese atributo. Revisiones cloth-wrap-3 evitan cargar
JS anterior mientras se revisa; no cambian animaciones publicadas.
11 tests pasan (camiseta/cobertura, ocho detalles cuello/pies, cage rest/finite/
traslado y mascota inalterada). No validan ausencia visual de pliegues.

Pendientes: resolver deformación con referencia animada real y pesos específicos
de raíz/corona de manga, conservando malla/textura/rig original; después adaptar
patrón a otras mascotas y rehacer chaqueta/abrigo/vestido/sudadera con mismo acabado.
No se terminaron prendas adicionales en este bloque; no activar ni publicar.

## Prueba de carrera y salto autorizada, 2026-10-13
Usuario autoriza corregir el movimiento y pide prueba dinámica de carrera/salto
antes de aplicarlo, evitando rigidez. Se clonaron clips originales (no GLB/rig):
Natural_Jump y Wardrobe_Run. Compresión angular suave tanh evita mesetas de un
clamp rígido; limita cabeza/espina/hombros/brazos y articulaciones Hand del rig
humanoide. Conserva íntegros tiempos y pistas de piernas/pies y traslación Y.
Hips conserva giro hasta .32 salto/.24 carrera; brazos .16 salto/.12 carrera.
No se modifican Running/Regular_Jump del juego publicado. Revisiones dynamic-
cloth-4 y surface-fit-4 cargan realmente JS reciente, no imports anteriores.
Se corrigió bug del visor: Natural_Jump antes figuraba en menú, pero reviewMotion
solo aceptaba Running/Regular_Jump, de modo que no se reproducía la comparación.
Ahora acepta ambos nuevos clips solo en petOnly.

Visor nuevo assets/runner/wardrobe-motion-review.html compara ambas animaciones
con camiseta/conjunto Dulce, vistas, ciclo vivo y fases 0/25/50/75. Captura
prueba-carrera-salto-nuevos-encaje-t50.png. Pasa 10 pruebas: ocho de animación
para cuatro mascotas (originales/timing/piernas sin cambios, aletas siguen
animadas), activo de camisa y restauración de cobertura. No aprobación visual
de las otras mascotas ni cierre de todo inventario.

Camisa conserva geometría aprobada pero usa campo de manga mediante NidoSleeve,
cuello Neck y preserve_authored_contact (sin empuje heurístico al cráneo) para
estos clips moderados. SHA4cea182e66c13c36ef8bdc5182312b2c6b9ec7c746bed4b9c05c839e0c6a27f5.
A .5 se reduce deformación grande anterior, pero quedan pequeñas marcas oscuras
en raíz de hombro que requieren revisión. No certificar perfecto o sin pliegues.
Esperar criterio del usuario sobre dinamismo de esta prueba antes de mover
la nueva animación al recorrido publicado. Luego continuar el resto de prendas.


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
