<!-- ciclo: critica=si turno-noche=1 rama=feature/cola-evidencias etapas=4 descongela=tests -->

# Tarea 12 — TE-07: cola de evidencias

## Qué hacer

Infraestructura habilitante para HU-08 (incidencia con foto) y HU-09
(cerrar trabajo con captura del RC): comprimir una imagen a <300 KB
(invariante 8 de `CLAUDE.md`), calcularle un hash SHA-256, encolarla
separada de los registros livianos (`ColaSync` no la toca), y subirla a
`POST /api/evidencias` con reintentos — sin esperar señal para que el
dispositivo siga capturando.

**Nada en `lib/` consume esto todavía.** No hay pantalla de cámara, no hay
HU-08/HU-09 construidas — esta tarea entrega el motor solo, testeado con
bytes de imagen sintéticos en memoria. Es infraestructura pura, mismo
espíritu que TE-05 (motor de sync) y TE-06 (pull de catálogo) cuando se
integraron antes de que ninguna pantalla las usara.

Es tarea `critica=si`: agrega una tabla nueva a `nucleo/db` — lista de "qué
no delegar sin revisión línea por línea" de `CLAUDE.md`. Se implementa e
integra igual, anotala en `runs/revision-pendiente.txt`.

Cargá `verificacion` siempre, `protocolo-sync` antes de tocar el esquema
`drift` (aunque esta cola es distinta del outbox de `ColaSync`, comparte el
mismo principio de idempotencia y orden), y `flujo-git-pr` antes de
rama/commits/PR.

### El contrato de `POST /api/evidencias` — distinto de `POST /api/sync`

`/Applications/MAMP/htdocs/agrocom-api/docs/api/openapi.yaml`, path
`/api/evidencias` (líneas ~216-291). Diferencias clave respecto al motor de
sync que ya existe en este repo:

- **multipart/form-data**, no JSON. Campos: `uuid_cliente` (obligatorio,
  generado en el dispositivo, invariante 2), `tipo` (enum:
  `captura_rc`/`imagen_campo`/`foto_incidencia`/`comprobante`/
  `firma_acta`), `fecha` (ISO 8601), `hash_dispositivo` (opcional — SHA-256
  calculado en el dispositivo, el servidor lo recalcula igual y rechaza si
  no coincide), `archivo` (binario).
- **Un POST por evidencia**, no un lote — a diferencia de `/api/sync`, que
  recibe un array de `registros`, este endpoint sube de a una. El motor de
  subida itera las filas `pendiente` de la cola y hace un request por
  cada una.
- Respuesta: `{uuid_cliente, estado: aplicado|duplicado|rechazado, motivo?}`
  — mismo vocabulario que sync (`duplicado` se trata como éxito, invariante
  ya aplicada en `OutboxRepository.marcarConfirmado`), pero sin lote.
- `ApiClient.post` (`lib/nucleo/api/api_client.dart`) ya acepta
  `Object? data` pasado directo a `dio.post` — un `FormData` con
  `MultipartFile` funciona sin tocar esa clase; Dio detecta el
  `Content-Type` solo. No modifiques `ApiClient` salvo que encuentres una
  razón concreta al implementar.

### Paquetes — uno ya está, evaluá el otro

`flutter_image_compress: ^2.5.1` **ya está declarado en `pubspec.yaml`**
pero ningún archivo lo usa todavía (parece que se agregó preventivamente
en TE-01). Confirmá que sigue siendo la versión más alta compatible con el
SDK instalado en esta máquina antes de asumirlo — mismo chequeo que hizo la
tarea 09 con `torch_light` (`flutter pub add` resuelve solo, documentá en
`runs/12.md` qué versión terminó resolviendo si difiere de la declarada).
Para el hash, agregá `crypto` (paquete del propio equipo de Dart, `sha256`
sobre los bytes ya comprimidos) — no hace falta evaluarlo como a un plugin
nativo, es Dart puro.

## Piezas a construir

Carpeta nueva `lib/nucleo/evidencias/` (ya prevista en el árbol de
`docs/vision.md`).

1. **Esquema `drift`** (delegá a `modelo-datos-flutter`, revisá línea por
   línea): tabla `EvidenciaLocal` — PK `uuidCliente` (generado en el
   dispositivo), `tipo` (texto plano, no `textEnum` — mismo criterio que
   `SesionLocal.motivoCierre`, catálogo cerrado del servidor),
   `rutaArchivoLocal` (texto — dónde quedó el archivo comprimido en disco;
   no guardes el binario en una columna `drift`), `hashSha256` (texto),
   `fecha` (`DateTime`), `estado` (`textEnum`: `pendiente`/`subido`/
   `rechazado` — vocabulario LOCAL de esta cola, no confundir con
   `EstadoSync` de `ColaSync`, son colas separadas por invariante 8),
   `motivoRechazo` (texto, nullable). `schemaVersion` sube 1 respecto de lo
   que esté vigente al momento de implementar esta tarea (confirmalo en
   `lib/nucleo/db/database.dart` — depende de si las tareas 10/11 ya
   subieron la versión antes que esta), con su test de migración real.
