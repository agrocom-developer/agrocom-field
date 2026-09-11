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
| 01 | TE-05 (lado app) | Lógica real de `SyncEngine` (push contra `POST /api/sync`) + prueba de replay obligatoria (invariante 10 de `CLAUDE.md`). Primera pendiente en el orden de `plan_sprints.md` que sí tiene criterio ejecutable — antecede a HU-04/HU-05, que necesitan un motor de sync real para tener algo que sincronizar. Crítica (motor de sync). | **hecho** — PR #10 (+ fix #11) |
| 02 | TE-06 | Pull de catálogo con cursor (`GET /api/sync/catalogo`), lado app — tablas `drift` de órdenes/lotes/personas + repositorio de catálogo. Siguiente pendiente tras TE-05 en el orden de `plan_sprints.md`; HU-04 (ver órdenes offline) necesita este catálogo ya bajado. Crítica (esquema `drift`). | **hecho** — PR #13 |
| 03 | HU-03 (consumo) | Pantalla de login real contra `POST /api/auth/token` + persistencia del token ya existente (`TokenStoreSeguro`). Siguiente pendiente en el orden de `plan_sprints.md`; independiente de 01/02, no crítica. No incluye el selector de rol multi-rol (HU-69, bloqueada — ver abajo). | **hecho** — PR #14 |
| 04 | HU-04 | Ver órdenes vigentes offline (lista + detalle), leyendo `OrdenCatalogo`/`LoteCatalogo` que TE-06 (tarea 02) ya deja pobladas — sin red, sin tabla nueva. Siguiente pendiente del "Heredado del plan original" tras HU-03; no crítica. | prompt escrito |
| 05 | HU-05 | Esqueleto vertical: abrir trabajo, abrir sesión, cerrar sesión (flavor piloto), sobre las órdenes vigentes de la tarea 04. El contrato de `POST /api/sync` para estos cuatro tipos de registro ya está confirmado e integrado del lado `agrocom-api`. Recorte explícito: "cerrar trabajo" queda fuera — exige evidencia subida (TE-07, cola de evidencias) que no existe en este repo todavía. Crítica (tablas `drift` nuevas para el espejo de escritura de trabajo/sesión). | prompt escrito |
| 06 | HU-69 (caso simple) | Selector de rol al loguear en el flavor `auxiliar` (vía `409` + reintento con `role_id`), contra la decisión ya tomada en `docs/decisiones/0005-selector-rol-flavor-auxiliar.md`. Quedaba anotado en esta misma tabla como "se retoma una vez que 03 esté integrada" — 03 ya está mergeada (PR #14). No crítica; no necesita ADR nuevo, el 0005 ya cubre este alcance exacto. | prompt escrito |

## Fuera del ciclo automático

| Id/HU/TE | Motivo | Condición incumplida |
|---|---|---|
| TE-02 | Spike RC Agras: instalar APK propio, confirmar Android/minSdk del hardware. Necesita el RC del dron en mano — no hay comando que lo verifique. | No tiene criterio de aceptación ejecutable por un comando. |
| HU-65 | Reclamo/queja durante el trabajo: alcance sin definir (¿queja sobre el servicio del cliente, sobre condiciones de trabajo del operario, o ambas?) — el propio `plan_sprints.md` la marca bloqueada hasta que el dueño lo resuelva. | Depende de una decisión de negocio sin tomar. |
| HU-69 (caso "en caliente") | "Cambiar de rol sin volver a loguearse" depende de que `agrocom-api` defina un mecanismo para reasignar el rol de un token Sanctum ya vivo (nota abierta de su ADR 0004, punto 6) — ADR 0005 de este repo ya lo deja explícito como bloqueante real, no inventable acá. El caso simple (elegir rol al loguear) ya se encoló como tarea 06. | Depende de una decisión que no está tomada del lado `agrocom-api`. |
| TE-15 | Sistema de diseño Flutter: su criterio de aceptación pide un ADR nuevo en `docs/decisiones/` (catálogo de widgets + convención de transiciones) — la zona `decisiones` solo se descongela para **ampliar** lo que un ADR ya dejó abierto, nunca para fijar una decisión de arquitectura enteramente nueva sin que el dueño la revise primero. Además, "cero widget suelto por pantalla" no es verificable por un comando hoy (no existe ningún lint propio para eso). | No tiene criterio de aceptación ejecutable por un comando (el criterio de uso futuro no es mecánicamente verificable) y requiere fijar una decisión de arquitectura nueva sin revisión previa del dueño. |
| TE-17 | i18n español/portugués: su criterio de aceptación pide explícitamente "un ADR propio de este repo" nuevo (excepción a "dominio en español" de `CLAUDE.md`) — mismo motivo que TE-15, no es una ampliación de un ADR existente. | Requiere fijar una decisión de arquitectura nueva sin revisión previa del dueño. |

## Deuda técnica detectada

Ninguna fila registrada todavía. Es material para que el usuario decida qué
hacer con él, no trabajo que el ciclo se autoasigna: ver
`prompts/plantillas/planificar.md`, sección "El trabajo sale del plan, nunca
de tu criterio".
