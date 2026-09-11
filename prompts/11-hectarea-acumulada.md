<!-- ciclo: critica=no turno-noche=1 rama=feature/hectarea-acumulada etapas=2 descongela=tests -->

# Tarea 11 — HU-07 (resto): hectárea inicial acumulada + dron/auxiliar en la sesión

## Qué hacer

HU-05 dejó afuera a propósito lo que un relevo de piloto necesita: que el
piloto entrante registre desde dónde arranca el acumulado del DJI (para no
cobrar hectáreas que ya voló el piloto anterior en ese mismo lote), y quién
más participa de la sesión (auxiliar, dron). Esta tarea completa esos tres
campos, que **ya existen en el esquema** (`SesionLocal.auxiliarId`,
`SesionLocal.dronId`, `SesionLocal.hectareaInicialAcumulada`, todos
`nullable`, comentados "HU-07" desde que se crearon) — no hace falta
migración nueva, por eso esta tarea no es crítica.

Asume que la tarea 10 (HU-06, condiciones al abrir sesión) ya está
integrada: el formulario de apertura de sesión existe (lo creó esa tarea).
Esta tarea lo AMPLÍA, no crea uno nuevo.

Cargá `verificacion` siempre y `flujo-git-pr` antes de rama/commits/PR. No
hace falta `protocolo-sync` — no se toca `nucleo/sync` ni el esquema.

### El cálculo de "doble conteo" — especificación, no inventiva

`/Applications/MAMP/htdocs/agrocom-api/docs/especificacion/especificacion_funcional_tecnica.md`,
líneas ~224-226:

> Control de doble conteo: si la misión de DJI se retoma, la pantalla del
> RC del segundo piloto muestra el acumulado del lote, no lo suyo — por eso
> cada sesión registra `hectarea_inicial_acumulada` y las hectáreas de la
> sesión son la diferencia contra ese valor.

Traducido al flujo de la app:

- **Al abrir sesión**: el piloto, si está entrando en relevo, ingresa el
  acumulado que muestra el RC en ESE momento (`hectarea_inicial_acumulada`
  — opcional, `null` si es la primera sesión del lote).
- **Al cerrar sesión**: si esa sesión tiene `hectarea_inicial_acumulada`,
  el piloto ingresa el acumulado FINAL que muestra el RC, y la app calcula
  `hectareasDeclaradas` (de cierre) = acumulado final − acumulado inicial
  — no le pidas al piloto que reste a mano bajo presión de campo, es
  exactamente el cálculo que esta HU existe para automatizar. Si el
  resultado da negativo (acumulado final menor al inicial — dato mal
  ingresado), rechazalo en el formulario antes de encolar nada, mismo
  criterio que ya usa la validación de hectáreas no negativas del
  formulario de cierre actual. Si la sesión NO tiene
  `hectarea_inicial_acumulada` (fue `null` al abrir), el formulario de
  cierre sigue funcionando exactamente como hoy — ingreso directo de
  hectáreas, sin resta.

Función pura nueva en `reglas_sesion.dart` para ese cálculo + su
validación, con tests — no la mezcles con el widget.

### `dron_id` — sin catálogo, no lo inventes

El propio contrato (`RegistroSync.dron_id` en `openapi.yaml`) ya lo avisa:
"catálogo mínimo de Operaciones, sin pull de catálogo propio todavía". No
hay ninguna tabla `DronCatalogo` en este repo y agregar un pull nuevo es
alcance de otra tarea (fuera de esta HU tal como está escrita en
`plan_sprints.md`). Resolvela con un campo de entrada numérica simple y
opcional (el id de servidor del dron, si el piloto lo conoce) — no es una
decisión de arquitectura nueva, es el único dato disponible hoy. Dejalo
anotado en `runs/11.md` como limitación conocida, no como algo a resolver
en esta misma tarea.

### `auxiliar_id` — sí hay catálogo, usalo

`PersonaCatalogo` (`lib/nucleo/db/tablas/persona_catalogo.dart`) ya está
poblada por el pull de catálogo (TE-06, integrada) y tiene una columna
`rol` (texto libre, valores como `"piloto"`/`"auxiliar"`). El formulario de
apertura de sesión puede ofrecer un dropdown opcional poblado con
`SELECT * FROM persona_catalogo WHERE rol = 'auxiliar' AND activo = true`
— agregá el método de consulta que haga falta al repositorio o cubit que
corresponda (revisá si ya existe algo parecido para órdenes/lotes en HU-04
antes de escribir uno nuevo).

## Piezas a tocar

Todo dentro de `lib/features/sesion_vuelo/`. No crear feature nueva, no
tocar `nucleo/db` (no hace falta).

1. **`domain/`**: función de cálculo de diferencia (ver arriba) + su
   validación, en `reglas_sesion.dart`.
2. **`data/`**: `SesionRepository.abrirSesion` deja de mandar
   `auxiliar_id`/`dron_id`/`hectarea_inicial_acumulada` fijos en `null` —
   acepta los tres como parámetros opcionales y los persiste en
   `SesionLocal` + los manda en el payload de `sesion`.
   `SesionRepository.cerrarSesion` acepta el acumulado final opcional y
   aplica el cálculo del punto anterior antes de escribir
   `hectareasDeclaradasCierre` — mismo criterio que hoy: todo dentro de la
   transacción existente, sin abrir una nueva.
3. **`presentation/`**: `SesionAbrirSolicitada` y `SesionCerrarSolicitada`
   ganan los campos opcionales nuevos. El formulario de apertura (creado
   en la tarea 10) suma los tres campos; el formulario de cierre suma el
   campo de acumulado final, visible solo si la sesión activa tiene
   `hectareaInicialAcumulada` no nulo.

## Cómo repartir las etapas

- Etapa 1: dominio (cálculo + validación, tests puros) + repositorio
  (`abrirSesion`/`cerrarSesion` extendidos, tests contra `drift` en
  memoria: apertura con los tres campos completos persiste y encola bien;
  cierre con acumulado final calcula la resta correcta; cierre con
  acumulado final menor al inicial rechaza antes de escribir; sesión sin
  `hectareaInicialAcumulada` cierra igual que hoy).
- Etapa 2: presentación (eventos, bloc, los dos formularios ampliados) con
  tests de bloc y de widget, wiring del dropdown de auxiliares contra
  `PersonaCatalogo`. Documentar en `runs/11.md` la limitación de `dron_id`
  sin catálogo.

## Qué NO hacer

- No agregues un pull de catálogo de drones — es alcance nuevo no pedido
  por esta HU tal como está en `plan_sprints.md`.
- No muevas el cálculo de diferencia a la UI (el widget solo arma el
  evento con los valores crudos ingresados) — vive en `domain/`, testeable
  sin `drift` ni Flutter.
- No toques `nucleo/db` ni subas `schemaVersion` — las columnas ya existen.
- No toques `SyncEngine`/`OutboxRepository`.

## Criterio de aceptación

`./bin/verify` devuelve 0, con la cobertura de tests descrita arriba.

## Cierre obligatorio de cada etapa

`runs/11.estado`: `PARCIAL`/`OK`/`BLOQUEADA`.

`runs/11.md`: qué se hizo y qué falta, concreto — incluida la limitación
de `dron_id` sin catálogo.

Al cerrar con `OK`, `runs/11.pr.md`: título en la primera línea, cuerpo
debajo.

## Commits

Agrupados por pieza coherente, español, imperativo, el porqué antes que el
qué: reglas de dominio, repositorio, presentación. Sin trailer
`Co-Authored-By`.
