# Visión del producto — `agrocom-field`

Este documento orienta a quien empieza a trabajar en este repo. Describe el producto, las dos superficies móviles y lo que cada una hace. Las reglas de trabajo están en `CLAUDE.md`; las decisiones de arquitectura, en `docs/decisiones/`; el contrato de API, en `docs/api/openapi.yaml` de `agrocom-api` (ruta local: `/Applications/MAMP/htdocs/agrocom-api`), con los estados, reglas y recursos de la negociación en `docs/especificacion/negociacion-contrato.md` de ese repo. Si este documento y el contrato no coinciden, manda el contrato.

## Qué es Agrocom

Agrocom es un **marketplace de servicio de fumigación con drones** donde el precio se negocia entre quien pide el servicio y quien lo hace. Un cliente publica una solicitud sobre su propiedad con un precio por hectárea; los pilotos la ven en un mapa y aceptan ese precio o proponen el suyo; el cliente compara las ofertas y elige. Los drones son los «vehículos».

- **Clientes**: dueños de campo o sus encargados. Publican, negocian, siguen y califican servicios.
- **Proveedores**: pilotos de Agrocom, pilotos independientes y dueños de drones, Compiten en igualdad.
- **Agrocom**: capta clientes, es el nexo entre ambos lados y el registro del estado y del resultado; además es proveedor propio. Lo operativo en el lote (cómo se trabaja, cuándo se vuela) lo acuerdan en persona el cliente y el piloto. La app no cobra: el pago se hace fuera de ella.

### Negociación

El cliente propone un precio por hectárea. El piloto, antes de ofertar, revisa el estado de la propiedad y de los lotes (lotes dibujados, cultivo, accesos, observaciones y fotos), y acepta el precio o contraoferta con el dron que usará. El cliente recibe varias ofertas, las compara por precio, calificación y dron (el orden recomendado pone primero a los proveedores propios de Agrocom y luego a los mejor calificados, y el cliente lo cambia), y acepta una, contraoferta o rechaza. La distancia no se calcula: se acuerda en la negociación. En cada negociación hay una sola oferta vigente y hay un máximo de ofertas; aceptar la oferta vigente de la contraparte adjudica la solicitud y cierra las demás. Todo lo decide y valida el servidor; la app muestra y envía.

## Las dos superficies móviles

Un solo código Flutter, dos flavors (ADR 0009, ADR 0021):

| Flavor | Quién lo usa | Qué hace | Conectividad |
|---|---|---|---|
| `cliente` | Dueño del campo o encargado | Registrarse, marcar propiedad y lotes en el mapa, publicar una solicitud con su precio por hectárea, comparar y elegir ofertas, ver fotos de avance, chatear, ver la última ubicación del piloto, calificar | Online-first, sin outbox |
| `piloto` | Piloto (control remoto del dron o celular) | Registrarse con sus datos y los de su dron con fotos, ver el mapa de solicitudes abiertas, ofertar, ajustar sus avisos y su disponibilidad; ejecutar: marcar inicio, subir fotos, marcar avance, cerrar con las hectáreas ejecutadas | Negociación con red; ejecución offline en el lote |

Las superficies web (panel admin y motor del marketplace) viven en `agrocom-api`: aprobación de proveedores y drones con sus fotos, moderación de calificaciones, reclamos y métricas.

### Qué es online y qué es offline

- **El lote no tiene señal.** Lo que sucede entre adjudicar y finalizar es offline-first: la UI lee de `drift`, toda escritura se inserta localmente y se encola en el outbox en una sola transacción, y cada registro nace con su `uuid_cliente`.
- **Negociar requiere red.** Ofertar, contraofertar, aceptar, rechazar y retirar van directo a la API, sin outbox; la adjudicación la confirma el servidor. Es una excepción documentada y revisable (ADR 0016).
- **El cliente siempre opera con red.** La app abre con la última lista conocida y avisa claramente cuando no hay conexión.

## El recorrido de un servicio

