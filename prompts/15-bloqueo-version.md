<!-- ciclo: critica=no turno-noche=1 rama=feature/bloqueo-version etapas=2 descongela=tests -->

# Tarea 15 — HU-20 (lado app): bloqueo por versión mínima

## Qué hacer

La app consulta `GET /api/version` y bloquea el uso si el `version_code`
instalado quedó por debajo del mínimo autorizado por el dueño — sin FCM,
por polling, coherente con la decisión ya tomada del lado `agrocom-api`
(HU-20 completa: "ningún RC se actualiza sin mi visto bueno").

No toca `nucleo/sync` ni `nucleo/db` — no es crítica.

Cargá `verificacion` siempre, `flujo-git-pr` antes de rama/commit/PR. No
hace falta `protocolo-sync`: esto no pasa por `ColaSync` ni por el motor de
sync.

### El contrato — confirmado en `agrocom-api/docs/api/openapi.yaml`

`GET /api/version`, **sin autenticación** (la app puede no tener token
emitido todavía cuando consulta): devuelve `{minima: VersionApk|null,
vigente: VersionApk|null}`. `VersionApk`: `{version` (SemVer string),
`version_code` (int), `url_descarga` (uri)`}`. Ambas claves son `null` si el
dueño todavía no autorizó ninguna versión — en ese caso la app **no**
bloquea, no hay mínima contra qué comparar.

### Piezas a construir

1. Agregá `package_info_plus` a `pubspec.yaml` para leer el `version_code`
   instalado en runtime (`PackageInfo.fromPlatform().buildNumber`) —
   mockeá su `MethodChannel` en tests, mismo patrón ya usado en el repo
   (`torch_light`, `flutter_local_notifications`, `flutter_image_compress`
   — ver `notificador_local_plugin_test.dart`).
2. `lib/nucleo/version/` (nuevo): un repositorio/servicio que llama
   `ApiClient.get('/api/version')` y devuelve el resultado tipado. Este
   endpoint no lleva `tokenDispositivo` — confirmá si
   `ApiClient`/`AuthInterceptor` ya tolera una llamada sin token (mirá
   `auth_interceptor.dart`) o si hace falta un cliente `dio` aparte sin el
   interceptor para este caso puntual.
3. Comparación: bloqueada = `minima != null && versionCodeInstalado <
   minima.versionCode`. Un fallo de red al consultar **no bloquea** la app
   (invariante 1 de `CLAUDE.md`: la app no depende de que la red
   responda) — solo bloquea una respuesta exitosa con `version_code` por
   debajo de la mínima.
4. Polling: repetir la consulta cada tanto mientras la app está en primer
   plano (`Timer.periodic` o equivalente) — sin FCM, mismo criterio que
   `HU-62`/HU-20 de `agrocom-api`.
5. Pantalla de bloqueo: simple, sin vía de escape, con la versión mínima
   requerida y el `url_descarga` — se muestra por encima de cualquier otra
   pantalla cuando el estado es "bloqueada". Es infraestructura común: va
   en `nucleo/`, se conecta igual en ambos flavors, nunca duplicada entre
   `piloto`/`auxiliar`.
6. Conectala en `app.dart` o en cada `main_*.dart`, donde ya se arma el
   árbol raíz — sin tocar la lógica de negocio de las demás features.

## Cómo repartir las etapas

- Etapa 1: repositorio/servicio de versión + comparación + tests (con
  `ApiClient` mockeado: `minima` null no bloquea, `version_code` igual no
  bloquea, por debajo bloquea, error de red no bloquea).
- Etapa 2: polling + pantalla de bloqueo + wiring en ambos flavors + tests
  de widget.

## Qué NO hacer

- No le agregues autenticación a esta llamada — el endpoint es
  explícitamente público.
- No bloquees comparando contra `vigente` — el contrato es explícito: solo
  `minima` importa para el bloqueo. `vigente` es informativo (para avisar
  de una actualización disponible sin forzarla) — dejalo sin pantalla si
  no alcanza el tiempo, no es criterio de esta HU.
- No dejes que un error de red tranque la app — invariante 1 de
  `CLAUDE.md`.

## Criterio de aceptación

```
./bin/verify
```
Exit code 0, con tests de los 4 casos de comparación de versión y de la
pantalla de bloqueo.

## Cierre obligatorio de cada etapa

`runs/15.estado`, `runs/15.md` al final de cada sesión. `runs/15.pr.md`
solo al cerrar con `OK`.

## Commits

paquete+servicio de versión, polling+pantalla+wiring. Español, imperativo,
el porqué antes que el qué. Sin trailer `Co-Authored-By`.
