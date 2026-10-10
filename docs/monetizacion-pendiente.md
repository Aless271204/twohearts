# Cobros y anuncios: estado de preparación

El propietario confirmó que todavía no tiene Google Play Console, App Store Connect ni AdMob. No hay cobros reales ni anuncios vinculados.

## Configuración editable

`lib/core/store_packages.dart` define los tres paquetes de referencia en USD y la propuesta de anuncios: 30 monedas por video completado, máximo 5 al día por persona. Ambos canales están desactivados. La tienda muestra su estado pendiente, sin simular compras ni añadir oro.

Los importes de oro y los beneficios siguen sujetos a la revisión del catálogo completo. El crecimiento permanecerá pendiente de los modelos por etapas. No publicar la promesa de comprar todo el catálogo sin comprobar su coste total.

## Pendientes para activar

1. Terminar y revisar los catálogos, ajustes de accesorios y precios.
2. Crear las cuentas de distribución y de anuncios a nombre del titular que recibirá los ingresos.
3. Configurar los productos y sus identificadores, el bloque de anuncios recompensados y la información comercial requerida.
4. Integrar y probar compras de prueba, restauración, comprobación de recibos y recompensas verificadas en servidor. La asignación debe ser única por transacción para impedir duplicados.
5. Activar producción únicamente después de comprobar el flujo completo.

No basta con cambiar los indicadores de activación: aún falta integrar los proveedores. No enviar contraseñas, claves privadas ni información bancaria por el chat.
