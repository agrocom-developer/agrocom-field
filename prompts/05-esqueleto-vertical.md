<!-- ciclo: critica=si turno-noche=1 rama=feature/esqueleto-vertical etapas=5 descongela=tests -->

# Tarea 05 — HU-05: esqueleto vertical (abrir trabajo, abrir sesión, cerrar sesión)

## Qué hacer

El flujo central de la app del piloto: elegir una orden vigente (HU-04, ya
integrada), abrir un trabajo sobre ella, abrir una sesión de vuelo, y
cerrarla con las hectáreas cubiertas. Escribir = insertar local + encolar
en outbox en una sola transacción (invariante 3 de `CLAUDE.md`) — ningún
paso espera respuesta del servidor para confirmar en pantalla.

Es tarea `critica=si`: agrega tablas nuevas a `nucleo/db` (lista de "qué no
delegar sin revisión línea por línea" de `CLAUDE.md`). Se implementa e
integra igual, queda anotada en `runs/revision-pendiente.txt` para
revisión posterior — no la conviertas en borrador ni la retengas por eso.

Cargá `verificacion` siempre, `protocolo-sync` antes de tocar el esquema
`drift`/outbox, y `flujo-git-pr` antes de rama/commits/PR.

**El criterio de aceptación de `plan_sprints.md` para esta HU dice "flujo
mínimo completo demostrable con avión-modo en el RC" — eso es cómo un
humano la valida en la práctica, no el gate de este PR** (mismo criterio ya
aplicado en la tarea 01/TE-05, que tradujo su "prueba de replay" a tests
reales en vez de esperar una demo física). El gate de esta tarea es
`./bin/verify` en verde con la cobertura de tests descrita más abajo,
armada contra el contrato real de `POST /api/sync` — no una demo con
hardware.

### Contrato de backend — ya confirmado, no hace falta redescubrirlo

El servidor **ya implementa e integró** los cuatro tipos de registro de
este flujo (`agrocom-api`, módulo `Operaciones`, tarea "HU-05, tarea 13"
del lado servidor). Fuente de verdad exacta (más confiable que la
descripción en prosa de `openapi.yaml`): los DTOs de validación en
`/Applications/MAMP/htdocs/agrocom-api/app/Dominios/Operaciones/Contratos/`:

- **`AperturaTrabajo.php`** — registro `tipo: "trabajo"`. Campos:
  `uuid_cliente` (string, no vacío), `orden_id` (int, de
  `OrdenCatalogo.id`), `lote_id` (int, de `OrdenCatalogo.loteId`),
  `nro_aplicacion` (int, de `OrdenCatalogo.nroAplicacion`),
  `hectareas_declaradas` (decimal-string, opcional, default `"0"`),
  `inicio` (string ISO 8601, obligatorio), `fin` (opcional, no se manda
  acá).
- **`AperturaSesion.php`** — registro `tipo: "sesion"`. Campos:
  `uuid_cliente`, `trabajo_uuid_cliente` (el `uuid_cliente` del trabajo que
  la contiene — **nunca** un id de servidor, puede no existir todavía si
  viajan en el mismo lote), `secuencia` (int, orden de apertura de la
  sesión **dentro de ese trabajo**, empieza en 1), `piloto_id` (int,
  obligatorio — ver más abajo de dónde sale), `auxiliar_id`/`dron_id`
  (opcionales, `null` acá — HU-07 no está construida, no inventes un valor),
  `hectareas_declaradas` (opcional, default `"0"` — a la apertura el
  piloto todavía no sabe cuánto va a cubrir), `hectarea_inicial_acumulada`
  (opcional, `null` acá — HU-07), `inicio` (ISO 8601, obligatorio).
- **`CierreSesion.php`** — registro `tipo: "cierre_sesion"`. Campos:
  `uuid_cliente` (**nuevo**, identifica el EVENTO de cierre — distinto del
  `uuid_cliente` de apertura de la sesión), `sesion_uuid_cliente` (el
  `uuid_cliente` de apertura de la sesión que se cierra), `fin` (ISO 8601,
  obligatorio), `motivo_cierre` (string, **obligatorio**, catálogo cerrado:
  `completado`/`relevo_piloto`/`cambio_dron`/`falla_equipo`/`clima`/
  `fin_jornada`/`otro` — un valor fuera de esta lista rechaza el registro
  completo), `hectareas_declaradas` (**obligatorio acá**, a diferencia de
  la apertura — sin este dato la sesión no puede quedar "cerrada": es la
  condición central de la transición, según la espec §5),
  `litros_consumidos` (opcional).

`RegistroSync`/`ResultadoSync` en `docs/api/openapi.yaml` documentan el
sobre del lote (mismo mecanismo que ya usa `SyncEngine`, sin cambios acá:
`OutboxRepository`/`SyncEngine` de `nucleo/sync` son genéricos por
`tipoEntidad`/`payload` JSON — **no hace falta tocar `nucleo/sync`**, solo
encolar filas nuevas en `ColaSync` con el `tipoEntidad` correcto).

### `piloto_id` — de dónde sale

`AperturaSesion.piloto_id` es la persona que abre la sesión. Hoy
`LoginService.login()` (`lib/nucleo/auth/login_service.dart`) descarta el
resto del cuerpo del `201` — solo guarda `cuerpo['token']`. El cuerpo trae
también `usuario: UsuarioCampo`, que incluye `persona_id` (nullable, ver
`docs/api/openapi.yaml`, schema `UsuarioCampo`) — esa es la persona
operativa del usuario logueado. Esta tarea necesita persistirlo: agregá un
store hermano de `TokenStoreSeguro` (mismo mecanismo,
`flutter_secure_storage`) o extendé el existente, y usalo para completar
`piloto_id`. **Confirmá antes de asumir** que `UsuarioCampo.persona_id` y
`PersonaCatalogo.id` (`lib/nucleo/db/tablas/persona_catalogo.dart`, ya
poblada por el pull de catálogo) comparten el mismo espacio de IDs — son
del mismo módulo `Personal` del lado servidor, pero confirmalo leyendo el
código del backend antes de construir sobre ese supuesto. Si el usuario
logueado no tiene `persona_id` (nullable), "abrir sesión" no puede
completarse — bloqueá la acción con un mensaje, no dejes que falle
silenciosamente.

## Piezas a construir

Feature nueva: `lib/features/sesion_vuelo/` (nombre tomado de ADR 0005 de
`agrocom-api`, que ya lo usa como ejemplo de este flujo exacto —
coordiná con `arquitectura-flutter` si conviene separar `trabajo`/`sesion`
en sub-features). Solo visible en flavor `piloto` (espec §3: abrir trabajo
es acción exclusiva del piloto) — la screen se muestra condicionada a
`Flavor.piloto`, nunca separada en una carpeta `piloto/` (esa carpeta no
existe todavía en el repo; cuando se cree, ver invariante 7 de `CLAUDE.md`).

1. **Esquema `drift`** (delegá a `modelo-datos-flutter`, revisá línea por
   línea antes de commitear): tablas nuevas para el espejo local de
   escritura de trabajo y sesión (nombre a su criterio, p. ej.
   `TrabajoLocal`/`SesionLocal`) — a diferencia de `OrdenCatalogo`/
   `LoteCatalogo` (solo lectura, PK = id de servidor), estas las escribe
   el dispositivo: PK/identidad por `uuidCliente`, sin id de servidor
   todavía. Necesitan reflejar localmente el estado "abierta"/"cerrada"
   para que la UI muestre sesiones en curso sin esperar confirmación del
   servidor (edición optimista de la propia fila que el dispositivo
   escribió — no es el caso que prohíbe la invariante 6, que es sobre no
   reescribir lo que el **servidor** ya confirmó). `schemaVersion` 2 → 3,
   con `migrationStrategy` que no toque las tablas de v1/v2, y su test de
   migración real (mismo patrón que
   `test/nucleo/db/migracion_catalogo_test.dart`).
2. **Persistencia de `persona_id`** del usuario logueado (ver arriba).
3. **`domain/`**: entidades `Trabajo`/`Sesion` puras, y las reglas mínimas
   que sí le tocan a este repo verificar antes de encolar (no duplican la
   autoridad del servidor, solo evitan encolar algo que el propio
   dispositivo ya sabe que está mal formado): no permitir "abrir sesión"
   sin un trabajo local ya abierto, `secuencia` de sesión incremental por
   trabajo llevada localmente.
4. **`data/`**: `TrabajoRepository`/`SesionRepository` (nombres de ADR
   0005) — cada método de apertura/cierre hace insert local + insert en
   `ColaSync` (con el `payload` JSON armado exactamente como los DTOs de
   arriba) dentro de una única `_db.transaction`. Generación de
   `uuid_cliente` con el paquete `uuid` (mismo que `DispositivoStore`) en
   el dispositivo, nunca en el servidor (invariante 2).
5. **`presentation/`**: Bloc/Cubit para abrir trabajo (desde el detalle de
   una orden de HU-04 — agregá el botón/acción ahí), para la sesión activa
   (abrir, ver estado, cerrar con formulario de hectáreas + motivo +
   litros opcional).
6. Wiring en `service_locator.dart` y en la navegación desde
   `OrdenesPantalla`/`OrdenDetallePantalla` (HU-04) — sin recrear esas
   pantallas, solo agregar el punto de entrada.

## Cómo repartir las etapas

- Etapa 1 (crítica — revisar línea por línea): esquema `drift` nuevo +
  migración + su test, y la persistencia de `persona_id`.
- Etapa 2: `domain/` + `data/` (los dos repositorios, insert+outbox
  transaccional) con tests contra una base `drift` en memoria — casos:
  abrir trabajo crea la fila local + la fila `ColaSync` con
  `tipoEntidad: 'trabajo'` y el payload exacto del DTO; abrir sesión sin
  trabajo previo falla en el dominio, no llega a escribir nada; secuencia
  incremental correcta con más de una sesión por trabajo; cerrar sesión
  encola `cierre_sesion` con `hectareas_declaradas` obligatorio.
- Etapa 3: presentación (cubits/blocs + estados) con tests.
- Etapa 4: pantallas (formulario de apertura, sesión activa, formulario de
  cierre) + wiring de navegación desde HU-04, con tests de widget.
- Etapa 5: integración — tests que encadenan las tres transiciones contra
  un `ApiClient`/repositorio mockeado verificando el payload exacto de
  cada tipo de registro contra los DTOs citados arriba, wiring final, y
  documentar en `runs/05.md` qué queda para HU-07 (dron, dupla auxiliar,
  hectárea inicial acumulada) y para el cierre de trabajo (ver recorte
  abajo).

## Qué NO hacer — recorte explícito

- **No implementar "cerrar trabajo" (`tipo: cierre_trabajo`).** Ese
  registro exige `evidencia_imagen_campo_uuid_cliente` **obligatorio**
  ("sin captura no cierra", `docs/api/openapi.yaml`) — una evidencia ya
  subida por `POST /api/evidencias`. La cola de evidencias comprimidas
  (TE-07) no existe todavía en este repo (`docs/vision.md`, "Evidencias" —
  nada en `lib/` hoy toca subida de imágenes). Sin esa pieza no hay forma
  correcta de completar ese registro. El "esqueleto vertical" de esta
  tarea llega hasta sesión cerrada — cerrar el trabajo queda pendiente
  para cuando TE-07 exista, no la inventes con un valor dummy.
- No implementar HU-07 (dron, hectárea inicial acumulada, doble conteo,
  auxiliar en la sesión) — todos los campos correspondientes van `null`/
  omitidos, tal como los DTOs los aceptan.
- No mostrarle al usuario un registro `rechazado` del outbox de forma
  especial (alertas de sync) — no existe ninguna pantalla hoy que muestre
  `motivoRechazo`; construirla es alcance de otra HU (HU-63, fuera de esta
  tarea).
- No tocar `SyncEngine`/`OutboxRepository` (`nucleo/sync`) — son
  genéricos por diseño (TE-05, ya integrada) y este flujo encola sobre
  ellos sin modificarlos.
- No construir la pantalla de "mis trabajos" como listado separado si no
  hace falta para el flujo — alcanza con navegar desde el detalle de una
  orden (HU-04) al trabajo recién abierto.

## Criterio de aceptación

`./bin/verify` devuelve 0, con la cobertura de tests descrita en la etapa
2 y 5 (payloads exactos de `trabajo`/`sesion`/`cierre_sesion` verificados
campo por campo contra los DTOs citados).

## Cierre obligatorio de cada etapa

`runs/05.estado`: `PARCIAL`/`OK`/`BLOQUEADA` (con el motivo concreto si
bloquea — p. ej. si el supuesto de `persona_id`/`PersonaCatalogo.id`
compartiendo espacio de IDs resulta falso, documentalo ahí en vez de
inventar un mapeo).

`runs/05.md`: qué se hizo y qué falta, concreto — en particular, dejá
explícito el recorte de "cerrar trabajo" para que no se reintente sin
TE-07.

Al cerrar con `OK`, `runs/05.pr.md`: título en la primera línea, cuerpo
debajo.

## Commits

Agrupados por pieza coherente, español, imperativo, el porqué antes que
el qué: esquema `drift` + migración, persistencia de `persona_id`,
dominio + repositorios, presentación, pantallas + wiring. Sin trailer
`Co-Authored-By`.
