<!-- ciclo: critica=no turno-noche=1 rama=feature/login-token-dispositivo etapas=2 descongela=tests -->

# Tarea 03 — HU-03 (consumo): pantalla de login real

## Qué hacer

Completar el lado app de HU-03: hoy `TokenStoreSeguro` (`lib/nucleo/auth/
token_store.dart`) ya guarda/lee el token de forma segura, pero no existe la
pantalla que lo obtiene — `AgrocomApp` (`lib/app.dart`) siempre muestra el
mismo `Scaffold` placeholder, sin login. Esta tarea es independiente de las
tareas 01/02 (motor de sync): no dependas de esas ramas, arrancá desde
`develop` actualizado (puede ser antes, en paralelo o después de que se
integren, según cómo corra la cola).

Cargá el skill `verificacion` antes de escribir código, y `flujo-git-pr`
antes de rama/commits/PR. No es tarea crítica (no toca `nucleo/sync` ni
`nucleo/db`).

Contrato de referencia: `POST /api/auth/token` en
`/Applications/MAMP/htdocs/agrocom-api/docs/api/openapi.yaml` (operationId
`emitirTokenDispositivo`): recibe `username`, `password`, `uuid_dispositivo`
y opcionalmente `nombre_dispositivo`/`role_id`; responde `201` con el token,
`401` credenciales inválidas, `409` si el usuario tiene más de un rol vivo
(body `{message, roles}`), `422` si falta algún campo obligatorio.

Piezas a construir:

1. **Identificador de dispositivo**: `uuid_dispositivo` se genera una sola
   vez (paquete `uuid`, ya en `pubspec.yaml`) y se persiste — se reutiliza en
   cada intento de login, nunca se regenera (si se regenerara, el servidor
   vería cada reintento como un dispositivo nuevo). Mismo mecanismo de
   almacenamiento seguro que ya usa `TokenStore` (`flutter_secure_storage`),
   como store hermano o ampliando el existente — a tu criterio.
2. **Servicio/caso de uso de login** en `lib/nucleo/auth/`: llama
   `POST /api/auth/token` vía `ApiClient`, y ante `201` guarda el token con
   `TokenStore.guardarToken`. No maneja el selector de rol de `409` (ver
   "Qué NO hacer") — simplemente lo expone como un resultado distinguible
   para que la pantalla muestre un mensaje.
3. **Pantalla de login** (Bloc/Cubit — pantalla simple con estados
   inicial/cargando/error, así que Cubit alcanza; feature-first, ver ADR
   0005 de `agrocom-api`): campos usuario/contraseña, botón de ingresar,
   estado de carga, mensaje de error legible para `401`/`422`/`409`/sin red.
   Ubicación a tu criterio (`lib/features/auth/` compartida por ambos
   flavors, o dentro de `nucleo/` si no amerita capas `presentation/domain/
   data` completas) — consultá `arquitectura-flutter` si dudás; lo que no
   vale es que quede importada cruzada entre un futuro `piloto/` y
   `auxiliar/` (invariante 7 de `CLAUDE.md`), porque ambos flavors la
   necesitan igual.
4. **Arranque de la app** (`lib/app.dart`, y lo que haga falta en
   `main_piloto.dart`/`main_auxiliar.dart`): si `TokenStore.leerToken()`
   devuelve `null`, mostrar la pantalla de login; si ya hay token guardado,
   mostrar el `Scaffold` placeholder actual tal cual está (no construyas una
   pantalla "home" nueva — eso es HU-04/HU-05, fuera de esta tarea). Después
   de un login exitoso, navegar a ese mismo placeholder.
5. Registrar en `lib/nucleo/di/service_locator.dart` lo que haga falta
   (el store de `uuid_dispositivo`, el servicio de login).

## Cómo repartir las etapas

- Etapa 1: identificador de dispositivo + servicio de login (`domain`/
  lógica, sin UI) con sus tests unitarios (201/401/409/422/error de red).
- Etapa 2: pantalla de login (Cubit + widgets) + wiring en `app.dart`/
  `main_*.dart`, con tests de widget/bloc.

## Qué NO hacer

- No implementar el selector de rol para el caso `409` (elegir `role_id` y
  reintentar) — es HU-69, tarea aparte del plan de sprints, con su propio
  ADR (0005 de este repo). Esta tarea solo necesita mostrar un mensaje claro
  de que ese caso todavía no está soportado, sin crashear ni guardar ningún
  token a medias.
- No implementes "recordarme", biometría, ni refresco automático de token —
  fuera de alcance de HU-03, no están en su criterio de aceptación ni en el
  contrato.
- No construyas ninguna pantalla "home" real — el placeholder de
  `app.dart` queda como está, solo cambia cuándo se muestra.
- No toques `nucleo/sync` ni `nucleo/db` — esta tarea es pura
  `nucleo/auth` + una pantalla.

## Criterio de aceptación

`./bin/verify` devuelve 0, con tests que cubran los cuatro resultados de
`POST /api/auth/token` (`201`, `401`, `409`, `422`) más el caso sin red, y al
menos un test de que la app arranca en login sin token guardado y salta el
login cuando ya hay uno.

## Cierre obligatorio de cada etapa

`runs/03.estado` con una sola palabra (`PARCIAL`/`OK`/`BLOQUEADA`).
`runs/03.md` con qué se hizo y qué falta. Al cerrar con `OK`,
`runs/03.pr.md` con título en la primera línea y cuerpo debajo.

## Commits

Uno para el identificador de dispositivo, uno para el servicio de login, uno
para la pantalla, uno para el wiring de arranque si no entra natural en los
anteriores. Español, imperativo, explicando el porqué. Sin trailer
`Co-Authored-By`.
