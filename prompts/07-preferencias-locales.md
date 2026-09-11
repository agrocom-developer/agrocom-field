<!-- ciclo: critica=no turno-noche=1 rama=feature/preferencias-locales etapas=2 descongela=tests -->

# Tarea 07 — TE-16: `nucleo/preferencias`

## Qué hacer

Construir el almacén de preferencias de UI (tema, idioma, último flavor
usado) que `docs/gestion/plan_sprints.md` (Sprint 15, TE-16) pide como
infraestructura separada del outbox/`drift` — **ninguna preferencia de UI
compite con datos de sync**. Es una TE habilitante, sin pantalla propia:
HU-59 (selector de tema/idioma) la consume más adelante, pero HU-59 sigue
bloqueada en la cola (depende de TE-17/i18n, que exige un ADR nuevo que este
ciclo no puede fijar sin revisión del dueño) — no la construyas ni le busques
un consumidor todavía. Esta tarea termina en la pieza de infraestructura
sola, con sus tests.

Cargá `verificacion` antes de cerrar etapas y `flujo-git-pr` antes de
rama/commits/PR. No es tarea crítica (no toca `nucleo/sync` ni `nucleo/db`).

### Piezas a construir

1. **`pubspec.yaml`** — agregar `shared_preferences` (versión estable
   vigente en pub.dev al momento de implementar).
2. **`lib/nucleo/preferencias/preferencias_store.dart`** — mismo patrón que
   `lib/nucleo/auth/rol_activo_store.dart` (interfaz abstracta + impl
   concreta, para poder fakear en tests sin depender del plugin real):
   - `abstract class PreferenciasStore`, con:
     - `Future<ThemeMode> leerTema()` / `Future<void> guardarTema(ThemeMode)`
       — default `ThemeMode.system` si no hay nada guardado.
     - `Future<String?> leerIdioma()` / `Future<void> guardarIdioma(String?)`
       — código de idioma (`'es'`/`'pt'`) o `null` (sigue el del sistema);
       `null` también borra la preferencia guardada.
     - `Future<Flavor?> leerUltimoFlavor()` /
       `Future<void> guardarUltimoFlavor(Flavor)`.
   - `class PreferenciasStoreLocal implements PreferenciasStore` — usa
     `SharedPreferences` (inyectable/lazy igual que `FlutterSecureStorage`
     en `RolActivoStoreSeguro`, para que el test controle el `Future` de
     `getInstance()`). Tres claves separadas y con prefijo propio
     (`preferencias_tema`, `preferencias_idioma`,
     `preferencias_ultimo_flavor`) — nunca una clave que se confunda con
     algo de `ColaSync`/`drift`.
   - **No importar `AppDatabase` ni `OutboxRepository` en este archivo** —
     es la garantía de "nunca compite con datos de sync" que pide el CA;
     si en algún momento sentís la tentación de guardar algo acá que
     debería sincronizarse, es la señal de que no es una preferencia de UI.
3. **`lib/nucleo/di/service_locator.dart`** — registrar
   `PreferenciasStore` como lazy singleton (`PreferenciasStoreLocal.new`),
   mismo lugar donde ya están `TokenStore`/`RolActivoStore`.

### Tests

`test/nucleo/preferencias/preferencias_store_test.dart` — usar
`SharedPreferences.setMockInitialValues({})` (o el mecanismo equivalente de
la versión instalada) para simular persistencia sin plugin real:

- Sin nada guardado: `leerTema()` devuelve `ThemeMode.system`,
  `leerIdioma()`/`leerUltimoFlavor()` devuelven `null`.
- Guardar y releer cada preferencia devuelve el mismo valor.
- **Persiste "entre reinicios"**: guardar con una instancia del store,
  construir una instancia nueva (nuevo `SharedPreferences.getInstance()`)
  y confirmar que la segunda lee lo que la primera guardó — es el criterio
  literal de la HU/TE, no alcanza con un getter/setter en memoria.
- Guardar `idioma: null` borra una preferencia ya guardada (vuelve a leer
  `null`, no una cadena `"null"`).

## Cómo repartir las etapas

- Etapa 1: `PreferenciasStore`/`PreferenciasStoreLocal` + dependencia en
  `pubspec.yaml` + registro en DI, con los tests completos de arriba.
- Etapa 2: solo si queda algo suelto de la etapa 1 (esta TE es chica,
  0,5 d en el plan — es razonable cerrarla entera en la etapa 1 con `OK`
  directo si `./bin/verify` ya da verde).

## Qué NO hacer

- No construir ninguna pantalla de ajustes ni wiring a `MaterialApp` (eso
  es HU-59, bloqueada — ver "Qué hacer"). Un store sin consumidor todavía
  es normal para una TE habilitante (mismo patrón que TE-04 antes de que
  existiera `SyncEngine`).
- No tocar `nucleo/sync` ni `nucleo/db` — esta pieza es deliberadamente
  ajena a `drift`.
- No agregar i18n real (`flutter_localizations`/ARBs) — eso es TE-17,
  bloqueada por su propio ADR nuevo.
- No inventar más preferencias de las tres pedidas (tema/idioma/último
  flavor). Si te tienta agregar algo "ya que estás", no lo hagas.

## Criterio de aceptación

`./bin/verify` devuelve 0, con los tests de
`preferencias_store_test.dart` descritos arriba en verde.

## Cierre obligatorio de cada etapa

`runs/07.estado`: `PARCIAL`/`OK`/`BLOQUEADA`.

`runs/07.md`: qué se hizo y qué falta, concreto.

Al cerrar con `OK`, `runs/07.pr.md`: título en la primera línea, cuerpo
debajo.

## Commits

Agrupados por pieza coherente, español, imperativo, el porqué antes que el
qué: dependencia + `PreferenciasStore`/`PreferenciasStoreLocal` con tests,
después el registro en DI si no entró en el mismo commit. Sin trailer
`Co-Authored-By`.