2. **Compresión** (`nucleo/evidencias/compresor_evidencia.dart` o similar):
   recibe bytes de imagen sin comprimir, devuelve bytes comprimidos con
   `flutter_image_compress` apuntando a <300 KB. Test: mockeá el
   `MethodChannel` del plugin, mismo patrón ya usado en este repo para
   plugins nativos (`test/nucleo/linterna/linterna_controlador_test.dart`,
   `notificador_local_plugin_test.dart`) — no dependas de compresión real
   de imagen en el test, valida que se invoque con los parámetros
   correctos y que el resultado se persista.
3. **Hash**: función pura `sha256` sobre bytes (paquete `crypto`), sin
   mock necesario — Dart puro, test directo.
4. **`EvidenciaRepository`**: inserta una evidencia nueva (recibe bytes ya
   capturados por quien la llame — no hay UI de cámara en esta tarea),
   corre compresión + hash, persiste el archivo comprimido en el
   filesystem local (`path_provider` si hace falta explorar dónde
   guardarlo — evalualo igual que cualquier paquete nuevo) y encola la fila
   `EvidenciaLocal` en estado `pendiente`, todo en una operación coherente
   (invariante 3: la app no espera red para confirmar que la evidencia
   "quedó guardada" localmente).
5. **`EvidenciaSyncEngine`**: lee pendientes, por cada una arma el
   `FormData` con el contrato de arriba y hace `POST /api/evidencias`;
   `aplicado`/`duplicado` → marca `subido`; `rechazado` → marca `rechazado`
   con motivo; error de red → deja `pendiente` para el próximo ciclo (mismo
   criterio que `SyncEngine.sincronizar`, pero sin lote — un fallo de una
   evidencia no debe frenar la subida de las demás pendientes en el mismo
   ciclo).

## Cómo repartir las etapas

- Etapa 1 (crítica — revisar línea por línea): esquema `drift` +
  migración + su test.
- Etapa 2: compresión + hash, con tests (mock de `MethodChannel` para la
  compresión, test directo para el hash).
- Etapa 3: `EvidenciaRepository` (captura → comprime → hashea → persiste
  archivo → encola) con tests contra `drift` en memoria y un
  filesystem/directorio temporal de test.
- Etapa 4: `EvidenciaSyncEngine` con tests contra un `ApiClient` mockeado —
  casos: `aplicado`, `duplicado` (se trata igual que éxito), `rechazado`
  con motivo persistido, error de red deja `pendiente`, y el caso
  "reenviar el mismo lote de pendientes dos veces dejando el estado final
  idéntico" (mismo espíritu que la prueba de replay de TE-05, adaptado a
  esta cola — no hace falta que sea literalmente el mismo test, sí que
  cubra la misma garantía de idempotencia). Documentar en `runs/12.md` que
  ninguna pantalla consume esto todavía — queda para HU-08/HU-09.

## Qué NO hacer

- No construyas pantalla de cámara ni selector de imagen — esta tarea
  recibe bytes ya capturados por quien la llame en una tarea futura.
- No mezcles esta cola con `ColaSync`/`OutboxRepository`/`SyncEngine` — son
  dos colas separadas por diseño (invariante 8), no una tabla compartida
  con un discriminador.
- No inventes compresión de video ni de otros formatos — el objetivo es
  imagen, <300 KB, nada más.
- No agregues lógica de compresión progresiva ni reintento de calidad
  variable si el primer intento no llega a 300 KB — usá la configuración
  de calidad que ofrezca `flutter_image_compress` de forma directa;
  ajustes finos de calidad son afinamiento posterior, no bloqueante para
  esta tarea.

## Criterio de aceptación

`./bin/verify` devuelve 0, con la cobertura de tests descrita arriba.

## Cierre obligatorio de cada etapa

`runs/12.estado`: `PARCIAL`/`OK`/`BLOQUEADA`.

`runs/12.md`: qué se hizo y qué falta, concreto — en particular, dejá
explícito que esta cola queda sin ningún consumidor hasta HU-08/HU-09.

Al cerrar con `OK`, `runs/12.pr.md`: título en la primera línea, cuerpo
debajo.

## Commits

Agrupados por pieza coherente, español, imperativo, el porqué antes que el
qué: esquema `drift` + migración, compresión + hash, repositorio, motor de
subida. Sin trailer `Co-Authored-By`.
