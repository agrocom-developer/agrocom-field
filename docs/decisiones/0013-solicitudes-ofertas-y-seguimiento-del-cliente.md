# ADR 0013 — Solicitudes, ofertas, seguimiento, calificación y reclamo en el flavor cliente

**Estado:** Aceptada (decisión revisable) · **Serie:** ADR propios de `agrocom-field` · Contrato: `docs/especificacion/negociacion-contrato.md` de `agrocom-api` y ADR 0016 y 0017 de este repo.

## Contexto

El cliente publica su solicitud con un precio por hectárea, recibe ofertas de varios pilotos, las compara, elige una (o contraoferta) y, una vez adjudicada, ve cómo avanza el trabajo, conversa con el piloto, mira su última ubicación, revisa el precio final, califica y, si hay desacuerdo, reclama. El flavor `cliente` es online-first y no tiene outbox (ADR 0009 de arquitectura): negociar es una decisión entre dos partes que el servidor resuelve de forma atómica.

## Decisión

### Dominio del cliente (`lib/cliente/`)

El dominio de la negociación vive en el flavor, junto a las pantallas que lo usan; lo que comparte con otros flavors (`Lote`, `GeoPunto`, `FallaMarketplace`, calificación y motivos de reclamo) sigue en `lib/nucleo/marketplace/dominio/`.

- `Solicitud` y `EstadoSolicitud` (`solicitudes/domain/`): abierta, con ofertas, adjudicada, en ejecución, finalizada, calificada, disputada, expirada y cancelada. Hectáreas, precios y montos son `Decimal`. El precio final es el que calcula el servidor (hectáreas ejecutadas por precio acordado); la app no recalcula montos congelados.
- `lineaDeTiempo(solicitud)`: función pura que arma los seis puntos que ve el cliente (publicada, ofertas, piloto elegido, fumigación, precio final, calificación). Una solicitud cancelada o expirada se detiene donde quedó y no deja nada «en curso».
- `OfertaRecibida`, `ProveedorOfertante` y `EstadoOferta` (`ofertas/domain/`): cada oferta lleva su ronda, su autor (el piloto abre y el cliente responde), si es definitiva, su vencimiento, la distancia, la calificación del piloto, su tasa de cancelación y el dron con sus fotos aprobadas. Qué se puede hacer sale de `autor`, `estado`, `es_definitiva` y `vence_en`; la app no replica el máximo de rondas ni las vigencias.
- `AvanceServicio`, `FotoAvance`, `UbicacionPiloto` y `MensajeChat` (`seguimiento/domain/`).
- `EtiquetaCalificacion` y `CalificacionEmitida`: el catálogo cerrado de etiquetas que el cliente aplica al piloto.
- `MotivoProblema`, `ReporteProblema` y `ProblemaReportado`: los motivos son los de la política de disputas. En la interfaz se llama «reportar un problema»; del lado servidor es una disputa.

### Repositorios

| Interfaz | Lee | Escribe |
|---|---|---|
| `SolicitudesRepositorio` | Lista (con caché de lectura) y detalle | Cambiar el precio, cancelar con motivo, renovar |
| `SolicitudRepositorio` | Terrenos, sugerencias de cultivo y producto | Publicar (terreno nuevo, borrador y publicación) |
| `OfertasRepositorio` | Ofertas de la solicitud | Aceptar, contraofertar, rechazar |
| `SeguimientoRepositorio` | Avance con fotos, ubicación del piloto, mensajes (por cursor) | Mensajes, lectura |
| `CalificacionRepositorio` | Calificación emitida y recibidas | La calificación al piloto, con etiquetas y comentario |
| `ProblemaRepositorio` | El reclamo de la solicitud | El reclamo |

- Cada escritura es de un solo actor (el cliente) sobre un registro propio y lleva una clave de idempotencia que nace en el dispositivo y se reutiliza en cada reintento: la publicación, la contraoferta, el mensaje, la calificación y el reclamo.
- Todas requieren red. Sin conexión lanzan `SinConexion`; la pantalla conserva lo que el cliente ya escribió u eligió y ofrece reintentar. Nada se encola.
- Un `409` de la negociación (`oferta_no_vigente`, `solicitud_ya_adjudicada`, `equipo_no_disponible`) llega como `OfertaCambio` con el mensaje del servidor; la pantalla lo explica y recarga las ofertas. `chat_cerrado` llega como `ChatCerrado` y deja el chat en solo lectura.
- Los repositorios de red comparten `FuenteSolicitudes`, que guarda en memoria lo último leído, resuelve el nombre del piloto adjudicado y la calificación emitida, y se vacía al cerrar sesión. El token y la sesión viven en el almacenamiento seguro; un `401` borra el token y vuelve al acceso.
- Los repositorios demo comparten `AlmacenDemoCliente`: cinco solicitudes sembradas (con ofertas, en ejecución, finalizada, calificada y expirada), ofertas, avance, ubicación y chat en memoria. Con `respuestasAutomaticas` (la demo que corre `main_cliente.dart`) los pilotos simulados ofertan unos segundos después de publicar, responden las contraofertas con el punto medio y contestan el chat. `AlmacenDemoCliente.sinRed` simula la falta de red.

