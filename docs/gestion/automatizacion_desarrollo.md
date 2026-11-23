# Automatización del desarrollo

El ciclo automatizado de `agrocom-field` implementa la cola de tareas de [cola_tareas.md](cola_tareas.md) con agentes en segundo plano, sobre este working tree, sin tocar `agrocom-api`. Es un proceso aparte del de `agrocom-api` porque los dos repos tienen GitFlow, CI y ritmo de cambio independientes, y no comparten bien una cola ni un working tree.

## La regla que ordena el resto (igual que en `agrocom-api`)

**Una tarea puede avanzar sin supervisión solo si su criterio de aceptación es un comando que devuelve 0 o 1.** Si no se puede expresar así, la revisa una persona. La sección «Qué no delegar sin revisión línea por línea» de `CLAUDE.md` marca qué se integra pero queda anotado para revisión humana posterior.

## Piezas

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

Por defecto `bin/verify` verifica solo lo afectado por el diff contra `origin/develop`; `bin/verify --todo` corre las etapas de arriba sobre todo el repo (ver `docs/gestion/ci-por-impacto.md`). Detenerse en la primera falla, exit code honesto — misma cascada que corre `flutter-tests` en `.github/workflows/ci.yml`, así que un verde local predice el verde de CI. A diferencia de `agrocom-api`, no hay etapa de build de assets ni de regresión visual todavía (ver "Lo que falta" más abajo).

### 2. El merge: `auto-merge.yml`

`auto-merge.yml` mergea con squash en cuanto `flutter-tests` queda verde, mismo mecanismo que `agrocom-api` (espera de check-runs por SHA, sin depender del auto-merge nativo de GitHub).

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
| planificar | Lee `plan_sprints.md` y `docs/gestion/cola_tareas.md` de este repo + git real; escribe el prompt de la siguiente tarea, sin commitear nada |

**Fuente del backlog**: `docs/gestion/plan_sprints.md` de este repo, con su cola ejecutable en `docs/gestion/cola_tareas.md`. `agrocom-api` es la fuente del contrato (`docs/api/openapi.yaml`), no del backlog de esta app.

**Críticas de este repo**: motor de sync (`nucleo/sync`), esquema `drift` (`nucleo/db`) y la aceptación de ofertas con red. Se integran igual que cualquier tarea y quedan anotadas en `runs/revision-pendiente.txt` para revisión humana posterior sobre `develop`; no se retienen en borrador, porque una rama que no entra bloquea todo lo que viene detrás.

**Modelo por fase**: igual criterio — `sonnet` para lo que decide (implementar, verificar, planificar), `haiku` para lo repetitivo (leer CI rojo, reproducir con `bin/verify`, corregir).

### 5. La persistencia: `bin/ciclo-servicio`

Mismo mecanismo (LaunchAgent de macOS), **proceso separado** del de `agrocom-api` (`com.agrocom.ciclo-field`, no comparte PID ni `runs/` con el otro) — cada uno sobre su propio working tree, para que un `git checkout` de uno no pise al otro. No arranca un segundo ciclo sobre el mismo árbol (`runs/ciclo.pid`); respeta `runs/DETENER`.

## Límites del turno desatendido

1. **Prueba de replay del motor de sync**: corre en CI y es la compuerta de cualquier cambio en `nucleo/sync` o `nucleo/db`.
2. **Golden tests**: detectan regresiones visuales, no deciden estética. Cada tarea de UI adjunta capturas del emulador y la revisión visual final es del dueño.
3. **Un working tree, una tarea a la vez**: un cambio que afecta a un solo flavor igual espera su turno.
4. **Contrato ausente**: una tarea que depende de un endpoint no publicado queda `BLOQUEADA` con un PR en borrador, y la cola sigue.
