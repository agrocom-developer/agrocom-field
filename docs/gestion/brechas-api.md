# Brechas de la API vistas desde la app

Lo que una pantalla necesita y el contrato (`agrocom-api`, `docs/api/openapi.yaml`) todavía no entrega. La app no inventa endpoints: degrada la pantalla y lo deja anotado aquí. Cada fila se elimina cuando el contrato lo cubre.

## Flavor cliente

| Falta en la API | Qué hace la app hoy |
|---|---|
| Varios terrenos en una solicitud. `POST /api/solicitudes` recibe un solo `terreno_id`. | Una solicitud por terreno: quien tiene varios lotes en una propiedad registra un terreno por lote y publica una solicitud por cada uno. |
| El teléfono y los datos de contacto del piloto adjudicado en la solicitud. `GET /api/solicitudes/{id}` solo trae `proveedor_id`. | El nombre del piloto sale de la oferta adjudicada (`GET /api/ofertas/{id}`); el contacto es el chat. |
| El número de ofertas vigentes en la lista de solicitudes. | Una lectura de las ofertas por cada solicitud abierta o con ofertas al cargar la lista. |
| Si el cliente ya calificó, en la lista de solicitudes. | Una lectura de calificaciones por cada solicitud calificada al cargar la lista. |
| Fotos del terreno (`POST /api/terrenos/{id}/fotos`), precio de referencia (`GET /api/referencias/precio`), confirmación de pago (`POST /api/solicitudes/{id}/pago-confirmado`) y edición de una solicitud (`PUT /api/solicitudes/{id}`), descritos en `negociacion-contrato.md` pero ausentes de `openapi.yaml`. | El cliente no sube fotos del terreno, no ve un precio de referencia ni marca el pago; el precio se cambia con `POST /api/solicitudes/{id}/precio`. |
| La ruta de las fotos aprobadas del dron en la oferta. `proveedor.dron.fotos` llega vacío en los datos de demostración. | Muestra las fotos cuando traen `url`; si no, solo marca, modelo y capacidad. |
| Dosis, producto y tipo de aplicación como campos. Solo hay `producto_indicado` (texto) y `tipo_aplicacion`. | El producto viaja como texto escrito o elegido; el tipo de aplicación se deduce del producto. |
| Fecha de creación de la solicitud en la lista. | Usa el historial (detalle) o `publicada_en`. |
| Contorno del terreno cuando `geometria` es nula. | Dibuja un cuadrado de reserva centrado en la zona, con la superficie del terreno, solo para ubicarlo en el mapa. |
| Catálogo de productos y cultivos sugeridos. | Listas fijas en la app. |
| Calificaciones que el proveedor da al cliente (son privadas por diseño). | Solo se muestra el promedio y el conteo de la ficha del cliente. |
| Marcar un aviso del inicio como leído desde la tarjeta. | Descartar un aviso solo lo oculta en la sesión. |
| Entrega en tiempo real de mensajes y de ofertas. | Sondeo corto con la pantalla abierta (5 s el chat, 15 s el seguimiento, 20 s las ofertas); el contrato por cursor permite cambiar el transporte sin tocar los repositorios (ADR 0017). |
