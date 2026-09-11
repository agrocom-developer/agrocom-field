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
| — | — | (sin filas todavía) | — |

## Fuera del ciclo automático

Ninguna fila registrada todavía. Se completa a medida que la planificación se
tope con una HU/TE que no califica (no tiene criterio ejecutable, no es de
este repo, o depende de una decisión sin tomar) — con cuál de las tres
condiciones incumple, en una línea.

## Deuda técnica detectada

Ninguna fila registrada todavía. Es material para que el usuario decida qué
hacer con él, no trabajo que el ciclo se autoasigna: ver
`prompts/plantillas/planificar.md`, sección "El trabajo sale del plan, nunca
de tu criterio".
