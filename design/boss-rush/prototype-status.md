# Guardianes del Alba — integración Android 1.2.4+19

El antiguo prototipo de teclado se ha sustituido por solitario autenticado y
pareja online mediante código de sala entre dos celulares. La aventura se abre
desde Juegos, sin requerir un navegador externo. En navegador sin cuenta solo
hay una previsualización sin oro; no se ofrece pareja local en el producto.

Implementado: ruta ampliada, fácil/medio/difícil (5/3/1 corazones), difícil sin
curación ni corazones extra y más rápido; dos distribuciones táctiles, audio de
ambiente y efectos, derrota con mascota y Musgo. El inventario equipado validado
por servidor se representa en pixel art. Solo se eligen mascotas adoptadas.

Pareja: canales privados por participante, intercambio de entradas/snapshots,
pausa ante desconexión y salida compartida. Una victoria requiere replay
reproducible, entradas autenticadas y confirmación del segundo participante.
Premios individuales idempotentes, solo recibe exactamente la mitad del
correspondiente premio de pareja, tope de 200 diarios por usuario para Guardian.

Pruebas reales con dos cuentas sintéticas: canales privados y rechazo de una
tercera cuenta, especie bloqueada rechazada, equipo del inventario recibido;
victoria validada, pago de ambos, reintento sin duplicados y replay falsificado
rechazado. Se repitieron antes de preparar esta versión.

El arte todavía utiliza seis poses por mascota, no animaciones dibujadas con
muchos fotogramas intermedios. Las pruebas locales y de servidor no equivalen a
una evaluación humana de juego en dos teléfonos. Véanse los detalles visuales
y limitaciones en docs/guardian-pixel-footwear-review.md.

Distribución prevista: APK de prueba firmado, no publicación en Google Play.
Pagos reales no están habilitados. La entrega exige compilación, prueba Android
y comprobación del contenido y firma del APK.
