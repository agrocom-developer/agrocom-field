# Visión del producto — `agrocom-field`

Este documento orienta a quien empieza a trabajar en este repo. Describe el producto, las tres superficies móviles y lo que cada una hace. Las reglas de trabajo están en `CLAUDE.md`; las decisiones de arquitectura, en `docs/decisiones/`; el contrato de API, en `docs/api/openapi.yaml` de `agrocom-api` (ruta local: `/Applications/MAMP/htdocs/agrocom-api`). Si este documento y el contrato no coinciden, manda el contrato.

## Qué es Agrocom

Agrocom es un **marketplace de servicio de fumigación con drones**, al estilo de las plataformas de transporte bajo demanda. Un cliente solicita un servicio sobre su lote; un proveedor lo acepta y lo ejecuta. Los drones son los «vehículos» del sistema.

- **Clientes**: dueños de campo o sus encargados. Solicitan, siguen y califican servicios.
- **Proveedores**: pilotos propios de Agrocom, pilotos independientes y dueños de drones de terceros, cada uno con sus auxiliares.
- **Agrocom**: capta clientes y es el nexo entre ambos lados; además es proveedor propio. La empresa también vende drones y entrega a cada comprador trabajo asegurado a través del marketplace.

### Asignación

Cuando un cliente solicita un servicio, el motor de `agrocom-api` lo ofrece primero a los pilotos y drones propios de Agrocom. Si ninguno acepta o está disponible, lo ofrece a proveedores externos, con ventana de tiempo, escalado por zona y calificación. Cada oferta se acepta o se rechaza; el primero que acepta a tiempo obtiene el servicio. El cliente y el proveedor se califican entre sí al terminar.

## Las tres superficies móviles

Un solo código Flutter, tres flavors (ADR 0009):

| Flavor | Quién lo usa | Qué hace | Conectividad |
|---|---|---|---|
| `cliente` | Dueño del campo o encargado | Registrarse, solicitar un servicio (lote en el mapa, hectáreas, producto, fecha), seguirlo en vivo, calificar al proveedor | Online-first, sin outbox |
| `piloto` | Piloto (control remoto del dron o celular) | Recibir y aceptar ofertas, gestionar perfil, documentos y dron, ejecutar el servicio asignado: condiciones, sesiones de vuelo, hectáreas, incidencias, evidencias, cierre | Ofertas con red; ejecución offline en el lote |
| `auxiliar` | Auxiliar del piloto | Registrar mezcla, recargas, baterías e incidencias del servicio en el lote | Offline en el lote |

Las superficies web (panel admin y motor del marketplace) viven en `agrocom-api`: aprobación de proveedores y auxiliares, moderación de calificaciones, asignación, comisión y reportes.

### Qué es online y qué es offline

- **El lote no tiene señal.** Lo que sucede entre aceptar el servicio y cerrarlo es offline-first: la UI lee de `drift`, toda escritura se inserta localmente y se encola en el outbox en una sola transacción, y cada registro nace con su `uuid_cliente`.
- **Aceptar o rechazar una oferta requiere red.** Es una competencia por tiempo entre proveedores; la respuesta va directo a la API, sin outbox. Es una excepción documentada y revisable (ADR 0009).
- **El cliente siempre opera con red.** La app abre con la última lista conocida y avisa claramente cuando no hay conexión.

## El recorrido de un servicio

1. **Solicitud.** El cliente dibuja o elige su lote en el mapa, declara hectáreas (decimal exacto), producto y fecha deseada. La solicitud viaja con una clave de idempotencia generada en el dispositivo.
2. **Oferta.** El motor ofrece el servicio. El proveedor la ve en su bandeja, con tiempo restante, zona y hectáreas, y la acepta o rechaza.
3. **Asignación.** Al aceptar, el servicio y los datos necesarios para ejecutarlo (lote, producto, límites de vuelo, datos de contacto) se bajan a `drift`. Desde aquí el flujo es offline.
4. **Ejecución.** El piloto abre el servicio, registra condiciones, abre y cierra sesiones de vuelo con hectáreas, registra incidencias con foto y cierra con la imagen del campo. El auxiliar registra mezcla y recargas. Todo se sincroniza cuando vuelve la señal; las evidencias, comprimidas a menos de 300 KB, viajan en una cola aparte.
5. **Seguimiento.** Mientras el servicio está activo, el cliente ve su avance en vivo: estado, posición del dron y hectáreas completadas.
6. **Calificación.** El cliente califica al proveedor en un registro propio; el proveedor lo ve y un admin lo modera. El proveedor califica al cliente en otro registro.

## Proveedores, auxiliares y drones

