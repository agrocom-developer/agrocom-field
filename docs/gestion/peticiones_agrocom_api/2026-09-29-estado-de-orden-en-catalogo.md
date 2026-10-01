# Petición a `agrocom-api` — estado de la orden en `GET /api/sync/catalogo`

**Fecha:** 29/9/2026 · **Pide:** `agrocom-field` (lado app), a través de la tarea TE-22 del Sprint 17 de `docs/gestion/plan_sprints.md` · **Decide y aprueba:** el dueño · **Ejecuta:** una sesión sobre `agrocom-api` (rama `feature/*`, PR contra `develop`, GitFlow del ADR 0006) · **Estado:** resuelta. El dueño eligió la opción B; `agrocom-api` la ejecutó en #313 (develop `5df5e8f53f98720aec4f523f6a52a3bda33ca0be`) y `agrocom-field` la aplicó en la tarea 26 (TE-22, esquema v14).

## Quién y por qué se requirió el cambio

Lo detectó `agrocom-field` al alinearse con `agrocom-api` (HEAD `44570a17`). El ADR 0022 de `agrocom-api` (19/9/2026) agregó a la orden de aplicación los estados `pausada` y `cancelada`, pero `openapi.yaml` declara que el catálogo **solo entrega órdenes `vigente`** y lo deja como «pendiente conocido»: la app «no se entera de una orden pausada, cancelada o cerrada».

Consecuencia en campo, sin conectividad: un piloto que ya bajó una orden `vigente` sigue viéndola y operándola en su dispositivo después de que el panel la pausó o canceló. El sync no tiene forma de retirar un registro ya entregado. La app no puede resolverlo sola: necesita que el contrato le diga qué orden dejó de estar vigente, y la invariante 6 de `CLAUDE.md` le impide borrar o reescribir localmente lo ya confirmado.

## Qué se pide del lado `agrocom-api`

1. **Decisión de contrato (a aprobar por el dueño antes de codificar).** Opciones:
   - **A (recomendada):** el pull de catálogo entrega también las órdenes que cambiaron de estado desde el cursor del dispositivo, con `estado` explícito (`pausada`, `cancelada`, `consumida`, `vencida`). La app oculta las no vigentes, no las borra.
   - **B:** lista aparte de `ordenes_retiradas` (solo `id` + `estado` + `updated_at`).
2. Actualizar el esquema `OrdenCatalogo` en `openapi.yaml` (se regenera del código, ADR 0014; no se edita a mano) y el ADR 0022, quitando el «pendiente conocido».
3. Respetar el cursor incremental existente: una orden que cambia de estado sube su `updated_at` y reaparece en el siguiente pull.
4. Prueba de contrato del lado servidor: orden `vigente` → `pausada` → `vigente`, y `cancelada`, aparecen con el estado correcto en el pull siguiente.
5. Sin cambios en `POST /api/sync`: la app nunca pausa ni cancela órdenes.

## Qué hará `agrocom-field` después (TE-22)

Ver el contrato ya publicado en `openapi.yaml`, escribir un ADR local, guardar el estado en `OrdenCatalogo` con migración `drift`, ocultar de «Órdenes vigentes» las no vigentes y cubrirlo con la prueba de replay (invariante 10). Qué pasa con una sesión ya abierta sobre una orden pausada lo decide el dueño; hasta entonces no se cambia ese comportamiento.

## Resolución

**Opción B**, `agrocom-api` #313, develop `5df5e8f53f98720aec4f523f6a52a3bda33ca0be`:

- La respuesta suma `ordenes_retiradas: [{id, estado, updated_at}]`, siempre presente y sin `null`.
- `estado` es uno de `pausada`, `consumida`, `cancelada` o `vencida`.
- Una `pausada` que se reanuda vuelve a llegar en `ordenes[]` en el pull siguiente. Hay test del servidor de `vigente → pausada → vigente`.
- Con cursor vacío, `ordenes_retiradas` viene vacía y su posición arranca en el momento del pull.

La misma PR suma `trabajos_retirados` para la pregunta 3 de la petición del 1/10/2026.

**TE-22 desbloqueada y hecha**: tarea 26 de `agrocom-field`, esquema v14.
- La app **marca, nunca borra**: `orden_catalogo.motivo_retiro`, con el estado del servidor, y `retiro_actualizado_en`.
- «Órdenes vigentes» y su detalle las ocultan. Si la orden vuelve en `ordenes[]`, se desmarca y reaparece.
- Como con cursor vacío no llegan retirados, lo retirado antes de #313 se limpia con el barrido completo que fuerza la migración v14: lo que no llega en un pull completo desde cursor vacío queda `fuera_de_alcance`.
- Ese barrido nunca marca la orden de un `trabajo_local` abierto.

## Pendiente

- [x] El dueño elige opción A o B: **B**.
- [x] Se ejecuta en `agrocom-api`: #313, `5df5e8f5`.
- [x] Se actualiza este documento y se marca TE-22 como desbloqueada: hecha en la tarea 26.
- [ ] Qué pasa con una sesión ya abierta sobre una orden pausada lo sigue decidiendo el dueño. La tarea 26 no cambió ese comportamiento: el piloto puede terminar y cerrar. Ver los pendientes de la petición del 1/10/2026 sobre cómo volver a una sesión abierta.
