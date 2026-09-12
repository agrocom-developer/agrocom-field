<!-- ciclo: critica=si turno-noche=1 rama=feature/cierre-trabajo etapas=3 descongela=tests -->

# Tarea 14 — HU-09: cerrar el trabajo con imagen del campo

## Qué hacer

El piloto cierra el TRABAJO (no la sesión — HU-05 ya cubre eso) con una
imagen del campo obligatoria: "sin captura no cierra". `TrabajoLocal`
(`lib/nucleo/db/tablas/trabajo_local.dart`) hoy declara explícitamente "sin
columnas de cierre ni columna de estado", a la espera exacta de esta HU.

Es tarea `critica=si`: agrega columnas a una tabla de `nucleo/db` con datos
reales (lista de "qué no delegar sin revisión línea por línea" de
`CLAUDE.md`). Se integra igual, anotala en `runs/revision-pendiente.txt`.

Cargá `verificacion` siempre, `protocolo-sync`, `flujo-git-pr` antes de
rama/commit/PR.

### Recorte de alcance — leé esto antes de tocar código

El título de esta HU en `docs/gestion/plan_sprints.md` dice "cerrar el
trabajo con captura del RC + imagen del campo". **Verificado línea por
línea contra el contrato real de `agrocom-api`** (`CierreTrabajo.php` y
`CierreSesion.php` en `app/Dominios/Operaciones/Contratos/`, más
`RegistroSync` de `docs/api/openapi.yaml`): el DTO `CierreTrabajo` **solo**
exige `evidencia_imagen_campo_uuid_cliente` (evidencia tipo
`imagen_campo`). No existe ningún campo de `captura_rc` en `CierreTrabajo`
ni en `CierreSesion` — grep en `app/` de `agrocom-api` sin resultados fuera
del enum general de tipos de evidencia. El modelo de datos (espec §4.3)
menciona `sesiones.captura_rc_id`, pero no está enganchado a ningún DTO
real todavía: es deuda del lado servidor, no de esta app.

**Implementá solo lo que el contrato real exige: una imagen de campo
obligatoria al cerrar el trabajo.** No agregues un segundo campo o una
segunda evidencia de `captura_rc` — no hay contra qué mandarlo, y si el
servidor lo agrega en el futuro es una tarea aparte del lado de ese
contrato.

### El contrato exacto de `cierre_trabajo`

Mutación de la fila existente de `TrabajoLocal`, no una fila nueva — mismo
patrón que `cierre_sesion` en `SesionRepository.cerrarSesion`:

- `uuid_cliente`: del EVENTO de cierre (nuevo, generado en el dispositivo)
  — distinto del `uuid_cliente` de apertura del trabajo que referencia.
- `trabajo_uuid_cliente`: el de apertura.
- `fin`: momento de cierre.
- `litros_sobrante`: opcional, DECIMAL como string (espec §7.2).
- `evidencia_imagen_campo_uuid_cliente`: **REQUERIDO** — `uuid_cliente` de
  una evidencia ya subida vía `POST /api/evidencias` con `tipo:
  imagen_campo`.

**Sin campo de hectáreas acá** — `trabajos.hectareas_declaradas` es
derivado (suma de sesiones), nunca algo que el dispositivo declare al
cerrar (mismo hallazgo ya documentado en `CierreTrabajo.php` del lado
servidor).

### Piezas a construir

1. **Migración `drift`**: agregá columnas a `TrabajoLocal` con
   `m.addColumn` (ALTER TABLE — **no recrees la tabla**, ya tiene filas
   reales en dispositivos con el esquema actual): `estado`
   (`textEnum<EstadoTrabajoLocal>`: `abierto`/`cerrado`, vocabulario LOCAL,
   default `abierto` — mismo criterio que `SesionLocal.estado`), `fin`
   (`DateTime` nullable), `litrosSobrante` (`Decimal` nullable, vía
   `DecimalDriftConverter`), `evidenciaImagenCampoUuidCliente` (`text`
   nullable), `uuidClienteCierre` (`text` nullable, único — el uuid del
   EVENTO de cierre, mismo patrón que `SesionLocal.uuidClienteCierre`).
   Subí `schemaVersion` (leé el valor real en `database.dart` al empezar —
   no asumas el número; si la tarea 13/HU-08 ya se integró, ya subió una
   versión). Test `test/nucleo/db/migracion_cierre_trabajo_test.dart`,
   mismo patrón que las anteriores: `onCreate` + migración real con
   `addColumn` sobre datos preexistentes de `TrabajoLocal`, verificando que
   las filas existentes quedan con `estado=abierto` y el resto de columnas
   nuevas nulas, sin perder `ordenId`/`loteId`/`nroAplicacion`/etc.
2. **`TrabajoRepository.cerrarTrabajo({trabajoUuidCliente, fin,
   litrosSobrante, evidenciaImagenCampoUuidCliente})`** — mismo patrón que
   `SesionRepository.cerrarSesion`: update de la MISMA fila + insert en
   `ColaSync` (`tipoEntidad: 'cierre_trabajo'`) en una transacción. Rechazá
   ANTES de escribir nada si falta `evidenciaImagenCampoUuidCliente` (forma
   "string no vacío", mismo criterio que el DTO del servidor).
3. **UI**: la captura de la foto (`EvidenciaRepository.capturarEvidencia`
   con `tipo: 'imagen_campo'`) va en la capa de presentación/bloc, ANTES de
   llamar a `cerrarTrabajo` — el repositorio recibe el `uuid_cliente` de la
   evidencia ya persistida. Si la tarea 13 (HU-08) ya integró
   `image_picker`/`EvidenciaRepository` en DI, reusalos; si no, replicá el
   mismo llamado directo. Agregá la acción "cerrar trabajo" al flujo de
   `sesion_vuelo` — `orden_detalle_pantalla.dart:46-53` ya provee
   `TrabajoCubit` en el árbol sobre `SesionVueloPantalla`, así que
   `context.read<TrabajoCubit>()` sigue disponible ahí. Extendé
   `TrabajoCubit` con un método `cerrar(...)` y su estado (mismo patrón que
   `TrabajoEstado` ya tiene para abrir), o un bloc nuevo si el flujo de
   confirmación lo justifica — a tu criterio.

## Cómo repartir las etapas

- Etapa 1: migración (crítica) + test.
- Etapa 2: `TrabajoRepository.cerrarTrabajo` + tests (incluido: rechazo sin
  evidencia, ANTES de escribir).
- Etapa 3: UI + wiring + tests.

## Qué NO hacer

- No agregues un campo o columna de `captura_rc` — no está en el contrato
  real (ver "Recorte de alcance" arriba).
- No recrees `TrabajoLocal` en la migración — es un `addColumn` sobre una
  tabla con filas reales.
- No dupliques la integración con `EvidenciaRepository` si la tarea 13 ya
  la dejó armada en DI.
- No agregues un campo de hectáreas al cierre de trabajo — es derivado, ya
  resuelto del lado servidor.

## Criterio de aceptación

```
./bin/verify
```
Exit code 0. Test de migración sin pérdida de filas de `TrabajoLocal`
preexistentes, test de `TrabajoRepository.cerrarTrabajo` que rechaza sin
evidencia, test de UI/bloc del cierre.

## Cierre obligatorio de cada etapa

`runs/14.estado`, `runs/14.md` al final de cada sesión. `runs/14.pr.md`
solo al cerrar con `OK`.

## Commits

migración, repositorio, UI+bloc. Español, imperativo, el porqué antes que
el qué. Sin trailer `Co-Authored-By`.
