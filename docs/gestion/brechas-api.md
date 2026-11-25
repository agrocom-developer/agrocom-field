# Brechas de la API vistas desde la app

Lo que una pantalla necesita y el contrato (`agrocom-api`, `docs/api/openapi.yaml`) todavía no entrega. La app no inventa endpoints: degrada la pantalla y lo deja anotado aquí. Cada fila se elimina cuando el contrato lo cubre.

## Flavor cliente

| Falta en la API | Qué hace la app hoy |
|---|---|
| Varios terrenos en una solicitud. `POST /api/solicitudes` recibe un solo `terreno_id`. | Una solicitud por terreno: quien tiene varios lotes en una propiedad registra un terreno por lote y publica una solicitud por cada uno. |
| El teléfono y los datos de contacto del piloto adjudicado en la solicitud. `GET /api/solicitudes/{id}` solo trae `proveedor_id`. | El nombre del piloto sale de la oferta adjudicada (`GET /api/ofertas/{id}`); el contacto es el chat. |
| El número de ofertas vigentes en la lista de solicitudes. | Una lectura de las ofertas por cada solicitud abierta o con ofertas al cargar la lista. |
| Si el cliente ya calificó, en la lista de solicitudes. | Una lectura de calificaciones por cada solicitud calificada al cargar la lista. |
| Edición de una solicitud (`PUT /api/solicitudes/{id}`), descrita en `negociacion-contrato.md` pero ausente de `openapi.yaml`. | El precio se cambia con `POST /api/solicitudes/{id}/precio`. |
| La ruta de las fotos aprobadas del dron en la oferta. `proveedor.dron.fotos` llega vacío en los datos de demostración. | Muestra las fotos cuando traen `url`; si no, solo marca, modelo y capacidad. |
| Dosis, producto y tipo de aplicación como campos. Solo hay `producto_indicado` (texto) y `tipo_aplicacion`. | El producto viaja como texto escrito o elegido; el tipo de aplicación se deduce del producto. |
| Fecha de creación de la solicitud en la lista. | Usa el historial (detalle) o `publicada_en`. |
| Contorno del terreno cuando `geometria` es nula. | Dibuja un cuadrado de reserva centrado en la zona, con la superficie del terreno, solo para ubicarlo en el mapa. |
| Contactos de referencia de una empresa (nombre, celular, cargo; al menos uno). `POST /api/clientes/registro` y `Cliente` solo traen `tipo`, `razon_social`, `documento_fiscal` y un `telefono`. | El registro permite elegir Persona o Empresa y envía razón social y NIT; la cuenta tiene un solo contacto (quien la usa) y la pantalla lo avisa. Cuando el contrato ofrezca contactos, se agrega el bloque «Contactos de referencia» detrás de la selección Empresa. |
| Catálogo de productos y cultivos sugeridos. | Listas fijas en la app. |
| Calificaciones que el proveedor da al cliente (son privadas por diseño). | Solo se muestra el promedio y el conteo de la ficha del cliente. |
| Marcar un aviso del inicio como leído desde la tarjeta. | Descartar un aviso solo lo oculta en la sesión. |
| Entrega en tiempo real de mensajes y de ofertas. | Sondeo corto con la pantalla abierta (5 s el chat, 15 s el seguimiento, 20 s las ofertas); el contrato por cursor permite cambiar el transporte sin tocar los repositorios (ADR 0017). |

## Datos listos, pantalla pendiente

La capa de datos ya cubre estas rutas (ADR 0020); falta la pantalla que las use.

| Ruta | Pantalla que falta |
|---|---|
| `GET /api/referencias/precio` | El precio de referencia junto al campo de precio al solicitar (cliente), y en la hoja de oferta del piloto. |
| `PUT` y `DELETE /api/perfil/foto` | Elegir, cambiar y quitar la foto de perfil en la cuenta (cliente) y en el perfil (piloto); mostrarla en la tarjeta del proveedor de la oferta. |
| `POST` y `DELETE /api/terrenos/{id}/fotos` | Galería de fotos del terreno al crearlo o editarlo (cliente); verlas en el detalle de la solicitud abierta (piloto). |
| `GET` y `POST /api/solicitudes/{id}/pago-confirmado` | «Ya recibí el pago» del proveedor titular en el servicio finalizado; el cliente ve el pago confirmado en el seguimiento. |
| `POST /api/dispositivos` y `DELETE /api/dispositivos/{token}` | Sin pantalla: se llaman al iniciar y cerrar sesión cuando exista un proveedor de push que entregue el token. |
