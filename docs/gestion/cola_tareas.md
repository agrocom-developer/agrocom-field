# Cola de tareas automatizables

**Creada el 11/9/2026, junto con TE-18 (el ciclo automatizado en sí).** Todavía
no tiene filas: la primera sesión de planificación (`bin/ciclo --planificar` o
la fase 5 de la primera vuelta del ciclo) las escribe leyendo
`docs/gestion/plan_sprints.md` desde el principio.

Este es el backlog que `bin/ciclo` consume solo — el punto 4 de
[automatizacion_desarrollo.md](automatizacion_desarrollo.md). No reemplaza a
`plan_sprints.md`: ahí están las HU y TE con su alcance de negocio; acá está lo
que además tiene **criterio de aceptación ejecutable**, que es lo único que
puede avanzar sin nadie mirando la pantalla.

La cola en ejecución es `runs/cola.txt` (ids, uno por línea, en orden). Esta
tabla es su versión legible, con el porqué de cada fila.

La numeración de tareas arranca en `01` — este repo no tiene una serie previa
que evitar. `runs/` no se versiona; es la bitácora local de lo que ya corrió,
así que un id no vuelve a usarse aunque su prompt se borre del árbol más
adelante (mismo criterio que ya usa `agrocom-api`: el historial de git
conserva el texto).

## Tareas

| Id | HU/TE | Motivo | Estado |
|---|---|---|---|
| 01 | TE-05 (lado app) | Lógica real de `SyncEngine` (push contra `POST /api/sync`) + prueba de replay obligatoria (invariante 10 de `CLAUDE.md`). Primera pendiente en el orden de `plan_sprints.md` que sí tiene criterio ejecutable — antecede a HU-04/HU-05, que necesitan un motor de sync real para tener algo que sincronizar. Crítica (motor de sync). | prompt escrito |
| 02 | TE-06 | Pull de catálogo con cursor (`GET /api/sync/catalogo`), lado app — tablas `drift` de órdenes/lotes/personas + repositorio de catálogo. Siguiente pendiente tras TE-05 en el orden de `plan_sprints.md`; HU-04 (ver órdenes offline) necesita este catálogo ya bajado. Crítica (esquema `drift`). | prompt escrito |
| 03 | HU-03 (consumo) | Pantalla de login real contra `POST /api/auth/token` + persistencia del token ya existente (`TokenStoreSeguro`). Siguiente pendiente en el orden de `plan_sprints.md`; independiente de 01/02, no crítica. No incluye el selector de rol multi-rol (HU-69, bloqueada — ver abajo). | prompt escrito |

## Fuera del ciclo automático

| Id/HU/TE | Motivo | Condición incumplida |
|---|---|---|
| TE-02 | Spike RC Agras: instalar APK propio, confirmar Android/minSdk del hardware. Necesita el RC del dron en mano — no hay comando que lo verifique. | No tiene criterio de aceptación ejecutable por un comando. |
| HU-65 | Reclamo/queja durante el trabajo: alcance sin definir (¿queja sobre el servicio del cliente, sobre condiciones de trabajo del operario, o ambas?) — el propio `plan_sprints.md` la marca bloqueada hasta que el dueño lo resuelva. | Depende de una decisión de negocio sin tomar. |
| HU-69 | Selector de rol activo en caliente (flavor `auxiliar`): "cambiar de rol sin volver a loguearse" depende de que `agrocom-api` defina un mecanismo para reasignar el rol de un token Sanctum ya vivo (nota abierta de su ADR 0004, punto 6) — ADR 0005 de este repo ya lo deja explícito. El caso simple (elegir rol al loguear, vía `409` + reintento) SÍ es automatizable, pero la tarea 03 lo deja fuera a propósito para no mezclar dos HU en un mismo PR — se retoma como tarea propia una vez que 03 esté integrada. | Depende de una decisión que no está tomada (para el caso "en caliente"); el caso simple queda pendiente de encolar como tarea aparte. |

## Deuda técnica detectada

Ninguna fila registrada todavía. Es material para que el usuario decida qué
hacer con él, no trabajo que el ciclo se autoasigna: ver
`prompts/plantillas/planificar.md`, sección "El trabajo sale del plan, nunca
de tu criterio".