1. **Publicación.** El cliente marca su propiedad y sus lotes en el mapa, elige el departamento y la provincia, escribe el municipio y la comunidad, declara hectáreas (decimal exacto), cultivo, producto, fecha deseada (puede ser dentro de semanas o meses), accesos, observaciones, un requisito de dron si lo necesita y su precio por hectárea. La solicitud viaja con una clave de idempotencia generada en el dispositivo y queda `abierta`.
2. **Mapa de solicitudes.** El piloto ve las solicitudes abiertas que le corresponden en un mapa, con filtro por departamento, hectáreas, precio, fecha y cultivo; decide si quiere ir y la distancia se acuerda en la negociación. No hay zonas ni restricción geográfica. Si activó las notificaciones y no está «Ocupado» ni «En trabajo», recibe un aviso por oleadas: primero los propios de Agrocom y los mejor calificados que cumplen todos los filtros (del sistema, del cliente y los suyos), y cada pocos minutos se abre a más proveedores sin avisar dos veces al mismo.
3. **Oferta.** El piloto abre el detalle, acepta el precio o contraoferta. La solicitud pasa a `con_ofertas`.
4. **Elección.** El cliente compara las ofertas y negocia ronda por ronda hasta que una parte acepta la oferta de la otra. Mientras negocia, la solicitud está «En negociación» y no aparece a los demás pilotos; si ya conversa con quien le interesa, puede elegir «Sin buscar más pilotos». Un dron que no cumple lo pedido puede ofertar y se le marca al cliente. La solicitud queda `adjudicada` con su precio acordado; se abren los datos de contacto y el chat.
5. **Ejecución.** Las partes acuerdan en persona cómo trabajan. El piloto marca el inicio (`en_ejecucion`), sube fotos de su avance y marca el progreso (porcentaje u hectáreas). Todo se sincroniza cuando vuelve la señal; las fotos, comprimidas a menos de 300 KB, viajan en una cola aparte. El cliente ve las fotos, el avance, los mensajes y la última ubicación del piloto como un punto en el mapa.
6. **Cierre.** El piloto cierra con las hectáreas ejecutadas. El servidor calcula el precio final (hectáreas ejecutadas por precio acordado) y ambos lo ven como el monto a pagar. La solicitud queda `finalizada`.
7. **Calificación.** El cliente califica al proveedor en un registro propio y la solicitud pasa a `calificada`; el proveedor lo ve y un admin lo modera. El proveedor califica al cliente en otro registro, privado. Cualquiera puede abrir un reclamo dentro de su plazo.

Una solicitud sin adjudicar vence al fin de su fecha deseada (`expirada`) y el cliente puede renovarla. Cancelar antes de adjudicar no tiene consecuencia; después de adjudicar se registra quién cancela y se muestra en su tasa de cancelación, sin penalidad en dinero.

## Proveedores y drones

- El **proveedor independiente se registra solo**, con los datos de la persona (nombres, apellidos, documento, teléfono, foto), su licencia y los datos del dron (marca, modelo, año, serie, capacidad) con sus fotos; un admin lo aprueba antes de que vea el mapa y ofrezca.
- El **auxiliar no usa la app** (ADR 0021): el piloto no lo registra ni lo ve en su equipo.
- El **dron es el vehículo**: tiene matrícula, modelo, capacidad, fotos y estado, y pertenece a Agrocom o a un tercero. El cliente ve el modelo y las fotos aprobadas en cada oferta.
- Los **documentos del proveedor** (licencia de piloto, matrícula del dron, seguros) se suben desde su perfil y los revisa el admin.

## Arquitectura

- BLoC feature-first en tres capas (`presentation/`, `domain/`, `data/`) y un `nucleo/` compartido (ADR 0009).
- `cliente/` y `piloto/` no se importan entre sí; solo importan de `nucleo/`.
- Cliente HTTP manual sobre `dio` (ADR 0001); decimal exacto para hectáreas y dinero (ADR 0002); configuración de entorno por `--dart-define-from-file` (ADR 0004); versionado SemVer automatizado (ADR 0007).
- Tema claro derivado del logo para `cliente` (ADR 0003) y modo campo de alto contraste para `piloto` (ADR 0008).
- Sin selector de rol: el flavor fija el rol (ADR 0021, que reemplaza el ADR 0005).
- Negociación de ofertas (ADR 0016), seguimiento del servicio (ADR 0017) y mercado sin zonas con avisos por oleadas (ADR 0023).

### Sincronización del lote

