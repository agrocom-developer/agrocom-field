<!-- ciclo: critica=si turno-noche=1 rama=feature/sync-push-lote etapas=3 descongela=tests -->

# Tarea 01 — TE-05 (lado app): motor de sync real (push) + prueba de replay

## Qué hacer

Reemplazar el esqueleto de `SyncEngine` (`lib/nucleo/sync/sync_engine.dart`,
método `sincronizar()` que hoy solo lanza `UnimplementedError`) por la lógica
real de push contra `POST /api/sync`, y escribir la prueba de replay que
`CLAUDE.md` exige (invariante 10) antes de que exista cualquier pantalla del
esqueleto vertical. Esta es la tarea que el propio código ya señala como
pendiente: leé el comentario completo de `sync_engine.dart` antes de tocar
nada, ya deja documentado el contrato mínimo.

Cargá los skills `verificacion` y `protocolo-sync` antes de escribir código, y
`flujo-git-pr` antes de crear la rama/commits/PR. Es tarea `critica=si`
(motor de sync, lista de "qué no delegar sin revisión línea por línea" de
`CLAUDE.md`): igual se implementa y se integra, queda anotada para revisión
posterior — no la conviertas en borrador ni la retengas por eso.

Contrato de referencia: `POST /api/sync` en
`/Applications/MAMP/htdocs/agrocom-api/docs/api/openapi.yaml` (operationId
`sincronizarLote`, esquemas `RegistroSync`/`ResultadoSync`). Repasá también
`docs/vision.md` de este repo, sección "El protocolo de sincronización".

Piezas a construir:

1. **Repositorio de outbox** (nombre y ubicación a tu criterio dentro de
   `lib/nucleo/sync/`, coordiná con `arquitectura-flutter` si dudás) sobre
   `AppDatabase`/`ColaSync` (`lib/nucleo/db/`):
   - Leer las filas en estado `pendiente` **ordenadas por `secuencia`
     ascendente** — nunca por `creadoEn` ni por cualquier reloj (invariante 5
     de `CLAUDE.md`).
   - Actualizar el estado de una fila (`confirmado` / `rechazado` +
     `motivoRechazo`) por `uuidCliente`.
   - Ninguna fila que ya esté `confirmado` se vuelve a escribir (invariante 6).
2. **`SyncEngine.sincronizar()` real**:
   - Arma `{"registros": [...]}` a partir de las filas pendientes: cada
     elemento junta `tipo` (la columna `tipoEntidad`), `uuid_cliente`
     (`uuidCliente`) y el resto de los campos del `payload` (JSON ya
     guardado).
   - Llama `ApiClient.post('/api/sync', data: ...)`.
   - Por cada `ResultadoSync` de la respuesta (mismo orden del arreglo de
     entrada, según el contrato): `aplicado`/`duplicado` → `confirmado`;
     `rechazado` → `rechazado` + `motivo`. Un `rechazado` en una fila nunca
     frena el procesamiento del resto del lote — el propio contrato ya lo
     garantiza fila por fila del lado servidor.
   - Ante `ApiExcepcionRed` (`lib/nucleo/api/api_excepcion.dart` ya la
     documenta como "el caso normal en el lote, no un error"): las filas
     quedan tal cual (`pendiente`), listas para el próximo ciclo. No es un
     `EstadoMotorSync.error` — es simplemente "no hay señal ahora".
   - Ante `ApiExcepcionServidor`/`ApiExcepcionDesconocida`: emitir
     `EstadoMotorSync.error` sin tocar el estado de las filas del outbox
     (no hay forma de saber qué aplicó el servidor sin una respuesta parseada
     — no asumas nada, dejalas `pendiente`).
   - Publicar `EstadoMotorSync.sincronizando` al arrancar el ciclo y
     `EstadoMotorSync.ocioso` al terminar sin error.
3. **Prueba de replay obligatoria** (invariante 10 de `CLAUDE.md`, no
   opcional, no se puede simular ni dejar vacía — ver skill `verificacion`):
   contra una base `drift` en memoria (`NativeDatabase.memory()` o
   equivalente) y un servidor simulado que se comporte como el real
   (idempotente por `uuid_cliente`: el mismo `uuid_cliente` ya "aplicado"
   responde `duplicado` la segunda vez), aplicar el mismo lote de sync **10
   veces seguidas, en orden**, y aparte en **desorden parcial** (dividir el
   lote en sub-lotes y mandarlos en distinto orden entre corridas) — el
   estado final de `ColaSync` tiene que ser idéntico en todos los casos.
4. Registrar `AppDatabase`, `SyncEngine`, `SyncCubit` y el repositorio de
   outbox en `lib/nucleo/di/service_locator.dart` (el comentario que hoy dice
   "se registran acá cuando TE-04/TE-05/TE-06 los agreguen" — esta tarea
   cubre la parte de TE-05).

## Cómo repartir las etapas

- Etapa 1: repositorio de outbox (leer pendientes ordenados, actualizar
  estado) con sus tests unitarios.
- Etapa 2: `SyncEngine.sincronizar()` real contra `ApiClient` mockeado
  (`mocktail`, ya está en `pubspec.yaml`) — casos `aplicado`, `duplicado`,
  `rechazado` mezclados en un mismo lote, y el caso `ApiExcepcionRed`.
- Etapa 3: la prueba de replay (la pieza que hace `OK` a la tarea) +
  wiring en `service_locator.dart`.

## Qué NO hacer

- No tocar `GET /api/sync/catalogo` (pull de catálogo) — es la tarea 02
  (TE-06), sobre otra rama.
- No construir ninguna pantalla ni tocar `app.dart`/`main_*.dart` — esto es
  puro `nucleo/`, sin UI (HU-04/HU-05 vienen después, y la propia invariante
  10 exige esta prueba **antes** de esa UI).
- No reabrir ADR 0002 (paquete `decimal`): esta tarea no agrega ninguna
  columna decimal nueva, `ColaSync.payload` sigue siendo JSON en texto.
- No implementar temporizadores, triggers de conectividad ni reintentos con
  backoff — `sincronizar()` solo corre el ciclo cuando alguien lo llama; quién
  y cuándo lo dispara es responsabilidad de otra pieza, fuera de esta tarea.
- No dejar la prueba de replay como test "pendiente"/`skip` para pasar
  `bin/verify` más rápido — es exactamente lo que la invariante 10 prohíbe.

## Criterio de aceptación

`./bin/verify` devuelve 0, y entre los tests corridos está la prueba de
replay descrita arriba (10 corridas en orden + desorden parcial, estado
final idéntico) — nómbrala de forma que se identifique fácil en el reporte
de `flutter test` (algo como `sync engine replay ...`).

## Cierre obligatorio de cada etapa

`runs/01.estado` con una sola palabra: `PARCIAL` si avanzó pero la HU sigue
abierta, `OK` recién cuando las tres piezas están completas y `bin/verify`
pasa, `BLOQUEADA` si aparece algo que de verdad no se puede resolver acá
(no debería pasar — el contrato ya está confirmado arriba).

`runs/01.md` con qué se hizo y qué falta, concreto, para que la etapa
siguiente no adivine.

Al cerrar con `OK`, `runs/01.pr.md`: título del PR en la primera línea,
cuerpo debajo.

## Commits

Agrupados por pieza coherente, en español, imperativo, explicando el
porqué: uno para el repositorio de outbox, uno para `SyncEngine` real, uno
para la prueba de replay, uno para el wiring de DI si no entra natural en
los anteriores. Sin trailer `Co-Authored-By`.