### Estado de pantalla

Cada pantalla tiene su `Cubit` (`HistorialCubit`, `SolicitudDetalleCubit`, `OfertasCubit`, `SeguimientoCubit`, `ChatCubit`, `CalificarCubit`, `ReportarProblemaCubit`) con fases explícitas de carga, contenido, error y sin conexión. Con datos ya en pantalla, si la red se corta se conserva lo último conocido y se marca como desactualizado. `OfertasCubit` vuelve a leer cada 20 s, `SeguimientoCubit` cada 15 s y `ChatCubit` cada 5 s mientras la pantalla está abierta; los tres aceptan un intervalo nulo para las pruebas.

### Interfaz

- **Lista de solicitudes.** Resumen de hectáreas fumigadas con un gráfico de barras de los últimos seis meses (`fl_chart`), filtro simple y una tarjeta por solicitud con su estado, el precio por hectárea y, según el estado, el número de ofertas, el avance o el piloto.
- **Detalle.** Una sola acción principal según el estado: comparar las ofertas, ver el seguimiento y el chat, calificar o volver a abrir una solicitud expirada. Cambiar el precio y cancelar (con motivo obligatorio) son acciones secundarias mientras se negocia. Reportar un problema está disponible con la solicitud finalizada o calificada.
- **Ofertas.** Tarjetas ordenables por menor precio, mejor calificación o más cerca; la de menor precio va marcada. Cada una muestra el precio por hectárea y el total, cuánto se aparta del precio del cliente, el piloto con su calificación, el dron, la distancia, la tasa de cancelación y cuánto falta para que venza. Elegir pide una confirmación que dice qué pasa (se cierran las demás ofertas y el piloto recibe el contacto). Contraofertar abre una hoja con el total calculado mientras se escribe. En la última ronda solo se puede elegir o rechazar. Las ofertas que ya no se pueden responder quedan en una lista aparte.
- **Seguimiento.** Porcentaje y hectáreas, galería de fotos de avance (cada una se abre a pantalla completa), notas del piloto y un mapa pequeño con el lote y un solo punto: la última ubicación del piloto, con su antigüedad («hace 2 min») o «sin ubicación reciente». No hay ruta, estela ni tiempo estimado. El mapa no se arrastra, para que el dedo siga desplazando la pantalla. Las fotos del servidor se descargan con la sesión del cliente y se guardan en memoria mientras dure la sesión.
- **Chat.** Burbujas de texto con la hora, campo que conserva lo escrito si el envío falla, y solo lectura cuando el plazo cierra.
- **Precio final.** Cuando la solicitud finaliza se muestra el precio a pagar, hectáreas ejecutadas por precio acordado, con el texto de que el pago es directo al piloto y fuera de la app.
- **Calificación.** Hoja inferior de dos toques (estrella y enviar); las etiquetas y el comentario aparecen después de elegir la estrella y son opcionales.
- Los botones de texto usan `PaletaCampo.acentoTexto`: el lima de marca no alcanza el contraste AA como color de texto sobre fondo claro.
- Con el texto ampliado por encima de 130 % las filas «etiqueta … valor», los segmentos de orden y el filtro de la lista pasan a una columna.

### Pruebas

- `test/cliente/red/`: mapeo de la solicitud y la oferta, traducción de errores, repositorios de red contra un servidor falso (incluidos los `409` de la negociación) y publicación.
- `test/cliente/cubits_cliente_test.dart`: los cubits y la línea de tiempo contra los repositorios demo.
- `test/ui/ui_negociacion_cliente/flujos_test.dart`: recorridos completos de cada pantalla.
- `test/ui/ui_negociacion_cliente/goldens_test.dart`: cada pantalla principal en claro (360 y 412 de ancho), oscuro (412) y con el texto al 200 % (360); los estados de carga, vacío, error, sin señal, éxito y los diálogos, una vez. Corren en macOS, como el resto de los goldens del repo.

## Consecuencias

- Las pantallas y los cubits no conocen `dio`: solo las implementaciones de red de `cliente/*/data/` lo usan, por `ClienteHttp`.
- Las fotos de la demo son las imágenes de marca empaquetadas en `assets/imagenes/`.
- Una solicitud usa un solo terreno (`terreno_id`). Un cliente con varios lotes en una misma propiedad registra un terreno por lote y publica una solicitud por cada uno; el contrato no agrupa terrenos en una solicitud.