1. Base local SQLite (`drift`); la UI del lote siempre lee de ahí.
2. Outbox `cola_sync` con estados `pendiente → enviado → confirmado | rechazado`.
3. `POST /api/sync` recibe un lote ordenado causalmente con los registros `inicio`, `avance`, `cierre`, `mensaje` e `incidencia`; el servidor procesa registro por registro y devuelve `aplicado`, `duplicado` o `rechazado` con motivo. Un rechazo no frena el resto.
4. La idempotencia vive en la base (`UNIQUE (uuid_cliente)`); un `duplicado` se trata como éxito.
5. Las referencias entre registros usan `uuid_cliente`, nunca ids del servidor, mientras están offline.
6. El catálogo de servicios adjudicados y en ejecución se baja con cursor (`GET /api/sync/catalogo`).
7. Las fotos viajan en una cola separada; el servicio puede cerrarse con fotos aún subiendo, pero pasa a `finalizada` cuando el servidor las tiene.
8. El orden es por `secuencia` local, nunca por reloj de dispositivo.
9. Cada tipo de registro tiene un solo rol escritor, así que no hay lógica de merge.

La prueba de replay (el mismo lote aplicado varias veces, en orden y en desorden parcial, deja la base idéntica) corre en CI.

## Contrato de API

El contrato completo está en `docs/api/openapi.yaml` de `agrocom-api`, generado code-first; nunca se edita desde este repo. Los grupos funcionales que la app consume:

| Grupo | Quién lo usa | Conectividad |
|---|---|---|
| Autenticación (`POST /api/auth/token`, `GET /api/auth/sesion`) y registro de cliente y proveedor (con datos de la persona y del dron) | Los dos flavors | Con red |
| Terrenos, solicitud (publicar, precio, renovar, cancelar), comparador de ofertas, avance, ubicación del piloto, calificación | `cliente` | Con red |
| Mapa de solicitudes abiertas, detalle, ofertar, contraofertar, aceptar, rechazar, retirar | `piloto` | Con red, sin outbox |
| Mensajes de la solicitud | `cliente`, `piloto` | Cliente con red; piloto por outbox |
| Perfil, documentos, drones y fotos del dron | `piloto` | Con red |
| Preferencias de notificación y token de push | `cliente`, `piloto` | Con red |
| Ubicación del piloto (`PUT /api/ubicacion`) | `piloto` | Con red, sin outbox; se omite sin señal |
| Catálogo de servicios adjudicados (`GET /api/sync/catalogo`) | `piloto` | Pull con cursor |
| Registros del lote (`POST /api/sync`) y fotos (`POST /api/evidencias`) | `piloto` | Offline, outbox |
| Versión mínima del APK (`GET /api/version`) | Todos | Polling, sin red tolerado |

## Qué no hace la app

- No procesa cobros ni calcula comisión: el precio final se muestra y el pago ocurre fuera de ella.
- No gestiona contratos ni campañas: todo es solicitud por solicitud.
- No administra mantenimiento, inventario, planilla ni contabilidad.
- No decide la negociación ni la moderación; las valida el servidor y el panel admin.
- No dirige la operación en el lote: sesión de vuelo, mezcla y condiciones las acuerdan las partes en persona.
- No muestra ruta ni tiempo estimado de llegada del piloto: solo su última ubicación.
- No sincroniza nada del flavor `cliente` por outbox.

## Decisiones por defecto, revisables

| Decisión | Motivo |
|---|---|
| El panel web admin vive dentro de `agrocom-api` | Un solo despliegue y un solo modelo de datos |
| Negociar requiere red | La adjudicación es un acuerdo entre dos partes que el servidor resuelve; el lote sigue offline |
| El cliente elige entre las ofertas; no hay adjudicación automática | El cliente decide con precio, calificación y dron; el orden recomendado (propios primero, luego calificación) solo sugiere |
| Los avisos de nuevas solicitudes salen por oleadas desde el servidor y la app no los calcula | Prioridad por tiempo para los propios y los mejor calificados sin avisar dos veces; ADR 0023 |
| Sin zonas, sin distancia y sin precio de referencia | El mercado es abierto; los precios los ponen el cliente y el proveedor |
| El piloto ve lotes y fotos antes de ofertar, y el contacto solo tras adjudicar | Decide su precio con información sin exponer al cliente |
| La calificación la escribe el cliente en un registro propio; el proveedor solo la ve; el admin modera | Un solo rol escritor por registro |
| Sin cobro ni comisión calculada en la app | Reduce superficie y riesgo; el modelo de ingresos es del negocio |
| La ubicación del piloto es solo la última posición durante la ejecución | Privacidad: sin historial ni ruta |
| El proveedor independiente se registra solo y el admin lo aprueba | Control de calidad sin frenar el alta |
| El auxiliar no es usuario de la app (ADR 0021) | No hay trabajo propio que justifique una app ni un selector de rol |
| El mapa usa `flutter_map` con teselas abiertas, sin clave de proveedor | Evita gestionar una clave de mapas en la primera versión |
