---
name: protocolo-sync
description: Referencia técnica rápida del protocolo de sincronización offline-first que usa agrocom-field — outbox, idempotencia por uuid_cliente, orden causal, qué endpoint pega qué. Usar antes de tocar nucleo/sync, nucleo/db, o cualquier repositorio que escriba a drift/outbox.
---

# Protocolo de sincronización — agrocom-field

Fuente completa: `docs/especificacion/especificacion_funcional_tecnica.md` §2.1 en `agrocom-api` (ruta local `/Applications/MAMP/htdocs/agrocom-api`) — "el problema de mayor riesgo del proyecto". Esto es la referencia operativa rápida, no el reemplazo.

## Las piezas

- **`drift`** (SQLite local): toda escritura va acá primero. La UI lee siempre de acá, nunca de la red.
- **`cola_sync`** (outbox): una fila por escritura pendiente. Columnas mínimas: `uuid_cliente`, tipo de entidad, payload, `secuencia`, estado.
- **Estados de la cola**: `pendiente → enviado → confirmado | rechazado`. Un `rechazado` no se reintenta solo — necesita que alguien (jefe de campo, o una pantalla de conflictos) lo revise.

## El push

`POST /api/sync` recibe un arreglo ordenado causalmente (trabajo antes que sesión, sesión antes que recarga — el orden lo da `secuencia`, no el reloj del dispositivo). El servidor procesa **registro por registro en transacciones individuales**, nunca el lote entero en una transacción, y devuelve por cada uno:

| Respuesta | Qué significa | Qué hace el cliente |
|---|---|---|
| `aplicado` | Se creó en el servidor | Marca la fila de `cola_sync` como `confirmado` |
| `duplicado` | Ya existía (`uuid_cliente` repetido) | Trata como éxito — marca `confirmado` igual |
| `rechazado {motivo}` | No pasó una validación del servidor | Marca `rechazado`, no reintenta automático |

Un `rechazado` en un registro **no frena el resto del lote** — los demás siguen su camino normal.

## Por qué no hace falta merge

Cada tipo de registro tiene exactamente un rol escritor: la sesión la escribe el piloto, la mezcla/caldo el auxiliar, la validación el jefe de campo desde el panel (fuera de este repo). No hay dos dispositivos editando la misma fila — por eso alcanza con inserciones idempotentes y anulaciones, nunca lógica de merge. Si una pantalla nueva pareciera necesitar que dos roles toquen el mismo registro, la señal correcta es dividirlo en dos registros, consultando con `arquitectura-flutter`.

## Referencias mientras se está offline

Una sesión creada sin conexión referencia su trabajo por `uuid_cliente`, nunca por id de servidor — el id de servidor puede no existir todavía en el dispositivo. El servidor resuelve la referencia real al aplicar el lote.

## Pull de catálogo

`GET /api/sync/catalogo?desde={cursor}` baja órdenes vigentes, lotes y personal, con cursor por `updated_at` del servidor — no se pide "todo" cada vez, se pide "lo que cambió desde la última vez".

## Evidencias

Van en una cola separada de los registros livianos, referenciada por `uuid_cliente`. Una sesión puede quedar `confirmada` con su evidencia todavía subiendo — pero la **validación** (del lado panel) exige la evidencia ya subida, así que un lote sin evidencia sube igual, solo que no se puede validar todavía. Objetivo de compresión: <300 KB por imagen, antes de encolar.

## La prueba que no se negocia

Aplicar el mismo lote de sincronización 10 veces, en orden y en desorden parcial, tiene que dejar el estado final de la base `drift` idéntico. Se escribe antes que la primera pantalla del esqueleto vertical — no después, no "cuando haya tiempo".

## Errores típicos a evitar

- Generar `uuid_cliente` en el servidor o reusar uno entre reintentos: rompe la idempotencia entera.
- Ordenar el lote de push por hora del dispositivo en vez de por `secuencia`: dos dispositivos con relojes desincronizados producen un orden causal incorrecto.
- Tratar `rechazado` como si fuera `duplicado` (reintentar sin revisar el motivo): esconde errores reales de validación.
- Escribir a `drift` sin pasar por la transacción local+outbox: rompe la garantía de que "confirmado en pantalla" y "encolado para sync" son la misma operación atómica.
