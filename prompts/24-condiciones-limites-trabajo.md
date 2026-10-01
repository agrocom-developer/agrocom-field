<!-- ciclo: critica=si turno-noche=1 rama=feature/condiciones-limites-trabajo etapas=3 descongela=tests -->

# Tarea 24 — condiciones con los límites efectivos del trabajo

## Qué hacer

Desde `agrocom-api` #310, el servidor valida el registro `condiciones` con los
límites **efectivos** del trabajo de la sesión, no con constantes. La app
sigue decidiendo con constantes en `reglas_condiciones.dart` (viento 17,
temperatura 30, humedad 90). Si no coinciden, el servidor rechaza sesiones ya
cargadas en campo, sin conectividad y sin forma de corregirlas.

Cargá `verificacion`, `protocolo-sync` y `flujo-git-pr`.

Fuente: el **código** de `agrocom-api` (solo lectura, develop @ `a47e5280`),
sobre todo `Operaciones/Dominio/LimitesEfectivos` (`resolver`,
`admiteCondiciones`), `Contratos/RegistroCondiciones` y
`EscrituraSincronizacionEloquent::registrarCondiciones`.

Pasos:

1. **Regla.** Replicá exactamente `LimitesEfectivos::admiteCondiciones`:
   - qué límite aplica;
   - si la comparación es estricta o no;
   - qué pasa con `humedad_min_pct` cuando la orden de trabajo no la fija;
   - qué valor usa el servidor cuando el trabajo no tiene orden de trabajo o lo abrió la app (`abrirTrabajo`).

   Si algún caso no se puede determinar leyendo el código, la tarea queda
   `BLOQUEADA` con la pregunta exacta.
2. **Límites del trabajo.** La apertura de sesión obtiene los límites desde
   `trabajo_catalogo`, buscando por el `uuid_cliente` del trabajo, y
   `reglas_condiciones.dart` los recibe como parámetro. Las constantes quedan
   solo como el fallback que usa el servidor en ese mismo caso. `Decimal`,
   nunca `double`.
3. **Formulario.** `sesion_vuelo_vista.dart` pide observación y firma
   exactamente cuando el servidor las exigiría. Mismas `Key`s.
4. **Tests**, al menos estos casos:
   - límite propio más estricto que la constante;
   - límite propio más permisivo que la constante;
   - trabajo sin orden de trabajo;
   - humedad mínima fijada y sin fijar.

## Cómo repartir las etapas

- Etapa 1: regla de dominio con sus tests.
- Etapa 2: lectura de límites en el repositorio y apertura de sesión.
- Etapa 3: formulario y tests de widget.

## Qué NO hacer

- No cambies `SesionBloc` más allá de pasarle los límites.
- No cambies el payload del sync.
- No toques el esquema `drift`. La limpieza de `orden_catalogo` es la tarea 25.
- No edites nada de `agrocom-api`.

## Criterio de aceptación

- `./bin/verify` devuelve 0.
- La regla de la app coincide con `admiteCondiciones` en los casos de borde: igual al límite, límite propio más estricto y más permisivo que la constante, humedad mínima fijada y sin fijar.
- Un trabajo sin fila en `trabajo_catalogo` (abierto por la app) usa los defaults del servidor.
- El formulario muestra observación y firma exactamente en esos casos.

## Cierre obligatorio de cada etapa

- `runs/24.estado`: `PARCIAL`, `OK` o `BLOQUEADA`.
- `runs/24.md`: qué se hizo y qué falta.
- Al cerrar con `OK`, `runs/24.pr.md`, con el título en la primera línea.

## Commits

Uno por pieza: regla, repositorio, formulario. En español, imperativo, con el porqué. Sin `Co-Authored-By`.
