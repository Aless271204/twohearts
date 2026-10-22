# Compras de oro · candidata 1.3.3

Integración Google Play para `app.nido.twohearts`. Productos de consumo:
500 monedas US$0,99 (`nido_gold_500`), 2500 US$3,99 (`nido_gold_2500`),
10000 US$9,99 (`nido_gold_10000`). Precio final localizado desde Play.

El servidor verifica estado PURCHASED y cuenta ofuscada, registra un recibo único
por token, abona el saldo existente compartido y consume la compra en Google.
Las compras pendientes, canceladas, ajenas o desconocidas no entregan oro.
Reintentar un token no duplica el saldo. No se registran tokens sin cifrar.

No declarar cobros listos: falta credencial de cuenta de servicio con acceso solo
a pedidos de Nido y los permisos de verificación requeridos por Google, productos
en Console y prueba real mediante un tester con licencia antes de activar ventas.
El servidor falla cerrado mientras no existan `GOOGLE_PLAY_SERVICE_ACCOUNT`
y `NIDO_PLAY_BILLING_ENABLED=true`. La clave privada solo pertenece a los secretos
del servidor; nunca a Flutter, al repositorio ni al chat.

El banco ya está registrado en el perfil de pagos. Console muestra un aviso
urgente sin causa en la página a la que redirige. No afirmar que esté resuelto.
Google liquida las ventas según su calendario, comisiones e impuestos, no una
transferencia inmediata por cada compra. Las monedas no se canjean por dinero.

Falta conciliación automática de reembolsos y RTDN antes de un lanzamiento de pagos
a producción; la recuperación inicial depende de compras pendientes de Play al
iniciar sesión. No activar ventas públicas con esa tarea pendiente.

Otros cambios incluidos: contacto y CV por correo, controles sobre la escena 3D,
retirada de Explorar en 3D para habitaciones, récords solo Difícil cuando hay
selector, tres monedas por anuncio verificado sin espera ni límite diario.
No se alteraron saldos históricos ni recibos; las pruebas SQL usan una base aislada.
