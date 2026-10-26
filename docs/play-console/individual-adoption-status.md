# Adopción individual · 26oct2026

Migración remota20261026143026_individual_pet_adoption_identity aplicada tras autorización humana expresa por rechazo inicial de revisión automática. SQL revisado en individual-adoption-applied.sql. Se conserva cada animal existente con UUID nuevo; no se borraron mascotas ni se cobraron adopciones a testers durante el despliegue.

Pruebas transaccionales dentro de la migración: compra individual5000->1000; reintento no cobra; saldo3999 rechaza sin cambio; adopción gratuita individual rechazada; dos pollitos conservan IDs/nombres al enlazarse; seleccionar/renombrar uno no cambia el otro; unión de mascota con pareja vacía no cobra; otro hogar y usuarios anónimos no pueden seleccionar/comprar. Datos y cuentas de fixture revertidos; consulta posterior confirma0cuentasfixture.

Privilegios posteriores: cliente sin SELECT/INSERT directo a animales; RPC porID sin accesoanon, síauthenticated. No se expusieron claves ni se ampliaron permisos de tablas.

App: aviso con enlace de cuentas y Adoptar4.000; muestra saldo y deshabilita confirmar sin oro; pide confirmación; habitación admite selección individual pagada; selector distingue dos mascotas iguales porID. No declarar disponible hasta terminar pruebas y publicar candidata.

Compatibilidad: mismos nombres de RPC de selección por especie; nuevo shared_pet_change_by_id para identidad individual. Snapshot conserva equipment y campos existentes. Mascotas compradas individualmente conservan propietario original y se mueven al contexto de sus miembros actuales sin clonación.
