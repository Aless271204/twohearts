# NIDO: progresión y microtransacciones

Análisis preparado el 8 de octubre de 2026. Propuestas para validar; no son precios publicados ni productos de pago activos.

## Evidencia disponible

| Indicador | Resultado | Alcance |
| --- | --- | --- |
| Ingreso por usuario que paga, juegos casuales | US$7,26 | Global, acumulado durante los primeros 90 días desde la instalación |
| Ingreso por usuario, incluyendo quienes no pagan | US$1,34 | Global, casuales, misma ventana de 90 días |
| Conversión de compradores de una sola compra | 6,51% | LATAM, agregado regional de aplicaciones, ventana de 30 días |
| Conversión de compradores recurrentes | 3,09% | LATAM, mismo agregado; no equivale a porcentaje de repetición entre los compradores |

Fuente: [AppsFlyer, State of App Monetization 2026](https://www.appsflyer.com/resources/reports/app-marketing-monetization-report/). Muestra de compras verificadas de enero de 2025 a marzo de 2026. Las métricas regionales no describen específicamente juegos de mascotas ni aplicaciones para parejas.

[Sensor Tower, State of Mobile Gaming 2025](https://sensortower.com/blog/state-of-mobile-gaming-2025) reporta crecimiento interanual del ingreso de compras en juegos móviles de LATAM de 13% en 2024. Es crecimiento del mercado, no gasto individual.

No encontramos un promedio público comparable del gasto mensual de una persona latinoamericana en una app como NIDO. Tampoco podemos inferirlo dividiendo ingresos de videojuegos de todas las plataformas entre habitantes o jugadores. El promedio entre compradores difiere del promedio entre todos los usuarios, y una ventana acumulada de 90 días no es una suscripción mensual. Los datos publicados no permiten calcular intervalos de confianza para NIDO.

## Progresión media propuesta

- Una mascota inicial gratis, elegida y nombrada por la pareja.
- Segunda, tercera y cuarta adopción: nivel compartido 8, 16 y 24, respectivamente, más 3, 7 y 14 días distintos de cuidado. Ambos requisitos deben cumplirse. Los días son mínimos de elegibilidad, no una promesa de tiempo para llegar al nivel.
- Cada mascota conserva su nombre y experiencia propios. Etapas: cría desde nivel 1, juvenil desde 5 y adulta desde 10.
- Ajustar la experiencia después de medir cuánto tardan parejas reales en progresar. No endurecer el cuidado para forzar una compra.
- La compra opcional puede adelantar una adopción y ofrecer personalización; mantener la vía gratuita y las mismas reglas de récords.

La implementación visual actual de las etapas cambia el tamaño uniformemente; todavía no hay tres modelos anatómicos diferentes por especie. La migración de familia y crecimiento está preparada pero pendiente de aprobación y aplicación.

## Catálogo de prueba

Referencias en dólares para comparar opciones. Se deben definir precios locales por país, capacidad de compra e impuestos de la tienda, no solo convertir divisas. No hay descuentos porcentuales hasta establecer precios individuales reales.

| Oferta | Contenido propuesto | Precio inicial a probar |
| --- | --- | --- |
| Primer look | Moño básico y bufanda de corazones | US$1,49 |
| Paseo juntos | Camiseta amor, gafas de corazón y mochila de corazón | US$2,99 |
| Colección especial | Corona dorada y sombrero de flores | US$3,99 |
| Nueva compañía | Una adopción anticipada y dos accesorios elegibles | US$4,99–6,99 |

Una compra beneficia a la pareja y no exige que ambos vuelvan a pagar. Todos los accesorios necesitan ajuste comprobado en las cuatro especies y en sus tamaños antes de venderlos. Evitar combos con objetos que la pareja ya posee; mostrar el contenido y beneficio antes del pago. No ofrecer mejoras de velocidad, colisiones o puntaje.

Conservar LoveCoins como moneda ganada jugando. Definir los costes gratuitos a partir del ingreso real de monedas por sesión y de los límites del servidor. Los artículos comunes pueden obtenerse jugando; variantes especiales pueden venderse con precio claro. La voz y el cuidado compartido deben aportar valor cotidiano sin obligar a comprar para conservar el vínculo.

## Escenarios económicos, no pronósticos

Supuestos: 10.000 parejas activas en un mes, una cesta promedio mensual de US$3 por pareja compradora.

| Conversión mensual supuesta de parejas activas | Parejas compradoras | Ingreso bruto mensual |
| --- | --- | --- |
| 1% | 100 | US$300 |
| 3% | 300 | US$900 |
| 5% | 500 | US$1.500 |

Son escenarios aritméticos propios. No se aplica directamente la conversión de instalaciones de AppsFlyer a parejas activas. Las cifras excluyen comisiones, impuestos, reembolsos, infraestructura y adquisición; no representan utilidad.

## Cómo validar antes de fijar precios

Medir por pareja: retención a 1, 7 y 30 días; actividad de ambos; tiempo hasta cada adopción; compras a 30 días; gasto entre compradores a 30 y 90 días; ingreso entre todas las parejas; recompra, reembolsos y errores de equipamiento. Segmentar Colombia, México y Brasil, plataforma y vía de adquisición.

Probar primero dos precios de un mismo combo, asignando la pareja completa a un grupo. No cambiar a la vez precio, contenido y dificultad. Elegir tamaño de muestra según conversión inicial y diferencia mínima de interés; pocos compradores producen estimaciones inestables. Evaluar ingresos junto con retención y satisfacción.

Antes de activar ventas: integrar facturación de la tienda, verificar compras en el servidor, restaurarlas, hacer idempotente la concesión de artículos y asociar los derechos de uso a la pareja. Una selección del cliente nunca debe conceder una adopción pagada.
