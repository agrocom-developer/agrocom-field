---
name: ciclo-segundo-plano
description: Cómo ejecutar desarrollo desatendido con bin/ciclo — escribir prompts con metadatos, la cola, runs/, estados, el LaunchAgent que lo mantiene vivo y los hooks de turno noche que congelan zonas. Usar para lanzar, vigilar, detener o preparar tareas del ciclo en segundo plano.
---

# Ciclo en segundo plano — `bin/ciclo`

Detalle del porqué en `docs/gestion/automatizacion_desarrollo.md`. Acá, la operación.

## Fases por tarea

implementar, verificar (solo si `critica=si`), abrir PR, esperar CI, planificar la siguiente. Cada fase corre en su propia sesión de Claude Code con contexto limpio. Una tarea es una HU o TE completa y termina en un PR contra `develop`. El estado vive en git y en `runs/`, no en ninguna conversación: el ciclo se puede matar y retomar.

## Comandos

```
bin/ciclo --fondo           # se desprende de la terminal
bin/ciclo                   # en primer plano
bin/ciclo --estado          # fase, cola, rama, parada, tareas trabadas, últimas líneas del log
bin/ciclo --detener         # parada ordenada: termina la fase en curso y no toma otra
bin/ciclo --reanudar        # levanta la bandera de parada
bin/ciclo --vueltas 2       # tope de tareas de esta corrida
bin/ciclo --planificar 08   # reescribe el prompt siguiente a la 08 si esa vuelta se cortó
bin/ciclo --reconciliar     # corrige runs/*.estado que git desmiente (--simular para ver)
```

## Escribir un prompt

Archivo `prompts/NN-nombre-corto.md`. La primera línea declara los metadatos:

```
<!-- ciclo: critica=no turno-noche=1 rama=feature/nombre-corto etapas=3 descongela=tests -->
```

| Clave | Significado |
|---|---|
| `rama` | Rama que crea el ciclo desde `develop`; la sesión no la elige |
| `critica` | `si` activa la sesión verificadora independiente (motor de sync y esquema `drift`) |
| `turno-noche` | `1` activa los congelamientos del hook |
| `etapas` | Tope de sesiones encadenadas sobre la misma rama |
| `descongela` | Zonas editables: `tests`, `decisiones`, `claude`, `github` (separadas por coma) |
| `modelo` | Modelo de la fase de implementación |

El cuerpo trae: objetivo, alcance, agentes a delegar (según `orquestador-flutter`), y **un criterio de aceptación que sea un comando con código de salida 0 o 1** (`./bin/verify` más los tests específicos). Sin criterio ejecutable, la tarea la revisa una persona.

## La cola y `runs/`

- `runs/cola.txt`: ids de tarea pendientes, uno por línea, en orden.
- `runs/NN.estado`: `OK`, `PARCIAL`, `CERRADA`, `OMITIDA`, `BLOQUEADA`, `RECHAZADA`, `AGOTADA`, `INCOMPLETA`. Los cuatro últimos necesitan una persona.
- `runs/NN.log`, `NN-verify.log`, `NN.pr.md`, `NN.veredicto`: evidencia de cada fase.
- `runs/ciclo.log`: bitácora; `runs/ciclo.estado`: fase actual; `runs/ciclo.pid`; `runs/DETENER`: bandera de parada.
- `runs/revision-pendiente.txt`: tareas críticas integradas que esperan revisión humana posterior.
`runs/` no se versiona.

Una tarea trabada no frena el bucle: queda marcada, con PR en borrador si tenía trabajo, y el ciclo sigue. Se detiene por parada pedida, cola vacía, o varias tareas seguidas sin integrarse.

## Que sobreviva a un reinicio: LaunchAgent

```
bin/ciclo-servicio --instalar     # instala y carga com.agrocom.ciclo-field
bin/ciclo-servicio --estado       # si está cargado y cómo salió
bin/ciclo-servicio --desinstalar
```

Copia el script a `~/.local/bin/agrocom-ciclo-field` para no depender de la rama en que esté el árbol. Respeta `runs/DETENER` y no arranca un segundo ciclo sobre el mismo árbol. Es un proceso separado del de `agrocom-api` (`com.agrocom.ciclo`).

## Hooks de turno noche

`.claude/hooks/guardarrail-bash.sh` bloquea siempre: push a `master` o `develop`, `--force`, `reset --hard`, `clean -fdx`, `branch -D` y lectura de credenciales. `guardarrail-archivos.sh`, con `AGROCOM_TURNO_NOCHE=1`, congela `test/`, `docs/decisiones/`, `.claude/` y `.github/` salvo que el prompt declare `descongela=` para esa zona; `CLAUDE.md` nunca se abre. Los hooks se prueban con `.claude/hooks/prueba-guardarrail.sh`. Si un comando legítimo cae en falso positivo, se reformula; no se esquiva el hook.

## Delegación dentro del ciclo

Las sesiones headless pueden usar los agentes de `.claude/agents/` con las mismas cadenas que describe `orquestador-flutter`. Una tarea de UI incluye siempre a `ui-movil-premium` y `qa-visual` en su criterio de aceptación; una con borrado de datos locales, a `migracion-esquema`.

## Antes de dejar la máquina sola

1. `./bin/verify` en verde sobre `develop`.
2. Cola escrita y prompts con criterio ejecutable.
3. Sin trabajo sin commitear en el árbol del ciclo.
4. `bin/ciclo --fondo` (o servicio instalado) y `bin/ciclo --estado` para confirmar.
