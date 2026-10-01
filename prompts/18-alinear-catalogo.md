<!-- ciclo: critica=si turno-noche=1 rama=feature/alinear-catalogo etapas=3 descongela=tests -->

# Tarea 18 — TE-23: alinear `OrdenCatalogo`/`TrabajoCatalogo` con el contrato actual

## Qué hacer

Contrastar, campo por campo, `GET /api/sync/catalogo` del `openapi.yaml`
actual contra las tablas `drift` del catálogo, y quitar o ajustar lo que ya no
tenga fuente. Por qué: `agrocom-api` replanteó la Orden de Trabajo entre el
15 y el 23/9/2026 (ADR 0022 y PR #251/#269/#270) y una tabla con columnas sin
fuente miente sobre lo que la app sabe.

Cargá `verificacion`, `protocolo-sync` (toca `nucleo/db` y el pull) y
`flujo-git-pr`.

Fuente: `/Applications/MAMP/htdocs/agrocom-api/docs/api/openapi.yaml`, esquemas
`OrdenCatalogo`, `LoteDeOrdenCatalogo`, `TrabajoCatalogo`, `LoteCatalogo`,
`PersonaCatalogo` y la respuesta de `/api/sync/catalogo` (solo lectura).

Pasos:

1. **Tabla de contraste** en `runs/18.md`: una fila por campo del contrato y
   por columna de `OrdenCatalogo`, `LoteCatalogo`, `PersonaCatalogo`
   (`lib/nucleo/db/tablas/`). Marcá: coincide / columna sin fuente / campo del
   contrato sin columna. Hoy `velocidad_max_kmh` sigue en el contrato como
   `required`; confirmá su estado real leyendo el esquema, no esta frase.
2. **Ajustes de esquema.** Solo lo que la tabla marque. Una **única**
   migración v9→v10 (regla de `CLAUDE.md`: nunca perder filas locales; mismo
   patrón que `migracion_propiedad_test.dart`, con fixture del esquema v9
   escrita a mano). Si la tabla no marca ninguna diferencia de esquema, no
   subas la versión y documentá por qué.
3. **`lotes[]` de la orden.** Hoy el pull toma `lotes.first` (simplificación
   de TE-20). ADR 0022 dice que `lotes` es la copia de **todos** los lotes del
   contrato. Verificá que `OrdenVigente`/`OrdenesRepository` y el detalle no
   muestren datos falsos con más de un lote (p. ej. hectáreas de un solo lote
   como si fueran las de la orden). Si hay un dato engañoso, corregilo con el
   cambio mínimo; **no** construyas soporte multi-lote de UI (es HU aparte).
4. **`TrabajoCatalogo`.** Solo contrastá; la tabla y el upsert de `trabajos`
   son de HU-70 (tarea 19). No los crees acá. Anotá en `runs/18.md` qué
   campos del contrato tendrá que cubrir esa tabla (en particular que
   `hectareas_declaradas` es ahora por equipo).
5. **Test de contrato.** Un fixture JSON en `test/` copiado de una respuesta
   real de `/api/sync/catalogo` según el `openapi.yaml` (órdenes con
   `lotes[]` de varios lotes, una con `litros_ha: null` y otra con
   `kilos_por_vuelo: null`, un `trabajos[]` con un elemento) que
   `CatalogoRepository.pull()` parsea sin excepción y deja las filas
   esperadas. Un test que además **falle** ante una columna de tabla sin
   fuente en el fixture no es necesario; alcanza con el contraste del punto 1.

## Cómo repartir las etapas

Etapa 1: tabla de contraste + decisión de esquema. Etapa 2: migración y
ajustes de parser/dominio con sus tests de migración. Etapa 3: test de
contrato con fixture y cierre.

## Qué NO hacer

- No crees tabla ni upsert de `trabajos` (HU-70).
- No toques el modelo de estados de la orden ni el retiro de órdenes
  pausadas/canceladas (TE-22, bloqueada por contrato).
- No agregues UI multi-lote ni cambies pantallas más allá del punto 3.
- No pongas `double` en ningún decimal (invariante 9): `Decimal`.
- No edites `openapi.yaml` ni nada de `agrocom-api`.
- No reescribas migraciones anteriores.

## Criterio de aceptación

`./bin/verify` devuelve 0. El test de contrato parsea el fixture sin
excepción. Si hubo migración: su test v9→v10 pasa y conserva filas de
`orden_catalogo`. Cada columna del catálogo tiene fuente en el contrato, o
queda anotada en `runs/18.md` con el motivo de conservarla.

## Cierre obligatorio de cada etapa

`runs/18.estado` (`PARCIAL`/`OK`/`BLOQUEADA`), `runs/18.md` con qué se hizo y
qué falta, y al cerrar con `OK`, `runs/18.pr.md` (título en la primera línea).

## Commits

Por pieza (tabla/decisión, esquema+migración, parser/dominio, test de
contrato), en español, imperativo, con el porqué. Sin `Co-Authored-By`.
