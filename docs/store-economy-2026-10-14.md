# Economía de NIDO — 14 de octubre de 2026

## Decisiones aplicadas

Una sola moneda y un solo inventario. Gafas desde 50, camiseta sencilla 50,
otras prendas de cuerpo 120–180, calzado 100–140. Un conjunto Dulce cuesta 300:
gorra 70 + camiseta 50 + moño 50 + zapatillas 130. El precio corresponde al
producto y a su tamaño/complexidad; cambiar de mascota no aumenta el precio.
Los precios editables están en `lib/core/store_economy.dart`; el catálogo de
prendas está en `assets/runner/accessory-catalog.json`. El servidor decide el
precio del cobro. Una modificación local no altera el saldo.

Cuadros 60; plantas 100; lámparas 100–180; revestimientos 140–250;
muebles principales 250–450. Los veinte conceptos de habitación muestran
precio. Los artículos aún en prueba no se activaron silenciosamente para venta.

Cambiar el color de una prenda: vista previa gratis, desbloqueo de 10 de oro
por producto y color una sola vez; reutilización y vuelta al original gratis.
Se conservan bordados, suelas, metales y mapas de relieve. Hay dieciocho
prendas con cinco colores, comprobados contra los materiales de las cuatro especies.

## Paquetes y comisiones

| Oro | Precio USD | Tras 15 % | Tras 30 % | USD por 1.000 de oro |
|---:|---:|---:|---:|---:|
| 1.000 | 1,99 | 1,69 | 1,39 | 1,99 |
| 2.000 | 2,99 | 2,54 | 2,09 | 1,495 |
| 5.000 | 4,99 | 4,24 | 3,49 | 0,998 |

Cálculo: precio × (1 − comisión), redondeado a centavos. No es beneficio neto:
faltan impuestos, devoluciones, alojamiento, adquisición y mantenimiento.
Las comisiones se calculan normalmente sobre una base que puede excluir impuestos;
el importe real depende de la región y el contrato. Los precios mostrados son
referencias USD: cuando se configure facturación, se debe mostrar el precio
localizado devuelto por la tienda, no imponer este texto a todos los países.

Apple reduce al 15 % para desarrolladores aceptados en Small Business Program;
no basta con facturar poco: hay que inscribirse y ser aceptado.
[Apple](https://developer.apple.com/app-store/small-business-program/).
Google Play ofrece 15 % sobre el primer millón anual a inscritos en ese nivel y
30 % sobre el exceso. [Google](https://support.google.com/googleplay/android-developer/answer/112622?hl=es).
El escenario de 30 % sirve como comparación conservadora; no implica una tarifa
única para todos los países ni excepciones contractuales.

El paquete grande cuesta cerca de 50 % menos por unidad de oro que el pequeño.
Es una ventaja considerable: revisar compras repetidas y ritmo de nuevos artículos
antes de ampliar más el descuento. El vestuario activo del catálogo local suma
2.270; con 5.000 se pueden combinar toda esa ropa y una selección importante de
muebles, pero no se promete comprar absolutamente todo el inventario.

## Qué dicen los datos y qué aún no sabemos

AppsFlyer informó en su reporte de juegos de 2024 que menos del 5 % de usuarios
compraba y más del 70 % de compradores repetía. Es una muestra agregada de juegos,
no el promedio de gasto de parejas latinoamericanas en NIDO.
[Reporte](https://www.appsflyer.com/company/newsroom/pr/gaming-app-report/).
Su estudio de monetización separa ARPU —todos los usuarios— y ARPPU —solo quienes
pagan—, y advierte de diferencias entre plataformas y regiones. Gran parte de la
muestra principal corresponde a Norteamérica y Europa occidental. No trasladar
sus ingresos medios directamente a Latinoamérica.
[Metodología](https://www.appsflyer.com/resources/reports/app-marketing-monetization-report-2024/).

No encontramos un promedio público representativo que permita afirmar cuánto
gastará nuestro usuario latinoamericano. Los precios son una hipótesis accesible
que debe contrastarse con conversión, mediana de gasto, repetición, retención D1/D7/D30,
ingreso neto por país y abandono tras compras. No confundir ARPPU elevado de una
minoría con disposición a pagar de la mayoría. Otros juegos usan monedas con
precios y catálogos propios: su cantidad de moneda no es una tasa de cambio para oro.

Ejemplo de planificación, no previsión: 1.000 usuarios y 2 % de compradores que
adquieren una vez el paquete de 2,99 producen 59,80 brutos; 50,83 tras 15 %,
antes de costes. La rentabilidad exige observar gasto y coste de adquisición reales.

## Publicidad y juego

Tres de oro por vídeo completado, hasta cinco en una ventana móvil de doce horas
por persona. Como máximo, treinta diarios si se aprovechan dos ventanas completas.
El anuncio aparece únicamente al pulsar «Ver publicidad» en el menú de minijuegos
o en la tienda. No hay publicidad insertada sobre una partida.
La carrera conserva 20 puntos = 1 oro. Ejemplos: 200 puntos → 10;
500 → 25; 1.000 → 50. Los puntos internos no son moneda de tienda directa.

Con cinco anuncios se consiguen 15, suficiente para un color con ahorro; 17 anuncios
completados permiten llegar a gafas de 50 sin jugar. El juego sigue siendo la vía
principal. El oro virtual no es dinero canjeable ni un coste monetario equivalente
uno a uno: su efecto económico es sustituir potenciales compras, que habrá que medir.

Por 100 impresiones, ingreso estimado = eCPM × 100 / 1.000. A eCPM 1/3/5,
los resultados son 0,10/0,30/0,50 USD. Son escenarios, no una promesa de tarifa.
[AdMob](https://support.google.com/admob/answer/15337570?hl=es).

## Activación pendiente y protección

IDs Android públicos proporcionados por el titular:
aplicación `ca-app-pub-4237033451731865~9326389277`;
unidad `ca-app-pub-4237033451731865/6701979953`.
La app solicita consentimiento mediante UMP. El SDK se carga únicamente al elegir
ver un vídeo. El callback local nunca acredita oro. El servicio verifica la firma
ECDSA de Google, una reserva autenticada y una transacción irrepetible.

En AdMob, configurar SSV con:
`https://nbldsimuntfeeynaadak.supabase.co/functions/v1/admob-reward`.
El SDK suministra automáticamente userId y el ticket aleatorio. La política del
servidor concede exactamente tres aunque la consola tenga otro reward_amount;
configurar también tres en la consola evita diferencias visuales.
Sin confirmar SSV y probar el flujo en Android, no activar `NIDO_LIVE_ADS`.
La compilación actual usa anuncios de prueba: no generan ingresos ni oro.
La app no está publicada; AdMob debe vincularse después a una tienda admitida
para su revisión. Google Play Console/App Store Connect siguen necesarios para
facturación real. Los paquetes no ejecutan cobros ficticios ni otorgan oro desde
el cliente. Los beneficios de crecimiento permanecen pendientes de los modelos.
