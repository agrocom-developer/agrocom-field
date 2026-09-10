# Automatización del desarrollo — diseño propuesto

**Estado: propuesta, no implementada.** Este documento describe el mecanismo de ciclo automatizado que TE-18 (`docs/gestion/plan_sprints.md` de `agrocom-api`, Sprint 15) va a construir para `agrocom-field` — espejo del que ya funciona en `agrocom-api` (`docs/gestion/automatizacion_desarrollo.md` de ese repo, léelo primero: acá solo se documentan las diferencias y lo específico de este repo), pero corriendo como proceso aparte, sobre este working tree, sin tocar `agrocom-api`.

**Por qué otro proceso y no extender el existente**: la propia plantilla de planificación de `agrocom-api` (`prompts/plantillas/planificar.md`) excluye explícitamente a `agrocom-field` ("otro repo, este ciclo no lo toca") — es una decisión ya tomada, no un olvido. Dos repos con GitFlow independiente, CI independiente y ritmo de cambio independiente no comparten bien una sola cola ni un solo working tree.

## La regla que ordena el resto (igual que en `agrocom-api`)

**Una tarea puede avanzar sin supervisión solo si su criterio de aceptación es un comando que devuelve 0 o 1.** Si no se puede expresar así, la revisa una persona. Es la misma sección "qué no delegar sin revisión línea por línea" de `CLAUDE.md` de este repo (motor de sync, esquema `drift`) la que marca qué **no** califica.

## Piezas a construir (TE-18)

### 1. La compuerta: `bin/verify`

Más simple que el de `agrocom-api`: sin Docker, sin base de datos de servicio — todo corre directo sobre el SDK de Flutter instalado en la máquina.

```
./bin/verify
```

| Etapa | Comando |
|---|---|
| Formato | `dart format --output=none --set-exit-if-changed .` |
| Análisis estático | `flutter analyze` |
| Codegen limpio | `dart run build_runner build --delete-conflicting-outputs` (si `pubspec.yaml` usa `build_runner`, mismo criterio que ya tiene `ci.yml`) |
| Tests | `flutter test` |

Detenerse en la primera falla, exit code honesto — misma cascada que corre `flutter-tests` en `.github/workflows/ci.yml`, así que un verde local predice el verde de CI. A diferencia de `agrocom-api`, no hay etapa de build de assets ni de regresión visual todavía (ver "Lo que falta" más abajo).

### 2. El merge: `auto-merge.yml`

**Ya existe, sin cambios.** Confirmado en el bootstrap de este repo: mergea con squash en cuanto `flutter-tests` queda verde, mismo mecanismo que `agrocom-api` (espera de check-runs por SHA, sin depender del auto-merge nativo de GitHub). TE-18 no toca este archivo — solo lo reutiliza.

**La misma trampa del squash aplica acá**: una rama que sigue viva después de que su PR se mergeó ya no es ancestro de `develop`, y un PR nuevo desde esa rama nace en conflicto sin disparar ningún check — "sin checks" hay que tratarlo como señal de fallo, no como pendiente. `bin/ciclo` de este repo necesita la misma doble compuerta que ya tiene el de `agrocom-api` (rebase antes de abrir PR; corte a los 3 min si no hay checks).

### 3. Los guardarraíles: hooks `PreToolUse`

Adaptación directa de `.claude/hooks/guardarrail-bash.sh` y `guardarrail-archivos.sh` de `agrocom-api`, con las diferencias propias de este repo:

- **`guardarrail-bash.sh`**: misma lista negra base (push a `master`/`develop`, `--force`, `reset --hard`, `clean -fdx`, `branch -D`, `filter-branch`, `rm -rf` fuera del scratchpad) **más** lo específico de Flutter/Android: ningún comando que toque `*.jks`/`key.properties` con contenido real, ninguna migración de `drift` que haga `DROP TABLE`/`DELETE FROM` sin filtro sobre una tabla ya usada en producción (una vez que existan tablas de negocio — hoy solo hay `ColaSync`).
- **`guardarrail-archivos.sh`**: con `AGROCOM_TURNO_NOCHE=1` se congelan `test/` (no `tests/` — es la convención de Dart, ojo con el nombre real de la carpeta), `docs/decisiones/`, `.claude/`, `.github/`, salvo `descongela=` explícito por tarea. `CLAUDE.md` nunca se abre con ninguna zona.
- **Prueba propia**: `.claude/hooks/prueba-guardarrail.sh`, mismo criterio de `agrocom-api` — un guardarraíl sin su propio test es un guardarraíl que puede fallar en silencio (ya pasó una vez del lado backend: un `echo` en cualquier línea del comando desactivaba todas las reglas).