- El **proveedor independiente se registra solo**; un admin lo aprueba antes de que reciba ofertas.
- El **piloto registra a su auxiliar**; el admin lo aprueba.
- El **dron es el vehículo**: tiene matrícula, modelo, capacidad y estado, y pertenece a Agrocom o a un tercero. Conserva sus ciclos de batería. El resto del mantenimiento, inventario y contabilidad interna no vive en la app.
- Los **documentos del proveedor** (licencia de piloto, matrícula del dron, seguros) se suben desde su perfil y los revisa el admin.

## Arquitectura

- BLoC feature-first en tres capas (`presentation/`, `domain/`, `data/`) y un `nucleo/` compartido (ADR 0009).
- `cliente/`, `piloto/` y `auxiliar/` no se importan entre sí; solo importan de `nucleo/`.
- Cliente HTTP manual sobre `dio` (ADR 0001); decimal exacto para hectáreas y dinero (ADR 0002); configuración de entorno por `--dart-define-from-file` (ADR 0004); versionado SemVer automatizado (ADR 0007).
- Tema claro derivado del logo para `cliente` (ADR 0003) y modo campo de alto contraste para `piloto` y `auxiliar` (ADR 0008).
- Selector de rol del flavor `auxiliar` (ADR 0005).

### Sincronización del lote

1. Base local SQLite (`drift`); la UI del lote siempre lee de ahí.
2. Outbox `cola_sync` con estados `pendiente → enviado → confirmado | rechazado`.
3. `POST /api/sync` recibe un lote ordenado causalmente; el servidor procesa registro por registro y devuelve `aplicado`, `duplicado` o `rechazado` con motivo. Un rechazo no frena el resto.
4. La idempotencia vive en la base (`UNIQUE (uuid_cliente)`); un `duplicado` se trata como éxito.
5. Las referencias entre registros usan `uuid_cliente`, nunca ids del servidor, mientras están offline.
6. El catálogo de servicios asignados se baja con cursor (`GET /api/sync/catalogo`).
7. Las evidencias viajan en una cola separada; el servicio puede cerrarse con evidencia aún subiendo, pero su validación exige la evidencia ya subida.
8. El orden es por `secuencia` local, nunca por reloj de dispositivo.
9. Cada tipo de registro tiene un solo rol escritor, así que no hay lógica de merge.

La prueba de replay (el mismo lote aplicado varias veces, en orden y en desorden parcial, deja la base idéntica) corre en CI.

## Contrato de API

El contrato completo está en `docs/api/openapi.yaml` de `agrocom-api`, generado code-first; nunca se edita desde este repo. Los grupos funcionales que la app consume:

| Grupo | Quién lo usa | Conectividad |
|---|---|---|
| Autenticación (`POST /api/auth/token`, `GET /api/auth/sesion`) y registro de cliente y proveedor | Los tres flavors | Con red |
| Solicitud, seguimiento y calificación de servicios | `cliente` | Con red |
| Ofertas: lista, aceptar, rechazar | `piloto` | Con red, sin outbox |
| Perfil, documentos y drones del proveedor | `piloto` | Con red |
| Catálogo de servicios asignados (`GET /api/sync/catalogo`) | `piloto`, `auxiliar` | Pull con cursor |
| Registros del lote (`POST /api/sync`) y evidencias (`POST /api/evidencias`) | `piloto`, `auxiliar` | Offline, outbox |
| Versión mínima del APK (`GET /api/version`) | Todos | Polling, sin red tolerado |

## Qué no hace la app

- No procesa cobros: la primera versión no tiene pagos en la app; el modelo de comisión vive en `agrocom-api`.
- No gestiona contratos ni campañas: todo es solicitud por solicitud.
- No administra mantenimiento, inventario, planilla ni contabilidad.
- No decide la asignación ni la moderación; las ejecuta el servidor y el panel admin.
- No sincroniza nada del flavor `cliente` por outbox.

## Decisiones por defecto, revisables

| Decisión | Motivo |
|---|---|
| El panel web admin vive dentro de `agrocom-api` | Un solo despliegue y un solo modelo de datos |
| Aceptar o rechazar requiere red | La oferta es una competencia por tiempo; el lote sigue offline |
| La calificación la escribe el cliente en un registro propio; el proveedor solo la ve; el admin modera | Un solo rol escritor por registro |
| Sin cobro en la app en la primera versión | Reduce superficie y riesgo; la comisión se define en el negocio |
| El proveedor independiente se registra solo y el admin lo aprueba | Control de calidad sin frenar el alta |
| El piloto registra a su auxiliar y el admin lo aprueba | El piloto conoce a su equipo |
| Sin contratos ni campañas | Cada servicio es una solicitud independiente |
| El mapa del cliente usa `flutter_map` con teselas abiertas, sin clave de proveedor | Evita gestionar una clave de mapas en la primera versión |
