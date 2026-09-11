# Automatización del desarrollo

**Estado: implementada (TE-18).** Este documento describe el mecanismo de ciclo automatizado de `agrocom-field` — espejo del que ya funciona en `agrocom-api` (`docs/gestion/automatizacion_desarrollo.md` de ese repo, léelo primero: acá solo se documentan las diferencias y lo específico de este repo), corriendo como proceso aparte, sobre este working tree, sin tocar `agrocom-api`.

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

**Fuente del backlog**: `docs/gestion/plan_sprints.md` **de este repo** — ya no es un documento compartido. Nació como "Sprint 15" dentro del `plan_sprints.md` de `agrocom-api` (10/9/2026), pero se movió acá para no tener que abrir rama/PR en `agrocom-api` cada vez que se ajusta la planificación de la app (los IDs HU-69/TE-15 a TE-18 se conservaron tal cual para no romper referencias ya hechas en commits/PRs). `agrocom-api` sigue siendo la fuente de la especificación funcional/técnica y de las decisiones de negocio — no del backlog de tareas de este repo. La planificación de este ciclo lee su propio `plan_sprints.md` entero, sin cruzar al de `agrocom-api`. La cola de ejecución (`docs/gestion/cola_tareas.md`, con criterio ejecutable por fila) es propia de este repo — mismo formato que la de `agrocom-api`, pero no se mezclan: cada una consume su propio `plan_sprints.md` y escribe en su propio `prompts/`/`runs/`.

**Críticas de este repo**: motor de sync (`nucleo/sync`) y esquema `drift` (`nucleo/db`) — mismo tratamiento que `agrocom-api` con lo del motor de sync backend: se integran igual que cualquier tarea, quedan anotadas en `runs/revision-pendiente.txt` para revisión humana posterior sobre `develop`, **nunca en borrador** (la lección ya está documentada del lado `agrocom-api`: retener un PR crítico bloqueó doce HU seguidas hasta que el ciclo se quedó sin trabajo).

**Modelo por fase**: igual criterio — `sonnet` para lo que decide (implementar, verificar, planificar), `haiku` para lo repetitivo (leer CI rojo, reproducir con `bin/verify`, corregir).

### 5. La persistencia: `bin/ciclo-servicio`

Mismo mecanismo (LaunchAgent de macOS), **proceso separado** del de `agrocom-api` (`com.agrocom.ciclo-field`, no comparte PID ni `runs/` con el otro) — cada uno sobre su propio working tree, para que un `git checkout` de uno no pise al otro. No arranca un segundo ciclo sobre el mismo árbol (`runs/ciclo.pid`); respeta `runs/DETENER`.

## Lo que falta para un turno desatendido en este repo

1. **Prueba de replay del motor de sync (invariante 10 de `CLAUDE.md`)**: hoy no existe — es el gate más importante que falta, y sin él un verde de `bin/verify` no significa lo mismo que en `agrocom-api`. Se escribe en la misma tarea que implemente la lógica real de `SyncEngine` (TE-05 lado app), no antes.
2. **Golden tests / regresión visual de Flutter**: no hay ninguno todavía. Mientras no exista, ningún cambio de UI puede cerrarse sin que una persona mire la pantalla (misma limitación que Playwright del lado panel).
3. **Paralelismo con dos flavors a la vez**: hoy el ciclo corre una tarea por vez sobre un solo working tree — un cambio que solo afecta a un flavor igual espera su turno. Recién vale la pena si el backlog crece mucho.

## Nota de proceso

Este documento describía, antes del 11/9/2026, un mecanismo todavía no construido — la especificación que TE-18 implementó, no una descripción de algo ya funcionando. Con TE-18 integrada, las cinco piezas de arriba (`bin/verify`, `auto-merge.yml`, los guardarraíles, `bin/ciclo`, `bin/ciclo-servicio`) existen en el árbol; lo que sigue pendiente es lo que ya listaba "Lo que falta para un turno desatendido en este repo" — la prueba de replay del motor de sync sigue siendo el gate más importante, y se escribe junto con TE-05, no antes.
