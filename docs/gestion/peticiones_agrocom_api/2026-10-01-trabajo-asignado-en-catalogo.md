# Petición a `agrocom-api` — trabajo asignado (`trabajos[]`) en `GET /api/sync/catalogo`

**Fecha:** 1/10/2026 · **Pide:** `agrocom-field` (lado app), tras integrar HU-70 (tarea 19, PR #59) · **Decide y aprueba:** el dueño · **Ejecuta:** una sesión sobre `agrocom-api` (rama `feature/*`, PR contra `develop`, GitFlow del ADR 0006) · **Estado:** pendiente de respuesta.

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

## Fuera de esta petición

Los campos de clima y vuelo que pasaron de la orden a `trabajos[]` (7 de 8 según la alineación del 1/10/2026) no son una pregunta: son trabajo del lado app, una tarea nueva de la cola (mover las columnas de `orden_catalogo` a `trabajo_catalogo` con su migración v12). Hasta entonces, «Límites climáticos» del detalle de orden muestra «sin datos».

## Pendiente

- [ ] Respuesta de `agrocom-api` a las preguntas 1, 2 y 4: lectura del código y, si hace falta, cambio en `openapi.yaml`.
- [ ] El dueño decide la 3 junto con la opción A/B de la petición del 29/9/2026.
- [ ] Con las respuestas, se encola en `agrocom-field` la tarea que ajuste el filtro por equipo, el retiro de trabajos y el parseo, y se actualiza este documento con el PR y el SHA.
