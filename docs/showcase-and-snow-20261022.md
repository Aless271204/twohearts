# Portadas de tienda y nieve · 22/10/2026

Guerra de Nieve utiliza 180 segundos de juego, además de su cuenta atrás. La duración compartida se aplica al entrenamiento y al servidor online. Las partidas anteriores que ya tienen un estado guardado conservan su duración. La guarda SQL admite hasta 180 segundos; los clientes siguen sin permiso de liquidar recompensas. No se cambian precios ni recompensas.

Se renuevan las once ilustraciones del carrusel (ocho habitaciones y tres outfits), con más contraste, luz cálida y profundidad. Se mantienen los diseños y artículos de las imágenes anteriores como referencia. Son ilustraciones promocionales basadas en los objetos del juego; no son capturas nuevas de los GLB.

Herramienta: image_gen integrada. Originales y prompts completos en `design/store-carousel-v2/`; versiones WebP de 1024 píxeles en `assets/images/products/showcases-v2/`. Peso conjunto aproximado: 743 KB. La mecánica del carrusel y el encuadre completo (`BoxFit.contain`) permanecen iguales.

Verificación: simulación reproducible de 180 segundos, tres mapas, cuatro jugadores y cuenta atrás; guarda de servidor rechaza 181 segundos y mantiene abono idempotente; revisión de las once imágenes y prueba de navegación de portadas en teléfono.
