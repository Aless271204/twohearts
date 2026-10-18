# NIDO 1.2.9+24 — integración para probar

Código:820b6214fe376ee1a649673a69c9d7765b6fee26. Compilación39096682460.

Incluye adopción después del enlace recíproco, llegada3D y habitación compartida;
cartera compartida, reparto confirmado10%por persona al separar; recompensas de
minijuegos y prenda no poseída tras victoria validada de Guardianes difícil;
salas Listo/Iniciar, ataques altos del jefe, patas animadas; power-ups de pong;
referencia misteriosa y cronómetro tras cargar ambos dibujos; indicadores de
aniversario/distancia y Home reorganizado; citas diarias con atribución;
recordatorios opcionales; carrera con brazos más visibles, pesos de ropa
corregidos, aceleración, lluvia/suelo que cae desde1.5km y tormenta desde2km.

Las mascotas originales se conservan. Las20prendas de cuerpo reciben corrección
de pesos sin alterar su geometría ni texturas. El ajuste adicional de forma del
hombro del pollito queda experimental y fuera de esta compilación: no se pudo
comprobar visualmente. Persisten detalles de acabado en esa unión; no presentar
esta prueba como ropa idéntica a la ilustración o lanzamiento de producción.

La llegada es una cinemática3D en tiempo real, no un video exportado; los pequeños
de adopción usan el modelo original a menor escala. Android tiene recordatorios
locales; aviso de ánimo en segundo plano depende del refresco del widget, no push
instantáneo. iOS sigue sin firma/compilación. Web permite probar navegación y
juegos; widgets del sistema y anuncios nativos requieren Android.

Pruebas de Node, topología, análisis Flutter, suite Flutter y compilación web:
correctas en CI. APK firmado y prueba de arranque Android pendientes de finalizar.
Completar esta nota con resultado, URL, tamaño y huella antes de entregar APK.
