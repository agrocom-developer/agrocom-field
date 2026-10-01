<!-- ciclo: critica=si turno-noche=1 rama=feature/limpia-limites-orden etapas=3 descongela=tests -->

# Tarea 25 — limpieza de `orden_catalogo` y relectura de límites (v13)

## Qué hacer

`orden_catalogo` conserva las 8 columnas de clima y vuelo que el servidor ya
no manda en `ordenes[]`:

- `humedad_min_pct`
- `viento_max_kmh`
- `temperatura_max_c`
- `humedad_max_pct`
- `velocidad_max_kmh`
- `altura_vuelo_m`
- `velocidad_vuelo_kmh`
- `ancho_pasada_m`

La tarea 23 dejó su borrado para cuando nada las leyera. Desde la tarea 24 los
límites salen de `trabajo_catalogo`.

Además, los dispositivos con trabajos ya bajados tienen esos límites en `null`
o viejos: `agrocom-api` #309 empezó a mandarlos resueltos sin cambiar
`updated_at`, así que el pull incremental nunca los vuelve a traer.

Cargá `verificacion`, `protocolo-sync` y `flujo-git-pr`.

Fuente: el código y el `openapi.yaml` de `agrocom-api` develop @ `a47e5280`
(solo lectura).

Pasos:

1. **Migración v13.** Quitá esas 8 columnas de `orden_catalogo` conservando
   las filas, con `TableMigration`/`alterTable` de drift: no recrees la tabla
   vaciándola. Reseteá el cursor. Prueba v12→v13 con filas reales en todas las
   tablas; la de replay sigue en verde.
2. **Dominio.** Quitá `velocidadMaxKmh` de `OrdenVigente` y la fila «Velocidad
   máxima» del detalle de orden: ya no existe en la orden de trabajo.
3. **Contrato.** Alineá el fixture y el test de contrato con `openapi.yaml`:
   - sin campos de clima/vuelo en `ordenes[]`;
   - `viento_max_kmh`, `temperatura_max_c` y `humedad_max_pct` siempre presentes en `trabajos[]`.

   El parseo puede seguir tolerando `null`, porque las columnas siguen nullable.
4. **Petición.** Actualizá
   `docs/gestion/peticiones_agrocom_api/2026-10-01-trabajo-asignado-en-catalogo.md`
   con las respuestas (#309-#312, SHA) y marcá lo resuelto. La pregunta 3
   (retiro) queda pendiente de la decisión A/B del dueño.

## Cómo repartir las etapas

- Etapa 1: migración v13 con su prueba.
- Etapa 2: dominio, detalle, parser, fixture y contrato.
- Etapa 3: documento de la petición y cierre.

## Qué NO hacer

- No reescribas migraciones anteriores.
- No toques la regla de condiciones (tarea 24).
- No edites nada de `agrocom-api`.
- No pongas `double` en ningún decimal (invariante 9).

## Criterio de aceptación

- `./bin/verify` devuelve 0.
- La prueba v12→v13 conserva las filas de todas las tablas, `orden_catalogo` queda sin las 8 columnas y el cursor queda reseteado.
- El fixture coincide con `openapi.yaml` de `a47e5280`.
- El detalle de orden no muestra «Velocidad máxima».

## Cierre obligatorio de cada etapa

- `runs/25.estado`: `PARCIAL`, `OK` o `BLOQUEADA`.
- `runs/25.md`: qué se hizo y qué falta.
- Al cerrar con `OK`, `runs/25.pr.md`, con el título en la primera línea.

## Commits

Uno por pieza: migración, dominio y contrato, documento. En español, imperativo, con el porqué. Sin `Co-Authored-By`.
