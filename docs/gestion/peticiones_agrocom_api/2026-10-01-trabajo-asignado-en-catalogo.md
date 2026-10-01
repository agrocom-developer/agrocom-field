# Petición a `agrocom-api` — trabajo asignado (`trabajos[]`) en `GET /api/sync/catalogo`

**Fecha:** 1/10/2026 · **Pide:** `agrocom-field` (lado app), tras integrar HU-70 (tarea 19, PR #59) · **Decide y aprueba:** el dueño · **Ejecuta:** una sesión sobre `agrocom-api` (rama `feature/*`, PR contra `develop`, GitFlow del ADR 0006) · **Estado:** respondida; pendientes de la tarea 26 resueltos en la tarea 27. Las preguntas 1, 2 y 4 por `agrocom-api` #309-#312 (develop `a47e5280cc4159038b1f5597aaec37a29ce7ce73`); la 3 por #313 (develop `5df5e8f53f98720aec4f523f6a52a3bda33ca0be`, opción B), aplicada en la tarea 26 de `agrocom-field`.

## Quién y por qué se requirió

Desde el PR #59, el pull de catálogo guarda `trabajos[]` en `trabajo_catalogo` (esquema v11). «Inicio» es la pantalla inicial del piloto y «Crear aplicación» abre sesiones sobre el trabajo asignado con el `uuid_cliente` que generó el panel. La app quedó alineada contra `agrocom-api` en `develop` `44570a17`, pero el contrato no responde cuatro preguntas. La app no puede resolverlas sola, y tres de ellas afectan la integridad de lo que el piloto carga en campo, sin conectividad.

## Preguntas

### 1. ¿El servidor acepta un `cierre_trabajo` del piloto sobre un trabajo creado por el panel?

La app nunca encola un registro `trabajo` para el trabajo asignado: ya existe en el servidor y sería una segunda apertura. Sí encola `sesion` y, al terminar, `cierre_trabajo` con ese mismo `uuid_cliente`. Hay que confirmar que `POST /api/sync` acepta ese cierre cuando el autor de la apertura fue el panel y no el dispositivo, y qué rechazo devuelve si no. Si lo rechaza, el piloto no tiene forma de cerrar un trabajo asignado.

### 2. ¿`trabajos[]` llega filtrado por el equipo del piloto autenticado?

El contrato no lo dice. Si no viene filtrado, «Inicio» puede mostrarle al piloto el trabajo de **otro equipo**, porque se elige el más reciente por `updated_at`, y el piloto podría abrir sesiones sobre él. No es un problema de presentación: serían horas de vuelo cargadas sobre el trabajo equivocado. **Se pide:** que el servidor filtre por el equipo del token, o que el catálogo diga a qué equipo pertenece el dispositivo para que la app filtre. Hoy la app guarda `equipo_trabajo_id` pero no tiene contra qué compararlo.

### 3. ¿Cómo se entera la app de un trabajo reasignado, cancelado o cerrado por el panel?

Es el mismo problema que la petición del 29/9/2026 sobre el estado de la orden (TE-22): el pull es incremental y no retira registros. Un trabajo que el panel reasigna a otro equipo o cancela sigue apareciendo como «el trabajo asignado» del piloto hasta que este lo cierre localmente. **Se pide** resolverlo con el mismo mecanismo que se elija para la orden (opción A o B de esa petición): un estado explícito o una lista de retirados.

### 4. ¿Qué campos de `trabajos[]` pueden venir nulos?

La app parsea `equipo_trabajo_id`, `hectareas_declaradas`, `lote_id` y `orden_id` como obligatorios. Si alguno llegara `null`, o `hectareas_declaradas` llegara como número en vez de texto decimal, toda la página del pull hace rollback y el cursor no avanza. El catálogo entero, órdenes incluidas, queda trabado en silencio en ese dispositivo. **Se pide:** que `openapi.yaml`, regenerado del código (ADR 0014), declare la nulabilidad real de cada campo de `TrabajoCatalogo`. La app ajusta su parseo a eso; no adivina.

## Respuestas

Leídas en el código de `agrocom-api` develop `a47e5280cc4159038b1f5597aaec37a29ce7ce73`, que incluye los PR #309, #310, #311 y #312.

### 1. Cierre de un trabajo creado por el panel — **resuelta**

El servidor lo acepta. `EscrituraSincronizacionEloquent::cerrarTrabajo()` busca el trabajo por `uuid_cliente` sin mirar quién lo abrió. #309-#312 no cambiaron esa función. Los rechazos posibles son:

- `trabajo_no_existe`;
- `trabajo_ya_cerrado`, si ya tiene otro `uuid_cliente` de cierre;
- `operario_no_participo`, si el trabajo tiene sesiones y ninguna es de ese piloto;
- `falta_imagen_campo`;
- `imagen_campo_reutilizada`.

La app no necesita cambios.

### 2. Filtro por equipo — **resuelta** (#312)

`trabajos[]` llega filtrado por el operario del token: solo los trabajos de los equipos donde su persona es integrante vigente hoy (todos, si está en varios). Una cuenta sin persona operativa recibe `trabajos` vacío.

Límite conocido, declarado en `openapi.yaml`: si la persona entra a un equipo nuevo, los trabajos de ese equipo que no cambiaron desde el último pull no llegan en el incremental. Los trae recién un pull completo (`desde` vacío).

### 3. Trabajo reasignado, cancelado o cerrado por el panel — **resuelta** (#313, opción B)

**La respuesta del servidor.** Suma `trabajos_retirados: [{id, uuid_cliente, motivo, updated_at}]`, siempre presente y sin `null`.

- `motivo`, si aplican varios gana el primero:
  - `dado_de_baja`: baja lógica.
  - `reasignado`: el trabajo pasó a un equipo donde la persona no está vigente hoy, o quedó sin equipo.
  - `cerrado`.
  - `orden_cerrada`: su orden pasó a `consumida`, `cancelada` o `vencida`.
- `trabajos[]` ahora solo trae trabajos abiertos de órdenes no cerradas: un trabajo nunca viaja a la vez como asignado y como retirado.
- Una orden `pausada` **no** retira sus trabajos.
- Con cursor vacío no llegan retirados.

**Límites con que el sync valida `condiciones` de una sesión cuyo trabajo quedó retirado:**

- `dado_de_baja`: la sesión ya no encuentra su trabajo y se usan los defaults (17/30/90, sin humedad mínima). Una sesión nueva se rechaza con `trabajo_no_existe_aun`.
- `reasignado`, `cerrado` y `orden_cerrada`: los límites de su Orden de Trabajo. Se usan los defaults si están en blanco o si la Orden de Trabajo se dio de baja. Las sesiones nuevas se aceptan, porque `abrirSesion` no mira el estado ni el equipo del trabajo.

**La app (tarea 26, esquema v14):**

- Marca `trabajo_catalogo.motivo_retiro` y nunca borra. Si el trabajo vuelve en `trabajos[]`, se desmarca.
- «Inicio» y los límites del detalle de orden los excluyen.
- `SesionRepository.limitesCondiciones` espeja #313: `dado_de_baja` usa los defaults; los otros tres, y el motivo local `fuera_de_alcance`, usan los límites de la fila.
- Una sesión ya abierta se cierra igual que antes.

#311 resolvió otra parte del problema: un trabajo vuelve a bajar cuando cambia su Orden de Trabajo, también si se da de baja. Lo hace porque el cursor de `trabajos` usa la modificación más reciente entre el trabajo y su tanda, y ese es el `updated_at` que viaja.

### 4. Nulabilidad — **resuelta** (#309)

`openapi.yaml` se regeneró del código:

- `id`, `uuid_cliente`, `orden_id`, `lote_id`, `hectareas_declaradas` (DECIMAL como string), `equipo_trabajo_id` y `updated_at` nunca vienen nulos.
- Los siete límites viajan **efectivos** (`LimitesEfectivos`): `viento_max_kmh`, `temperatura_max_c` y `humedad_max_pct` siempre traen valor, el de la Orden de Trabajo o el default 17.00 / 30.00 / 90.00.
- `humedad_min_pct`, `altura_vuelo_m`, `velocidad_vuelo_kmh` y `ancho_pasada_m` llegan `null` si la Orden de Trabajo no los fija.

El parseo de la app ya coincidía y sigue tolerando `null` en los siete.

### Relacionado: validación de condiciones (#310)

Desde #310, el registro `condiciones` se valida contra esos mismos límites efectivos, ya no contra constantes. Los topes son inclusivos y la humedad mínima solo se exige si está fijada. La app lo replica desde la tarea 24 (PR #64).

## Fuera de esta petición

Los campos de clima y vuelo que pasaron de la orden a `trabajos[]` (7 de 8 según la alineación del 1/10/2026) no son una pregunta: son trabajo del lado app. Se hicieron así:

- **Tarea 23** (PR #63, esquema v12): columnas en `trabajo_catalogo` y pantallas.
- **Tarea 25** (esquema v13): quita las 8 columnas de `orden_catalogo` y resetea el cursor para que los trabajos ya bajados reciban los límites efectivos.

## Pendiente

- [x] Respuesta de `agrocom-api` a las preguntas 1, 2 y 4: #309-#312, develop `a47e5280`.
- [x] El dueño decide la 3 junto con la opción A/B de la petición del 29/9/2026: **B**, #313 (`5df5e8f5`), aplicada en la tarea 26.
- [x] Filas de **otros equipos** bajadas antes de #312: las limpia el barrido completo de la tarea 26 (v14 resetea el cursor). Lo que no llega en un pull completo desde cursor vacío, terminado sin error, queda `fuera_de_alcance`; nunca un trabajo con `trabajo_local` abierto. Sin señal no se toca nada.
- [x] **Volver a una sesión abierta** — tarea 27. «Inicio» muestra arriba la tarjeta «Sesión en curso» o «Trabajo en curso», leída de `sesion_local`/`trabajo_local` en `drift`. Se ve aunque el trabajo esté retirado o lo haya abierto la app, y lleva a `SesionVueloPantalla` de ese trabajo. `SesionBloc` arranca con `SesionCargaSolicitada`: con la sesión abierta, en `SesionActiva` con su mismo `uuid_cliente`; sin ella, en `SesionInicial`, desde donde ahora se cierra el trabajo. Con algo en curso en otro trabajo, «Crear aplicación» queda deshabilitado con el motivo, y el formulario de apertura no deja abrir una segunda sesión.
- [x] **Trabajo de una orden pausada** — decisión del dueño, aplicada en la tarea 27: no se vuela sobre una orden pausada. «Inicio» muestra el badge «Orden pausada» y deshabilita «Crear aplicación» con el motivo. Cuando el pull vuelve a traer la orden vigente, se habilita solo. El formulario de apertura tampoco deja abrir una sesión nueva. Una sesión ya abierta se sigue y se cierra igual.
- [x] **Sesión nueva sobre un trabajo `dado_de_baja`** — tarea 27. Confirmado en `agrocom-api` `5df5e8f5`: `abrirSesion()` busca el trabajo con `Trabajo::query()`, que excluye los dados de baja (`SoftDeletes`), y rechaza con `trabajo_no_existe_aun`. No mira ni el estado ni el equipo del trabajo, así que acepta `reasignado`, `cerrado` y `orden_cerrada`. `registrarCondiciones()` usa los defaults si la sesión ya no resuelve su trabajo. La app bloquea la sesión nueva en el formulario, con el motivo, solo con `dado_de_baja`. Con los otros motivos, y con el local `fuera_de_alcance`, muestra el motivo como aviso en la pantalla de sesión.

### Pendientes que deja la tarea 27

- [ ] **Más de un trabajo abierto a la vez.** El modelo lo permite: «Abrir trabajo» desde «Órdenes» no mira si hay otro en curso. La tarea 27 no lo resuelve. «Inicio» muestra el más reciente por `cola_sync.secuencia`, nunca por reloj: primero una sesión abierta y, si no hay, un trabajo abierto. Un trabajo asignado sin sesiones no encoló nada y queda detrás, por orden de inserción local. Lo que sí impide la app es una segunda sesión abierta. Decide el dueño si «Abrir trabajo» también se bloquea.
- [ ] **Cerrar un trabajo `dado_de_baja`.** El dueño decidió que se pueda, pero `cerrarTrabajo()` de `agrocom-api` busca el trabajo con la misma consulta sin los dados de baja y rechaza con `trabajo_no_existe`. El cierre se encola y llega rechazado al sincronizar. Decide el dueño si la app lo avisa, lo bloquea o si el servidor lo acepta.
- [ ] **El aviso de retiro en la pantalla de sesión no es reactivo.** Se lee al entrar y al abrir el formulario de apertura. Si el pull retira el trabajo con la pantalla abierta, el aviso aparece recién en la próxima lectura. El bloqueo no depende de eso, porque el formulario vuelve a leer antes de dejar confirmar.
