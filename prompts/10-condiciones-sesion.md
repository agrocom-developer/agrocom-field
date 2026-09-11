<!-- ciclo: critica=si turno-noche=1 rama=feature/condiciones-sesion etapas=3 descongela=tests -->

# Tarea 10 — HU-06: condiciones al abrir sesión

## Qué hacer

Antes de abrir una sesión de vuelo, el piloto registra viento/temperatura/
humedad. Si algo cae fuera de rango, la app exige una observación del
agrónomo con su firma (texto, sin captura gráfica todavía) antes de dejar
seguir — sin eso, el servidor rechaza el registro igual, pero no tiene
sentido dejar que el piloto llegue hasta ahí para enterarse recién con
señal.

Es tarea `critica=si`: agrega una tabla nueva a `nucleo/db` (lista de "qué
no delegar sin revisión línea por línea" de `CLAUDE.md`). Se implementa e
integra igual — anotala en `runs/revision-pendiente.txt`, no la conviertas
en borrador ni la retengas por eso.

Cargá `verificacion` siempre, `protocolo-sync` antes de tocar el esquema
`drift`/outbox, y `flujo-git-pr` antes de rama/commits/PR.

### El contrato real — no uses el resumen de `docs/vision.md` para esto

`docs/vision.md` describe el registro de condiciones como parte de "abrir
el trabajo" (paso 2 del flujo). **Es un resumen narrativo, no el contrato**:
el campo real en `RegistroSync` (`docs/api/openapi.yaml` en
`/Applications/MAMP/htdocs/agrocom-api`) es `sesion_uuid_cliente`, y
`momento` solo acepta `inicio_sesion` — condiciones se ata a la APERTURA DE
SESIÓN, no a la apertura de trabajo. Motivo real: un trabajo puede tener
varias sesiones por relevo, y el viento/temperatura/humedad cambian entre
una y la siguiente — cada sesión mide las suyas. Tomá `openapi.yaml` como
fuente, no la prosa de `vision.md`.

Campos exactos de `RegistroSync` para `tipo: "condiciones"` (líneas ~1338-
1366 de ese archivo):

- `sesion_uuid_cliente` (string, obligatorio): `uuid_cliente` de la sesión
  que se está abriendo — el mismo que generás para `AperturaSesion` en la
  misma operación.
- `momento` (string, enum con un solo valor hoy: `inicio_sesion`).
- `viento_kmh`, `temperatura_c`, `humedad_pct` (decimal-string, invariante
  9 de `CLAUDE.md` — nunca `double`).
- `observacion_agronomo` (string, nullable): **obligatoria junto con
  `firma_observacion`** cuando alguna medición cae fuera de rango —
  `viento_kmh > 17`, `temperatura_c > 30` o `humedad_pct > 90`. Sin ambas
  presentes en ese caso, el servidor rechaza el registro completo.
- `firma_observacion` (string, nullable): **texto plano** — la descripción
  del propio contrato dice explícito "sin evidencia real todavía (TE-07)".
  No es una firma gráfica, no hay pantalla de captura de firma acá. TE-07
  (evidencias con imagen) es una tarea aparte, todavía sin construir.

No hay campo `autorizado` en el `RegistroSync` — esa decisión la toma el
SERVIDOR a partir de los valores recibidos, no el dispositivo. La app no
calcula ni envía `autorizado`.

## Piezas a tocar

Todo dentro de `lib/features/sesion_vuelo/` (feature existente, HU-05 ya
integrada) y `lib/nucleo/db/`. No crear una feature nueva.

1. **Esquema `drift`** (delegá a `modelo-datos-flutter`, revisá línea por
   línea): tabla nueva `CondicionLocal` — PK `uuidCliente` (generado en el
   dispositivo, invariante 2), `sesionUuidCliente` (referencia lógica a
   `SesionLocal.uuidCliente`, sin FK física — mismo criterio ya usado entre
   `SesionLocal`/`TrabajoLocal`), `momento` (texto plano, no `textEnum` —
   mismo criterio que `SesionLocal.motivoCierre`: el catálogo lo posee el
   servidor), `vientoKmh`/`temperaturaC`/`humedadPct` (`Decimal`, mismo
   converter que ya usa `SesionLocal.hectareasDeclaradas`),
   `observacionAgronomo`/`firmaObservacion` (texto, nullable).
   `schemaVersion` 3 → 4 (confirmá el número vigente en
   `lib/nucleo/db/database.dart` al momento de implementar — puede haber
   subido si algo más se integró antes), `migrationStrategy` que no toque
   las tablas existentes, con su test de migración real (mismo patrón que
   `test/nucleo/db/migracion_trabajo_sesion_test.dart`).
2. **`domain/`** (`reglas_sesion.dart` o un archivo nuevo del mismo
   feature): función pura que decida "fuera de rango" con los tres
   umbrales exactos de arriba, y otra que verifique la precondición
   "si está fuera de rango, `observacionAgronomo` y `firmaObservacion` no
   pueden ser null/vacíos" — lanzá una excepción de dominio sellada (mismo
   patrón que `TrabajoInexistenteExcepcion`) si falla, ANTES de escribir
   nada. Validar esto en el dispositivo evita encolar un registro que el
   propio contrato ya garantiza que el servidor va a rechazar.
