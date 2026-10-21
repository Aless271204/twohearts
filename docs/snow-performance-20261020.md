# Guerra de Nieve — rendimiento, 20 de octubre de 2026

Se almacena el escenario estático (imagen, plataformas, sombras) en un lienzo separado. Se vuelve a crear al cambiar de mapa o terminar de cargar la imagen. Nieve, jugadores y proyectiles siguen animados. Prueba de 91 fotogramas confirma una sola construcción del escenario.

Mascotas: resolución ajustada al ancho mostrado, máximo 1280 px, sin multiplicar por densidad de pantalla ni multisampling. Se reutiliza el vector de posición de la mano. No se modifican GLB, ropa ni reglas del servidor.

Presentación limitada a 30 fps; simulación mantiene su paso fijo de 30 Hz y las animaciones reciben el tiempo acumulado entre dibujos. Una pestaña oculta no dibuja; la conexión online sigue consultándose para conservar la sala.

Validación: nueve pruebas de reglas y caché de render aprobadas. Pendiente medir FPS en el teléfono del usuario: estas pruebas no certifican fluidez visual ni latencia de red. La publicación de este parche es web; el APK 1.3.2 previamente entregado conserva la versión anterior.
