<!-- ciclo: critica=si turno-noche=1 rama=feature/disparador-sync etapas=3 descongela=tests -->

# Tarea 16 — TE-19: disparador único de sincronización

## Qué hacer

Hoy `SyncEngine.sincronizar()`, `EvidenciaSyncEngine.sincronizar()` y
`CatalogoRepository.pull()` existen, están probados y registrados en el DI
(`service_locator.dart`), pero **nada en `lib/` los invoca en producción**
(confirmado por grep: cero resultados fuera de comentarios). La app captura y
encola perfecto — outbox, evidencias, cursor de catálogo — pero nunca sube ni
baja nada aunque haya señal. Comprobado a mano en un dispositivo real: con
datos ya sembrados del lado servidor, "Órdenes vigentes" muestra "No hay
órdenes vigentes" para siempre, porque el pull que las traería jamás se
dispara.

Esta tarea conecta los tres a un disparador real: conectividad recuperada y
apertura de la app. Es la pieza que le falta a cinco HU ya integradas
(HU-05/06/07, TE-05/06/07) para que el propósito completo de la app — offline
first, pero sincronizando de verdad en cuanto hay señal — exista en producción
y no solo en tests.

Cargá `verificacion` siempre, `protocolo-sync` (toca `CatalogoRepository`,
que escribe a `drift`) y `flujo-git-pr` antes de rama/commit/PR.

### Piezas a construir

1. **`CatalogoRepository.pull()` tiene que poder repetirse hasta agotar el
   catálogo.** Hoy trae una sola página por llamada (deuda ya señalada al
   integrar TE-06, `docs/gestion/cola_tareas.md` § Deuda técnica) y devuelve
   `Future<void>`, sin forma de que quien lo llama sepa si quedó algo más por
   traer. `docs/api/openapi.yaml` (`GET /api/sync/catalogo`) no expone un
   campo explícito de "hay más" — confirmá contra el contrato real y, si
   hace falta, contra cómo lo implementa `agrocom-api` del lado servidor
   (no lo asumas: puede ser "si las cuatro listas vinieron vacías, se
   terminó" u otro criterio) antes de decidir cómo `pull()` señala que debe
   repetirse. Cambiá su firma lo mínimo necesario para que el disparador
   pueda invocarlo en loop hasta agotar el catálogo — es un cambio aditivo
   sobre un método ya probado, no una migración de esquema `drift`.
2. **Un watcher nuevo en `nucleo/sync/`** (mismo patrón que
   `VersionWatcher`/`AvisosLocalesWatcher`: clase con `iniciar()`, sin
   Bloc/Cubit, vive tanto como la app) que:
   - Escuche `connectivity_plus` (`Connectivity().onConnectivityChanged`,
     ya declarado en `pubspec.yaml` sin usar) y dispare un ciclo completo
     cuando se pasa de sin-conectividad a con-conectividad.
   - Dispare también un ciclo al llamar `iniciar()` (arranque de la app),
     sin esperar su resultado antes de `runApp` — mismo criterio que
     `VersionWatcher`/HU-20 (invariante 1 de `CLAUDE.md`: la app nunca
     depende de que la red responda para arrancar).
   - Un ciclo completo es: `CatalogoRepository.pull()` en loop hasta
     agotarlo, después `SyncEngine.sincronizar()`, después
     `EvidenciaSyncEngine.sincronizar()`. Los tres son independientes entre
     sí (no comparten transacción) — si uno falla o no hay señal a mitad de
     camino, que se resuelva por las excepciones que cada uno ya maneja
     (`ApiExcepcionRed` no se propaga como error, ver sus propios archivos);
     no agregues reintentos con backoff ni temporizador propio, no es el
     alcance de esta tarea.
3. **Wiring en `main_piloto.dart` y `main_auxiliar.dart`**, instanciado una
   sola vez vía `getIt`, igual que `VersionWatcher` hoy — nunca duplicado ni
   importado cruzado entre `piloto/`/`auxiliar/` (va en `nucleo/`,
   invariante 7 de `CLAUDE.md`).

## Cómo repartir las etapas

- Etapa 1: `CatalogoRepository.pull()` con loop hasta agotar el catálogo +
  tests (mock de `ApiClient` con 2-3 páginas encadenadas, confirmar que para
  cuando corresponde).
- Etapa 2: el watcher nuevo, con tests (fake stream de conectividad, mocks de
  los tres motores/repositorio, confirmar que dispara en la transición
  sin-señal→con-señal y al iniciar, y que no dispara en cualquier otro
  cambio de estado de conectividad).
- Etapa 3: wiring en ambos `main_*.dart` + test de que `configurarDependencias`
  deja el watcher listo para instanciarse en ambos flavors.

## Qué NO hacer

- No toques la lógica interna de `SyncEngine.sincronizar()` ni de
  `EvidenciaSyncEngine.sincronizar()` — están integrados y probados; esta
  tarea solo los invoca desde afuera.
- No arregles ahora que `CatalogoRepository.pull()` no persiste `trabajos`
  (el `GET /api/sync/catalogo` los devuelve, pero el repositorio hoy solo
  aplica `ordenes`/`lotes`/`personas`) — es un hallazgo real, pero de otra
  tarea; no mezcles el alcance.
- No conectes `SyncCubit` a ninguna pantalla nueva — sigue sin consumidor en
  la UI, y eso es trabajo de `flutter-ui` en una tarea aparte, no de esta.
- No agregues reintentos con backoff, cola de reintentos propia ni
  temporizador periódico — el disparo es por evento (conectividad, apertura
  de app), no por polling.
- No migres ninguna tabla `drift` — si tu cambio en `pull()` te tienta a
  agregar una columna nueva para "recordar si hay más", resolvelo sin tocar
  el esquema (p. ej. con lo que ya devuelve la respuesta HTTP de cada
  llamada), y si de verdad hace falta una migración, parate y decilo en el
  reporte en vez de escribirla.

## Criterio de aceptación

```
./bin/verify
```
Exit code 0, con tests que cubran: `pull()` repitiendo hasta agotar el
catálogo, el watcher disparando los tres mecanismos en el orden correcto
ante conectividad recuperada y ante inicio, y el wiring presente en ambos
flavors.

## Cierre obligatorio de cada etapa

`runs/16.estado`, `runs/16.md` al final de cada sesión. `runs/16.pr.md` solo
al cerrar con `OK`.

## Commits

Separados por pieza coherente: cambio en `CatalogoRepository.pull()`, watcher
nuevo, wiring en los `main_*.dart`. Español, imperativo, el porqué antes que
el qué. Sin trailer `Co-Authored-By`.
