# Petición a `agrocom-api` — estado de la orden en `GET /api/sync/catalogo`

**Fecha:** 29/9/2026 · **Pide:** `agrocom-field` (lado app), a través de la tarea TE-22 del Sprint 17 de `docs/gestion/plan_sprints.md` · **Decide y aprueba:** el dueño · **Ejecuta:** una sesión sobre `agrocom-api` (rama `feature/*`, PR contra `develop`, GitFlow del ADR 0006) · **Estado:** pendiente de ejecutar.

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

## Pendiente antes de ejecutar

- [ ] El dueño elige opción A o B.
- [ ] Se ejecuta en `agrocom-api`, que deja registrado en su `docs/gestion/` el PR y el SHA.
- [ ] Se actualiza este documento con el número de PR y se marca TE-22 como desbloqueada.
