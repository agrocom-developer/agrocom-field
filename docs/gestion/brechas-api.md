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
| Contorno del terreno cuando `geometria` es nula. | Dibuja un cuadrado de reserva centrado en el punto del terreno, con la superficie del terreno, solo para ubicarlo en el mapa. |
| Catálogo de productos y cultivos sugeridos. | Listas fijas en la app. |
| Calificaciones que el proveedor da al cliente (son privadas por diseño). | Solo se muestra el promedio y el conteo de la ficha del cliente. |
| Perfil público del piloto (pantalla 19): licencia verificada, servicios completados, hectáreas fumigadas, años en la plataforma, reseñas con comentario y auxiliar. La oferta solo trae `proveedor.{nombre, foto_url, calificacion, tasa_cancelacion, dron}`. | La pantalla muestra nombre, foto, calificación, número de calificaciones, cancelaciones y dron con año y capacidad. No inventa el chip «Licencia verificada» ni la sección de reseñas. |
| Preferencias de aviso del cliente (`/api/notificaciones/preferencias` existe; el flavor cliente no tiene repositorio). | El perfil del cliente no ofrece el interruptor «Avisos de ofertas». |
| Hectáreas fumigadas del cliente (estadística del perfil 17). | El perfil muestra lotes, servicios y calificación como cliente. |
| Marcar un aviso del inicio como leído desde la tarjeta. | Descartar un aviso solo lo oculta en la sesión. |
| Entrega en tiempo real de mensajes y de ofertas. | Sondeo corto con la pantalla abierta (5 s el chat, 15 s el seguimiento, 20 s las ofertas); el contrato por cursor permite cambiar el transporte sin tocar los repositorios (ADR 0017). |

## Datos listos, pantalla pendiente

La capa de datos ya cubre estas rutas (ADR 0020); falta la pantalla que las use.

| Ruta | Pantalla que falta |
|---|---|
| `PUT` y `DELETE /api/perfil/foto` | Elegir, cambiar y quitar la foto de perfil en la cuenta (cliente) y en el perfil (piloto); mostrarla en la tarjeta del proveedor de la oferta. |
| `POST` y `DELETE /api/terrenos/{id}/fotos` | Galería de fotos del terreno al crearlo o editarlo (cliente); verlas en el detalle de la solicitud abierta (piloto). |
| `GET` y `POST /api/solicitudes/{id}/pago-confirmado` | «Ya recibí el pago» del proveedor titular en el servicio finalizado; el cliente ve el pago confirmado en el seguimiento. |
| `POST /api/dispositivos` y `DELETE /api/dispositivos/{token}` | Sin pantalla: se llaman al iniciar y cerrar sesión cuando exista un proveedor de push que entregue el token. |

## Piloto: datos que llegan del catálogo y no se guardan

| Falta | Qué hace la app hoy |
|---|---|
| `contacto.cargo` y `contacto.empresa` de `servicios_asignados` (catálogo del piloto, PR #349 de la API). La tabla local `servicio_adjudicado` solo guarda `contacto_nombre` y `contacto_telefono`, y `ejecucion_sync_engine.dart` solo lee esos dos. Agregar las columnas es una migración de `drift` y un cambio en `nucleo/sync`, que esta fase no toca. | El dominio `ServicioLote` ya admite `contactoCargo` y `contactoEmpresa` y la pantalla del servicio los muestra cuando llegan (la demo los trae); con datos reales de `drift` quedan vacíos hasta que se agreguen las columnas (revisión línea por línea del dueño). |

## Chat y precio final (dependen de PR de la API)

La app consume `tipo`, `evento`, `url` y `bytes` de los mensajes, `POST /api/solicitudes/{id}/mensajes/fotos` y `GET /api/mensajes/{id}/archivo` (PR #354 de `agrocom-api`), y `GET /api/solicitudes/{id}/precio-final` y `POST …/precio-final/confirmar` (PR #353). Hasta que entren a `develop`, las pruebas usan los ejemplos de esos PR copiados en `test/fixtures/api_cliente/`.

