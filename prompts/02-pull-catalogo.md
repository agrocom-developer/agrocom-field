<!-- ciclo: critica=si turno-noche=1 rama=feature/pull-catalogo etapas=3 descongela=tests -->

# Tarea 02 — TE-06: pull de catálogo con cursor (lado app)

## Qué hacer

Completar el lado app de TE-06: consumir `GET /api/sync/catalogo` (pull con
cursor de órdenes vigentes, lotes y personas) y persistirlo en `drift`, para
que HU-04 (ver órdenes vigentes offline) tenga de dónde leer después. Esta
tarea asume la 01 (TE-05, motor de sync push) ya integrada en `develop` —
no dependas de su rama, arrancá desde `develop` actualizado.

Cargá los skills `verificacion` y `protocolo-sync` antes de escribir código,
y `flujo-git-pr` antes de rama/commits/PR. Es `critica=si`: toca
`lib/nucleo/db/` (esquema `drift`), que está en la lista de "qué no delegar
sin revisión línea por línea" de `CLAUDE.md` — se integra igual, queda
anotada para revisión posterior.

Contrato de referencia: `GET /api/sync/catalogo` en
`/Applications/MAMP/htdocs/agrocom-api/docs/api/openapi.yaml` (operationId
`obtenerCatalogoSincronizacion`, esquemas `OrdenCatalogo`/`LoteCatalogo`/
`PersonaCatalogo`). Recordá la nota de `docs/vision.md`: recetas/productos
**no se modelan** (CR-01) — el catálogo de esta tarea es solo órdenes, lotes
y personas.

Piezas a construir:

1. **Tablas `drift` nuevas** en `lib/nucleo/db/tablas/` (una por entidad de
   catálogo: orden, lote, persona), con PK el `id` de servidor (son datos de
   solo lectura que el dispositivo nunca crea — no llevan `uuid_cliente`).
   Sumalas a `@DriftDatabase(tables: [...])` en `lib/nucleo/db/database.dart`
   y subí `schemaVersion` a `2` con su migración (`onUpgrade`) — nunca
   reescribas la migración de `schemaVersion: 1` que ya corrió en
   dispositivos reales.
   - `hectareas` (lote) y `litros_ha` + los límites climáticos/de vuelo
     (orden) viajan como string decimal en el contrato. Esta es la primera
     columna decimal de negocio del esquema: seguí ADR 0002 de este repo y
     creá el `TypeConverter<Decimal, String>` que la decisión ya anticipa
     (mismo patrón que `lib/nucleo/tipos/decimal_json_converter.dart`, pero
     para columnas `drift` en vez de JSON) — no reinventes otra
     representación (ni `double`, ni string sin convertir).
   - `geometria` (lote) es GeoJSON u objeto/`null` — guardalo como texto
     (JSON serializado); no hace falta modelarlo estructurado todavía, nadie
     lo consume aún (HU-61, mapa, es tarea futura).
2. **Repositorio de catálogo** en `lib/nucleo/catalogo/` (carpeta nueva,
   nombrada así en `docs/vision.md`, sección "Arquitectura Flutter"):
   - Persiste el cursor devuelto por el pull (necesita sobrevivir un reinicio
     de la app — no es preferencia de UI, así que no es lugar de
     `nucleo/preferencias`/TE-16; guardalo en `drift`, p. ej. una tabla
     mínima de una sola fila).
   - Llama `GET /api/sync/catalogo?desde={cursor}` (cursor vacío/ausente en
     la primera sincronización, tal como dice el contrato).
   - Upsert de los tres arreglos recibidos por `id` de servidor
     (`insertOnConflictUpdate` o equivalente de `drift`) — nunca duplica
     filas en pulls sucesivos.
   - Guarda el cursor de continuación recién después de aplicar el upsert
     completo (si el upsert falla a mitad de camino, el cursor viejo se
     reintenta en el próximo pull — no lo avances antes de tiempo).
3. Registrar el repositorio de catálogo en
   `lib/nucleo/di/service_locator.dart`.

## Cómo repartir las etapas

- Etapa 1: tablas `drift` nuevas + `TypeConverter<Decimal, String>` +
  migración `schemaVersion` 1 → 2, con tests de la migración.
- Etapa 2: repositorio de catálogo (pull + upsert + cursor) contra
  `ApiClient` mockeado.
- Etapa 3: test de idempotencia del pull (correr el mismo pull dos veces con
  el mismo cursor y verificar que no duplica filas; correr pulls sucesivos
  con cursores distintos y verificar que el estado acumulado es el
  esperado) + wiring de DI.

## Qué NO hacer

- No modelar `recetas_mezcla`/`receta_items` ni ningún campo de fórmula/dosis
  — CR-01 ya los descartó (ver `docs/vision.md`, "Lo que hoy contradice la
  especificación entre sí").
- No construir la pantalla de "ver órdenes vigentes" — es HU-04, tarea
  aparte, sobre otra rama.
- No tocar `lib/nucleo/sync/sync_engine.dart` (push) salvo que necesites
  reutilizar `ApiClient` — es la tarea 01, ya integrada.
- No inventes un mecanismo de sincronización periódica (polling con timer):
  igual que el motor de push, el repositorio de catálogo solo expone el
  método de pull; quién y cuándo lo dispara es otra pieza, fuera de alcance.

## Criterio de aceptación

`./bin/verify` devuelve 0, incluyendo el test de idempotencia del pull
descrito arriba.

## Cierre obligatorio de cada etapa

`runs/02.estado` con una sola palabra (`PARCIAL`/`OK`/`BLOQUEADA`).
`runs/02.md` con qué se hizo y qué falta. Al cerrar con `OK`,
`runs/02.pr.md` con título en la primera línea y cuerpo debajo.

## Commits

Uno por pieza coherente: tablas + migración + converter decimal, repositorio
de catálogo, tests de idempotencia, wiring de DI si no entra natural en los
anteriores. Español, imperativo, explicando el porqué. Sin trailer
`Co-Authored-By`.
