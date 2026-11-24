# ADR 0014 — Flujo «Solicitar fumigación» del flavor cliente

**Estado:** Aceptada (decisión revisable) · **Serie:** ADR propios de `agrocom-field`.

## Contexto

Solicitar un servicio es la acción principal del cliente del marketplace (`agrocom-api`, `docs/especificacion/marketplace.md` §3 y §6; ADR 0027, 0030 y 0034 de ese repo). El flujo necesita un terreno con geometría, una superficie en decimal exacto, una tarifa visible antes de confirmar y una respuesta clara a «¿y ahora qué pasa?» una vez enviada la solicitud. El flavor cliente es online-first: no tiene outbox.

## Decisión

### Estado y capas

- El formulario vive en `SolicitarCubit` (`lib/cliente/solicitar/presentation/`), con un `SolicitarEstado` inmutable. Los widgets no guardan datos del formulario: un fallo de envío o un cambio de paso nunca pierde lo escrito.
- `BusquedaProveedorCubit` sigue la asignación de un servicio a partir de `SolicitudRepositorio.observarBusqueda`.
- Las reglas que se validan en el dispositivo (anticipación mínima de un día, 14 días ofrecidos, urgencia, formato y tope de hectáreas) están en `ReglasSolicitud` (`domain/`). El servidor las vuelve a validar.

### Idempotencia y red

- La clave de idempotencia nace con el cubit, al abrir el formulario, y viaja en cada envío. Un segundo toque mientras viaja el primero se descarta en el cubit; un reintento tras un fallo reutiliza la misma clave.
- Sin conexión, `SolicitudRepositorio.solicitar` lanza `SolicitudSinConexion`. El estado conserva el formulario completo y la acción principal pasa a «Reintentar envío».

### Lote, mapa y superficie

- El terreno es un lote guardado o un contorno dibujado en el mapa (`flutter_map`, teselas abiertas). Un contorno dibujado viaja como un `Lote` nuevo con su polígono.
- El área del contorno se calcula en el dispositivo con `areaMetrosCuadrados` (proyección plana local y fórmula de Gauss, en `double` porque las coordenadas lo son) y se convierte a `Decimal` con un decimal en un único punto, `hectareasDePoligono`. Desde ahí la superficie es una magnitud de negocio y no vuelve a `double` (ADR 0002). El cliente puede corregirla a mano; cambiar de terreno vuelve a proponer la calculada.
- El mapa no usa doble toque para acercar: ese gesto retrasa 250 ms cada toque simple, y aquí un toque elige un lote o marca una esquina. El zoom es por pellizco.
- Un contorno que se cruza a sí mismo no se rechaza en el dispositivo; el servidor valida la geometría.

### Precio

- `EstimacionServicio` lleva el subtotal (hectáreas por tarifa por hectárea), los recargos explícitos y el total. La app muestra el desglose antes de confirmar.
- La app no cobra (ADR 0034 de `agrocom-api`). El resumen dice que el pago es al proveedor, fuera de la app, y que la comisión de Agrocom no se suma al precio del cliente.

### Después de confirmar

- La confirmación abre «Buscando proveedor»: muestra las dos rondas de la asignación en su orden real, propios primero y terceros después con el radio de búsqueda, y termina en el proveedor asignado o en «todavía no hay proveedor». Desde ahí se pasa al detalle del servicio.
- El radar de esa pantalla es una animación en bucle; representa una espera activa del servidor y queda quieto con movimiento reducido (sistema visual, §7).

### Demo

- `SolicitudDemo` usa una tarifa ficticia de Bs 90 por hectárea y un recargo ficticio del 10 % cuando el servicio se pide para el día siguiente. La búsqueda recorre las dos rondas (4 s cada una) y asigna un proveedor independiente, para que se vean las tres etapas.

## Consecuencias

- El repositorio de red del cliente implementa `SolicitudRepositorio` contra `POST /solicitudes`, `GET /solicitudes/{id}/estimacion` y el estado de asignación, sin tocar la interfaz.
- `VentanaHoraria` es una franja del día dentro de la fecha deseada; el contrato del servidor modela `ventana_desde` y `ventana_hasta` como fechas. El mapeo se define al escribir el repositorio de red.
- `NavegacionAdaptativaCampo` admite `anchoCompleto` para las pantallas con panel dividido.
- Las pruebas viven en `test/cliente/solicitar/`: reglas, cubits, widgets (incluye texto al 200 %, guías de accesibilidad y arrastre de esquinas) y goldens de cada pantalla y estado.
