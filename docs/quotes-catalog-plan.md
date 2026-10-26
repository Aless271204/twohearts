# Frases de autores — actualización del 26 de octubre de 2026

## Entrega concreta

El catálogo literario incorpora **50 extractos auténticos en español de 6 autores**:
Gustavo Adolfo Bécquer (30), Rubén Darío (14), Garcilaso de la Vega (3),
Francisco de Quevedo (1), Gutierre de Cetina (1) y Manuel del Palacio (1).
Cada registro identifica autor, obra, edición consultada, fecha de revisión y URL.
No son aforismos inventados ni frases «inspiradas» atribuidas a escritores.
Son pasajes de obras literarias, no necesariamente frases independientes.

Se sustituyen las tres entradas literarias anteriores (Bécquer y dos traducciones
propias de Austen y Shakespeare). Se conservan las otras nueve entradas existentes:
una bíblica, dos de cine/televisión y seis originales de NIDO. El catálogo activo
resultante contiene **59 entradas**, de las que **50 son literarias**.
Esta entrega no certifica nuevamente las nueve entradas heredadas.

## Fuentes y criterio editorial

- Bécquer: sección Rimas de Obras escogidas, edición digital 53552.
- Darío: Prosas profanas, edición digital 47650.
- Cetina y Palacio: poemas identificados en Las cien mejores poesías, antología 65880;
  Menéndez y Pelayo es el compilador, no el autor de estos versos.
- Garcilaso: Soneto V, texto primario de Wikisource, revisión 1496564.
- Quevedo: Amor constante más allá de la muerte, revisión 1543460 de Wikisource.

Solo se extraen los textos originales de autores fallecidos hace más de cien años;
no se copian prólogos, anotaciones modernas, ilustraciones ni traducciones ajenas.
Se regularizan espacios y mayúsculas al unir versos y se actualizan las antiguas
preposiciones/conjunciones á/é/ó. El signo … señala los pasajes que se cortan antes
del final de la oración. No se cambia el vocabulario del autor.

Los hashes y el método de consulta están en data/quotes/sources.json. Para las
fuentes de Wikisource el hash corresponde a la transcripción local del pasaje
consultado, no al HTML remoto; se indica expresamente. No es una licencia mundial
ni una certificación jurídica de todas las categorías del catálogo futuro.

## Mantenimiento y comprobación

La fuente editable es data/quotes/literary.es.json. Los IDs no deben reasignarse.
Ejecutar `python scripts/generate_literary_quotes.py` para generar el archivo Dart.
`--check` comprueba estructura, duplicados y sincronización sin necesitar internet.
Con `--source-dir outputs/quotes-sources` también compara hashes y texto con las
fuentes locales de la revisión; en Bécquer comprueba además el número de la rima.
Los textos completos descargados permanecen en outputs, fuera del control de versiones.

El selector mezcla todo el catálogo de forma determinista para cada pareja, usa día
UTC y no repite índices en un ciclo completo. Las dos cuentas obtienen la misma frase
sin importar el orden de sus IDs. Al cambiar el tamaño del catálogo comienza una
nueva distribución: no se promete continuidad del historial de ciclos anteriores.
El widget nativo y la tarjeta de la app usan ahora el mismo catálogo y selector.

Validación: 50 pasajes cotejados con sus fuentes, seis pruebas de rotación/integridad,
incluida una simulación de 1.000 entradas y el cambio de día en año bisiesto.
Esta actualización del repositorio no publica por sí misma una nueva versión Android.

## Objetivo anterior todavía pendiente

La petición completa era de 1.000 frases: 600 literarias, 100 bíblicas, 100 de
cine/series, 100 de canciones y 100 propias de NIDO. **No está completa**.
En esta entrega hay 50 de las 600 literarias; faltan 550 de esa categoría.
La proporción 60/10/10/10/10 no se presenta como conseguida en el catálogo actual.
Las nuevas letras de canciones y diálogos deberán verificarse en fuentes identificadas
antes de añadirse; no se rellenarán con citas inventadas ni atribuciones de redes sociales.
