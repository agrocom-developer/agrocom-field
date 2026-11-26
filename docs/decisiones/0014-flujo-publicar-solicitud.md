# ADR 0014 — Flujo «Publicar solicitud» del flavor cliente

**Estado:** Aceptada (decisión revisable) · **Serie:** ADR propios de `agrocom-field`.

## Contexto

Publicar una solicitud es la acción principal del cliente del marketplace (`agrocom-api`, `docs/especificacion/marketplace.md` y `negociacion-contrato.md`; ADR 0016 de este repo). El flujo necesita un terreno con geometría, una superficie en decimal exacto, los datos que un piloto necesita para decidir si oferta y el precio por hectárea que propone el cliente. Al publicar, la solicitud queda abierta y visible para los pilotos. El flavor cliente es online-first: no tiene outbox.

## Decisión

### Estado y capas

- El formulario vive en `SolicitarCubit` (`lib/cliente/solicitar/presentation/`), con un `SolicitarEstado` inmutable. Los widgets no guardan datos del formulario: un fallo de envío o un cambio de paso nunca pierde lo escrito.
- Las reglas que se validan en el dispositivo (anticipación mínima de un día, 14 días ofrecidos, la sugerencia de marcar la solicitud como urgente, formato y tope de hectáreas, formato del precio; la urgencia ya no se deriva de la fecha: la declara el cliente con una fecha límite, ADR 0023) están en `ReglasSolicitud` (`domain/`). Un terreno registrado limita las hectáreas que se pueden pedir a las suyas. El servidor las vuelve a validar y su mensaje llega a la pantalla tal cual.

### Cuatro pasos, una acción por pantalla

1. **Lote.** Un terreno guardado o un contorno dibujado en el mapa.
2. **Aplicación.** Hectáreas a fumigar, cultivo y producto.
3. **Cuándo.** Fecha deseada, cómo se llega al lote (solo para un terreno nuevo; uno registrado trae sus accesos) y observaciones.
4. **Precio.** El precio por hectárea que propone el cliente, el total estimado (hectáreas por precio, en decimal exacto) y un resumen. «Publicar solicitud» es la acción principal.

El precio no es una tarifa: los pilotos aceptan ese precio o contraofertan. La app no sugiere ni limita el monto; el máximo de sanidad lo valida el servidor.

### Idempotencia y red

- La clave de idempotencia nace con el cubit, al abrir el formulario, y viaja en cada envío. Un segundo toque mientras viaja el primero se descarta en el cubit; un reintento tras un fallo reutiliza la misma clave.
- La publicación crea un borrador (`POST /solicitudes`) y lo publica (`POST /solicitudes/{id}/publicar`). El `uuid_cliente` del borrador se deriva de la clave y de lo escrito: reintentar sin cambios devuelve el mismo borrador y cambiar un dato crea otro. Si la publicación ya había llegado y la respuesta se perdió, el reintento recupera la solicitud en lugar de fallar.
- Sin conexión, `SolicitudRepositorio.publicar` lanza `SolicitudSinConexion`. El estado conserva el formulario completo y la acción principal pasa a «Reintentar publicación». Si el servidor rechaza la solicitud (por ejemplo, falta el teléfono de la cuenta), la pantalla muestra su motivo.

### Lote, mapa y superficie

- El terreno es un lote guardado o un contorno dibujado en el mapa (`flutter_map`, teselas abiertas). Un contorno dibujado se guarda primero como terreno nuevo con su polígono, su superficie y sus accesos, y la solicitud lo usa.
- El área del contorno se calcula en el dispositivo con `areaMetrosCuadrados` (proyección plana local y fórmula de Gauss, en `double` porque las coordenadas lo son) y se convierte a `Decimal` con un decimal en un único punto, `hectareasDePoligono`. Desde ahí la superficie es una magnitud de negocio y no vuelve a `double` (ADR 0002). El cliente puede corregirla a mano; cambiar de terreno vuelve a proponer la calculada.
- El mapa no usa doble toque para acercar: ese gesto retrasa 250 ms cada toque simple, y aquí un toque elige un lote o marca una esquina. El zoom es por pellizco.
- Un contorno que se cruza a sí mismo no se rechaza en el dispositivo; el servidor valida la geometría.
- Una solicitud usa un solo terreno. Para varios lotes se registra un terreno por lote y se publica una solicitud por cada uno.

### Después de publicar

- La solicitud publicada abre su detalle, que dice «Buscando piloto» y muestra el precio propuesto. Las ofertas llegan a medida que los pilotos las hacen; el cliente las compara desde el detalle (ADR 0013).
- El cliente puede cambiar su precio o cancelar mientras la solicitud no esté adjudicada.

### Demo

- `SolicitudDemo` publica en memoria una solicitud abierta con el precio escrito. Con las respuestas automáticas de la demo, un piloto acepta el precio unos segundos después y otro ofrece un 12 % más.

## Consecuencias

- Las pruebas viven en `test/cliente/solicitar/`: reglas, cubit, widgets (incluye texto al 200 %, guías de accesibilidad y arrastre de esquinas) y goldens de cada pantalla y estado en claro y oscuro, a 360 y 412 de ancho y en iPad.
- `NavegacionAdaptativaCampo` admite `anchoCompleto` para las pantallas con panel dividido.
