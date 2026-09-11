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
| 04 | HU-04 | Ver órdenes vigentes offline (lista + detalle), leyendo `OrdenCatalogo`/`LoteCatalogo` que TE-06 (tarea 02) ya deja pobladas — sin red, sin tabla nueva. Siguiente pendiente del "Heredado del plan original" tras HU-03; no crítica. | **hecho** — PR #16 |
| 05 | HU-05 | Esqueleto vertical: abrir trabajo, abrir sesión, cerrar sesión (flavor piloto), sobre las órdenes vigentes de la tarea 04. El contrato de `POST /api/sync` para estos cuatro tipos de registro ya está confirmado e integrado del lado `agrocom-api`. Recorte explícito: "cerrar trabajo" queda fuera — exige evidencia subida (TE-07, cola de evidencias) que no existe en este repo todavía. Crítica (tablas `drift` nuevas para el espejo de escritura de trabajo/sesión). | **hecho** — PR #17 |
| 06 | HU-69 (caso simple) | Selector de rol al loguear en el flavor `auxiliar` (vía `409` + reintento con `role_id`), contra la decisión ya tomada en `docs/decisiones/0005-selector-rol-flavor-auxiliar.md`. Quedaba anotado en esta misma tabla como "se retoma una vez que 03 esté integrada" — 03 ya está mergeada (PR #14). No crítica; no necesita ADR nuevo, el 0005 ya cubre este alcance exacto. | **hecho** — PR #18 |
| 07 | TE-16 | `nucleo/preferencias`: `shared_preferences` para tema/idioma/último flavor, separado del outbox/`drift`. `runs/03-plan.md` ya la había señalado como "siguiente candidata razonable" tras 04/05/06. Sin dependencias nuevas — no toca ningún ADR. No crítica. | prompt escrito — `prompts/07-preferencias-locales.md` |
| 08 | HU-62 (recortada) | Avisos locales del dispositivo (sin FCM). Recorte: solo "orden nueva sincronizada" — "sesión abierta" no tiene datos en el flavor `auxiliar` (la sesión la escribe/lee el piloto, sin pull hacia el auxiliar) y "batería caliente" depende de `recarga`/HU-13, bloqueada por TE-07 (cola de evidencias), que no existe todavía. No crítica. | prompt escrito — `prompts/08-avisos-locales.md` |
| 09 | HU-68 | Modo emergencia con linterna, acceso en un toque desde cualquier pantalla (incluida login), sin depender de señal. Recorte: solo el punto de entrada + linterna — las demás "acciones rápidas" no están especificadas en ningún documento del plan. No crítica. | prompt escrito — `prompts/09-modo-emergencia.md` |

## Fuera del ciclo automático

| Id/HU/TE | Motivo | Condición incumplida |
|---|---|---|
| TE-02 | Spike RC Agras: instalar APK propio, confirmar Android/minSdk del hardware. Necesita el RC del dron en mano — no hay comando que lo verifique. | No tiene criterio de aceptación ejecutable por un comando. |
| HU-65 | Reclamo/queja durante el trabajo: alcance sin definir (¿queja sobre el servicio del cliente, sobre condiciones de trabajo del operario, o ambas?) — el propio `plan_sprints.md` la marca bloqueada hasta que el dueño lo resuelva. | Depende de una decisión de negocio sin tomar. |
| HU-69 (caso "en caliente") | "Cambiar de rol sin volver a loguearse" depende de que `agrocom-api` defina un mecanismo para reasignar el rol de un token Sanctum ya vivo (nota abierta de su ADR 0004, punto 6) — ADR 0005 de este repo ya lo deja explícito como bloqueante real, no inventable acá. El caso simple (elegir rol al loguear) ya se encoló y se cerró como tarea 06. | Depende de una decisión que no está tomada del lado `agrocom-api`. |
| TE-15 | Sistema de diseño Flutter: su criterio de aceptación pide un ADR nuevo en `docs/decisiones/` (catálogo de widgets + convención de transiciones) — la zona `decisiones` solo se descongela para **ampliar** lo que un ADR ya dejó abierto, nunca para fijar una decisión de arquitectura enteramente nueva sin que el dueño la revise primero. Además, "cero widget suelto por pantalla" no es verificable por un comando hoy (no existe ningún lint propio para eso). | No tiene criterio de aceptación ejecutable por un comando (el criterio de uso futuro no es mecánicamente verificable) y requiere fijar una decisión de arquitectura nueva sin revisión previa del dueño. |
| TE-17 | i18n español/portugués: su criterio de aceptación pide explícitamente "un ADR propio de este repo" nuevo (excepción a "dominio en español" de `CLAUDE.md`) — mismo motivo que TE-15, no es una ampliación de un ADR existente. | Requiere fijar una decisión de arquitectura nueva sin revisión previa del dueño. |
| HU-59 | Selector de tema/idioma: el propio `plan_sprints.md` agrupa "TE-17/HU-59 juntas (tema e idioma)" — sin TE-17 (bloqueada, ver arriba) construida, elegir "portugués" no tendría ningún efecto visible (no hay ARBs ni `flutter_localizations` todavía). Entregar la HU entera exige que TE-17 exista primero. | Depende de una decisión que no está tomada (transitiva vía TE-17). |
| HU-60 | Pronóstico de clima: la app pide el pronóstico directo a la Weather API de Google Maps Platform (RF-70/`analisis_capturas_rc.md` §6, decisión ya tomada del lado `agrocom-api` sobre el proveedor) — pero eso exige una API key propia de este proyecto, que no existe en ningún `config/env.*.json` de este repo, y no hay convención establecida acá para manejar credenciales de terceros (solo existe la de la URL del backend, un valor propio, no un secreto de un proveedor externo). Proveer esa clave y decidir cómo se inyecta al build es una decisión del dueño. | Depende de una decisión que no está tomada. |
| HU-61 | Mapa del lote: mismo motivo que HU-60 — requiere una clave de Google Maps Platform para el SDK nativo (`google_maps_flutter`), que no existe en este repo ni tiene convención de manejo definida. | Depende de una decisión que no está tomada. |
| HU-63 | Vista de alertas: es de solo lectura sobre lo que HU-19 (`agrocom-api`) generaría del lado servidor, pero `GET /api/sync/catalogo` (`docs/api/openapi.yaml`) hoy solo trae órdenes/lotes/personas — no hay endpoint ni tipo de dato de alertas para bajar. Construirlo es trabajo de `agrocom-api`, que este ciclo no toca. | Depende de un endpoint que no existe todavía en el otro repo (fuera del alcance de este ciclo). |
| HU-64 | Registrar pausas: el enum `tipo` de `RegistroSync` en `POST /api/sync` (`docs/api/openapi.yaml`) no incluye `pausa` — solo `trabajo`/`recepcion_caldo`/`sesion`/`condiciones`/`incidencia`/`recarga`/`cierre_trabajo`/`cierre_sesion`/`estadia_entrada`/`estadia_salida`. Sin ese tipo de registro del lado servidor, la app no tiene contra qué sincronizar. | Depende de un endpoint/contrato que no existe todavía en el otro repo. |
| HU-66 | Vista de devengos: de solo lectura sobre datos que HU-16/HU-28 (`agrocom-api`) expondrían, pero no hay endpoint de pull para eso hoy (mismo chequeo que HU-63/67 sobre `openapi.yaml`). | Depende de un endpoint que no existe todavía en el otro repo. |
| HU-67 | Vista de repuestos/suministros: de solo lectura sobre el catálogo de HU-27/HU-36 (`agrocom-api`, drones/stock), que tampoco está expuesto en `GET /api/sync/catalogo` hoy. | Depende de un endpoint que no existe todavía en el otro repo. |

## Deuda técnica detectada

Ninguna fila registrada todavía. Es material para que el usuario decida qué
hacer con él, no trabajo que el ciclo se autoasigna: ver
`prompts/plantillas/planificar.md`, sección "El trabajo sale del plan, nunca
de tu criterio".