### 4. El bucle de cola: `bin/ciclo`

Mismas 5 fases, mismo criterio "una tarea = una HU o TE completa = un PR", misma regla de que la rama la crea el ciclo (no la sesión) desde el metadato `rama=` del prompt:

| Fase | Qué hace |
|---|---|
| implementar | Encadena sesiones sobre la misma rama hasta cerrar la HU/TE; corre `bin/verify` al final de cada una |
| verificar | Solo si `critica=si` — sesión independiente, no puede tocar código, solo escribe veredicto |
| PR | Abre con título/cuerpo que dejó la planificación |
| esperar CI | Sondea `auto-merge`; corta rápido si hay conflicto o si no aparecen checks a los 3 min |
| planificar | Lee `plan_sprints.md` de `agrocom-api` (Sprint 15 en adelante es lo que le toca a este repo) + `docs/gestion/cola_tareas.md` propio de este repo + git real; escribe el prompt de la siguiente tarea, sin commitear nada |

**Fuente del backlog**: `plan_sprints.md` sigue siendo compartido entre ambos repos (documento oficial único) — la planificación de este ciclo lee ahí las filas que le corresponden a `agrocom-field` (Sprint 15 en adelante, más TE-04/TE-05-lado-app/TE-06/HU-03-consumo/HU-04/HU-05 de sprints anteriores que sigan pendientes del lado app). La cola de ejecución (`docs/gestion/cola_tareas.md`, con criterio ejecutable por fila) es propia de este repo — mismo formato que la de `agrocom-api`, pero no se mezclan: cada una consume su propio `plan_sprints.md`-subset y escribe en su propio `prompts/`/`runs/`.

**Críticas de este repo**: motor de sync (`nucleo/sync`) y esquema `drift` (`nucleo/db`) — mismo tratamiento que `agrocom-api` con lo del motor de sync backend: se integran igual que cualquier tarea, quedan anotadas en `runs/revision-pendiente.txt` para revisión humana posterior sobre `develop`, **nunca en borrador** (la lección ya está documentada del lado `agrocom-api`: retener un PR crítico bloqueó doce HU seguidas hasta que el ciclo se quedó sin trabajo).

**Modelo por fase**: igual criterio — `sonnet` para lo que decide (implementar, verificar, planificar), `haiku` para lo repetitivo (leer CI rojo, reproducir con `bin/verify`, corregir).

### 5. La persistencia: `bin/ciclo-servicio`

Mismo mecanismo (LaunchAgent de macOS), **proceso separado** del de `agrocom-api` (`com.agrocom.ciclo-field`, no comparte PID ni `runs/` con el otro) — cada uno sobre su propio working tree, para que un `git checkout` de uno no pise al otro. No arranca un segundo ciclo sobre el mismo árbol (`runs/ciclo.pid`); respeta `runs/DETENER`.

## Lo que falta para un turno desatendido en este repo

1. **Prueba de replay del motor de sync (invariante 10 de `CLAUDE.md`)**: hoy no existe — es el gate más importante que falta, y sin él un verde de `bin/verify` no significa lo mismo que en `agrocom-api`. Se escribe en la misma tarea que implemente la lógica real de `SyncEngine` (TE-05 lado app), no antes.
2. **Golden tests / regresión visual de Flutter**: no hay ninguno todavía. Mientras no exista, ningún cambio de UI puede cerrarse sin que una persona mire la pantalla (misma limitación que Playwright del lado panel).
3. **Paralelismo con dos flavors a la vez**: hoy el ciclo corre una tarea por vez sobre un solo working tree — un cambio que solo afecta a un flavor igual espera su turno. Recién vale la pena si el backlog crece mucho.

## Nota de proceso

Este documento se escribe **antes** de que TE-18 exista como código — es la especificación que esa tarea implementa, no una descripción de algo ya funcionando. Actualizarlo para que refleje la realidad (quitar "diseño propuesto" del encabezado) es parte del criterio de aceptación de TE-18, no un paso aparte.