3. **`data/`**: `SesionRepository.abrirSesion` gana los parámetros nuevos
   (`vientoKmh`, `temperaturaC`, `humedadPct`, `observacionAgronomo`?,
   `firmaObservacion`?, todos obligatorios salvo los dos últimos). En la
   MISMA transacción que ya inserta `SesionLocal` + encola `sesion`:
   validar con las reglas del punto 2, insertar la fila `CondicionLocal`,
   y encolar en `ColaSync` un registro `tipoEntidad: 'condiciones'` con
   `sesion_uuid_cliente` = el `uuidCliente` de la sesión recién generado.
   Mirá `_proximaSecuenciaGlobal` — el registro de condiciones necesita su
   propio número de secuencia global, después del de `sesion` (orden
   causal, invariante 5).
4. **`presentation/`**: `SesionAbrirSolicitada` (`sesion_evento.dart`) gana
   los campos nuevos. `sesion_vuelo_vista.dart` — hoy el botón "Abrir
   sesión" despacha el evento directo (línea ~51-53); reemplazalo por un
   formulario modal (mismo patrón que `_mostrarFormularioCierre`, con
   `Form`/`GlobalKey<FormState>`) con viento/temperatura/humedad, y los
   campos de observación/firma que aparecen recién cuando el propio
   formulario detecta que algún valor ingresado está fuera de rango
   (`setState` al cambiar, misma idea que el resto del formulario).
   `SesionBloc._alAbrirSolicitada` pasa los campos nuevos a
   `sesionRepositorio.abrirSesion` y traduce la excepción de dominio del
   punto 2 a un `SesionError` legible.

## Cómo repartir las etapas

- Etapa 1 (crítica — revisar línea por línea): esquema `drift` + migración
  + su test, y las reglas de dominio (rango + precondición) con tests
  puros, sin `drift`.
- Etapa 2: `SesionRepository.abrirSesion` extendido, con tests contra una
  base `drift` en memoria — casos: dentro de rango sin observación inserta
  igual; fuera de rango sin observación/firma lanza la excepción ANTES de
  escribir (verificar que ni `SesionLocal` ni `CondicionLocal` ni
  `ColaSync` tengan filas nuevas); fuera de rango con ambas presentes
  inserta las tres filas correctas, con el payload de `condiciones` exacto
  contra el contrato.
- Etapa 3: `presentation/` (evento, bloc, formulario) con tests de bloc y
  de widget — incluido el caso "el campo de observación aparece solo
  cuando corresponde" — y test de integración que encadena el flujo
  completo. Documentar en `runs/10.md` qué falta (nada si HU-06 queda
  entera).

## Qué NO hacer

- No construir captura de firma gráfica ni ninguna pieza de evidencias —
  `firma_observacion` es texto plano por contrato explícito, hasta TE-07.
- No agregar `momento` como opción configurable — hoy solo existe
  `inicio_sesion`; no inventes soporte para condiciones-en-incidencia (el
  propio contrato lo excluye de este catálogo).
- No tocar `SyncEngine`/`OutboxRepository` — son genéricos por
  `tipoEntidad`/payload, `condiciones` encola igual que cualquier otro tipo
  sin tocar ese código.
- No calcular ni enviar un campo `autorizado` — es decisión exclusiva del
  servidor.
- No perder la referencia a `docs/vision.md` como versión desactualizada
  en este punto: si alguna vez se actualiza ese documento con esta HU,
  usá el criterio de `openapi.yaml` como el que manda.

## Criterio de aceptación

`./bin/verify` devuelve 0, con la cobertura de tests descrita arriba —
migración de esquema, reglas de rango, repositorio con los tres casos, y
presentación con el formulario condicional.

## Cierre obligatorio de cada etapa

`runs/10.estado`: `PARCIAL`/`OK`/`BLOQUEADA`.

`runs/10.md`: qué se hizo y qué falta, concreto.

Al cerrar con `OK`, `runs/10.pr.md`: título en la primera línea, cuerpo
debajo.

## Commits

Agrupados por pieza coherente, español, imperativo, el porqué antes que el
qué: esquema `drift` + migración, reglas de dominio, repositorio, evento +
bloc + formulario. Sin trailer `Co-Authored-By`.
