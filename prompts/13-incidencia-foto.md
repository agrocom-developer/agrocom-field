<!-- ciclo: critica=si turno-noche=1 rama=feature/incidencia-foto etapas=3 descongela=tests -->

# Tarea 13 — HU-08: registrar incidencia con foto

## Qué hacer

El piloto, durante una sesión activa, registra un evento puntual (caldo /
ESC / batería / mecánica / clima / otro) con una foto **siempre
obligatoria** — sin foto no hay incidencia (mismo espíritu que "sin captura
no cierra" de HU-09). Queda encolada para `POST /api/sync`, tipo
`incidencia`.

TE-07 (tarea 12, ya integrada) dejó la cola de evidencias entera pero sin
consumidor: `EvidenciaRepository.capturarEvidencia({bytesOriginales, tipo,
fecha})` en `lib/nucleo/evidencias/evidencia_repository.dart` comprime +
hashea + persiste + encola, y devuelve el `uuid_cliente` de la evidencia.
Esta tarea es la primera que lo llama de verdad — con `tipo:
'foto_incidencia'` — y la primera que registra `EvidenciaRepository`/
`EvidenciaSyncEngine` en `nucleo/di/service_locator.dart`.

Es tarea `critica=si`: agrega una tabla nueva a `nucleo/db` (lista de "qué
no delegar sin revisión línea por línea" de `CLAUDE.md`). Se integra igual,
anotala en `runs/revision-pendiente.txt`.

Cargá `verificacion` siempre, `protocolo-sync` (toca el esquema `drift` y
`ColaSync`), `flujo-git-pr` antes de rama/commit/PR.

### El contrato exacto — confirmado línea por línea contra `agrocom-api`

`RegistroIncidencia.php` (`app/Dominios/Operaciones/Contratos/`) y
`RegistroSync` en `docs/api/openapi.yaml` de
`/Applications/MAMP/htdocs/agrocom-api`:

- `uuid_cliente`: del EVENTO incidencia (nuevo, generado en el dispositivo).
- `sesion_uuid_cliente`: `uuid_cliente` de apertura de la sesión activa —
  nunca id de servidor.
- `tipo_incidencia`: enum `caldo` / `esc` / `bateria` / `mecanica` /
  `clima` / `otro`. **El campo JSON se llama `tipo_incidencia`, NO `tipo`**
  — `tipo` ya es la key que distingue el TIPO DE REGISTRO del lote
  (`'incidencia'`); dos `tipo` en el mismo objeto colisionarían.
- `descripcion`: opcional, texto libre.
- `hora`: cuándo ocurrió.
- `evidencia_foto_uuid_cliente`: **REQUERIDO** — `uuid_cliente` de una
  evidencia ya subida vía `POST /api/evidencias` con `tipo:
  foto_incidencia`. Sin ella, el servidor rechaza el registro completo.

Nadie llama hoy a `EvidenciaSyncEngine.sincronizar()` ni a
`SyncEngine.sincronizar()` en producción (confirmado por grep: cero
resultados en `lib/` fuera de un comentario) — conectar el trigger
automático (conectividad recuperada, temporizador) es deuda técnica ya
anotada aparte en `docs/gestion/cola_tareas.md`, **no de esta tarea**.
Alcanza con registrar `EvidenciaSyncEngine` en el service locator, mismo
patrón que `SyncEngine`, para que quede listo cuando esa pieza se conecte.

### Piezas a construir

1. **Esquema `drift`**: `lib/nucleo/db/tablas/incidencia_local.dart`, tabla
   `IncidenciaLocal` — `uuidCliente` TEXT PK (generado en el dispositivo,
   invariante 2); `sesionUuidCliente` TEXT; `tipo` TEXT **plano, sin
   `textEnum`** (catálogo cerrado del SERVIDOR — mismo criterio que
   `SesionLocal.motivoCierre`/`EvidenciaLocal.tipo`, no el de
   `SesionLocal.estado`, que es vocabulario local); `descripcion` TEXT
   nullable; `hora` DATETIME; `evidenciaFotoUuidCliente` TEXT. Subí
   `schemaVersion` (leé el valor real en `lib/nucleo/db/database.dart` al
   empezar — hoy es 5, no asumas que sigue así) con su rama `if (from <
   N)` que solo crea la tabla nueva. Test
   `test/nucleo/db/migracion_incidencia_test.dart`, mismo patrón que
   `migracion_evidencia_test.dart` (`onCreate` + migración real armando a
   mano el esquema anterior completo con datos preexistentes, verificando
   que nada se pierde).
2. **Dominio**: catálogo `TipoIncidencia` (los 6 valores de arriba) — Dart
   puro, testeable sin emulador, mismo criterio que
   `reglas_condiciones.dart`/`reglas_sesion.dart` de `sesion_vuelo`.
3. **`IncidenciaRepository`**: `registrarIncidencia({sesionUuidCliente,
   tipo, descripcion, hora, bytesFoto})` — valida que la sesión exista y
   esté abierta ANTES de comprimir/persistir la foto (no tiene sentido
   gastar la captura si la sesión no es válida — mismo criterio que
   `SesionRepository.verificarTrabajoExiste`), llama
   `EvidenciaRepository.capturarEvidencia(bytesOriginales: bytesFoto, tipo:
   'foto_incidencia', fecha: hora)`, y con el `uuid_cliente` que devuelve
   arma el insert de `IncidenciaLocal` + encolado en `ColaSync`
   (`tipoEntidad: 'incidencia'`) en una transacción — mismo patrón que
   `TrabajoRepository`/`SesionRepository` (invariante 3).
4. **UI**: punto de entrada ("reportar incidencia") desde
   `sesion_vuelo_vista.dart`/`SesionVueloPantalla` cuando la sesión está
   activa. Pantalla: selector de tipo (6 opciones), descripción opcional,
   captura de foto con la cámara. Agregá `image_picker` (paquete oficial
   de flutter.dev) a `pubspec.yaml` — mockeá su `MethodChannel` en tests,
   mismo patrón ya usado para `torch_light`/`flutter_local_notifications`/
   `flutter_image_compress` (ver `notificador_local_plugin_test.dart`).
5. **DI**: en `service_locator.dart`, en orden de dependencia:
   `CompresorEvidenciaFlutterImageCompress`, el `Directory` de evidencias
   (`resolverDirectorioEvidencias`), `EvidenciaRepository`,
   `EvidenciaSyncEngine`, y el repositorio/bloc de incidencias.

Decidí si esto va a una feature nueva `lib/features/incidencias/`
(domain/data/presentation, patrón feature-first ya usado en
`avisos_locales`/`emergencia`/`ordenes` — y ya sugerido en
`docs/vision.md`) o si conviene ubicarlo junto a `sesion_vuelo`. Preferí lo
primero por ser conceptualmente independiente del ciclo de sesión aunque
lo referencie; es una sugerencia, no un mandato.

## Cómo repartir las etapas

- Etapa 1: esquema + migración (crítica) + su test.
- Etapa 2: dominio + `IncidenciaRepository` + tests (drift en memoria +
  directorio temporal real, mismo patrón que `evidencia_repository_test.dart`;
  incluí el caso de sesión inexistente/cerrada rechazando ANTES de escribir).
- Etapa 3: UI + bloc + DI + wiring de navegación + tests de widget/bloc.

## Qué NO hacer

- No inventes un endpoint dedicado de incidencias — va por el `POST
  /api/sync` genérico (`ColaSync`, tipo `incidencia`); la evidencia sube
  aparte, por `EvidenciaRepository`/`EvidenciaSyncEngine`.
- No le pongas `textEnum` a la columna `tipo` de `IncidenciaLocal` — ese
  catálogo lo valida y es dueño el servidor.
- No conectes el trigger automático completo de sincronización
  (conectividad recuperada, timers) — es deuda técnica anotada aparte.
- No la habilites en el flavor `auxiliar` — ese flavor no tiene
  `SesionLocal` (invariante 4: la sesión la escribe el piloto), así que no
  tiene `sesionUuidCliente` contra qué referenciar.

## Criterio de aceptación

```
./bin/verify
```
Exit code 0. Además: test de migración v(N-1)→v(N) sin pérdida de datos
preexistentes, tests de `IncidenciaRepository` (incluida la validación de
sesión inexistente/cerrada), y tests de la pantalla/bloc (selector de tipo,
foto obligatoria bloqueando el envío si falta).

## Cierre obligatorio de cada etapa

`runs/13.estado` (`PARCIAL`/`OK`/`BLOQUEADA`) y `runs/13.md` (qué se hizo,
qué falta, concreto) al final de cada sesión. `runs/13.pr.md` (título +
cuerpo del PR) solo al cerrar con `OK`.

## Commits

Agrupados por pieza coherente: esquema+migración, dominio, repositorio,
UI+bloc+DI. Español, imperativo, el porqué antes que el qué. Sin trailer
`Co-Authored-By`.
