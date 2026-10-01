<!-- ciclo: critica=si turno-noche=1 rama=feature/catalogo-retirados etapas=3 descongela=tests -->

# Tarea 26 — aplicar órdenes y trabajos retirados (v14)

## Qué hacer

El pull de catálogo es incremental y nunca retiraba nada. Una orden pausada,
consumida, cancelada o vencida, o un trabajo dado de baja, reasignado o
cerrado, seguía apareciendo en la app hasta que el piloto lo cerraba a mano.
Es TE-22 (petición del 29/9/2026) y la pregunta 3 de la petición del
1/10/2026.

`agrocom-api` #313 (opción B) suma a la respuesta dos secciones, siempre
presentes y sin `null`:

- `ordenes_retiradas`: `{id, estado, updated_at}`.
- `trabajos_retirados`: `{id, uuid_cliente, motivo, updated_at}`.

Cargá `verificacion`, `protocolo-sync` y `flujo-git-pr`.

Fuente: el **código** de `agrocom-api` develop @ `5df5e8f5` (solo lectura).
Sobre todo `ObtenerCatalogoDesdeCursor`, `LecturaRetirosCatalogoEloquent`,
`MotivoRetiroTrabajo`, los DTOs de retirados, `registrarCondiciones` y
`openapi.yaml`.

Pasos:

1. **Migración v14.** Agregá a `orden_catalogo` y `trabajo_catalogo` lo
   necesario para marcar una fila como retirada: motivo y momento del
   servidor, con `ALTER TABLE`, nullable, sin perder filas. Reseteá el
   cursor. Prueba v13→v14 con filas reales en todas las tablas; la de replay
   sigue en verde.
2. **Pull.** Aplicá las dos secciones en la MISMA transacción que el upsert y
   el cursor.
   - **Marcar, nunca borrar**: una orden que vuelve a `vigente` llega otra vez
     en `ordenes[]` y se desmarca.
   - Las dos secciones cuentan para el «hay más», y su ausencia se tolera
     como lista vacía.
   - Extendé el fixture, el test de contrato y la prueba de idempotencia: la
     misma página aplicada 10 veces y páginas repetidas fuera de orden dejan
     la misma base.
3. **Lectura.**
   - «Órdenes vigentes» y su detalle excluyen las órdenes retiradas.
   - «Inicio» y los límites del detalle de orden excluyen los trabajos
     retirados.
   - `SesionRepository.limitesCondiciones` espeja exactamente lo que
     documenta #313 para un trabajo retirado.
4. **Barrido completo.** Con cursor vacío el servidor no manda retirados, y
   las filas de otros equipos de antes de #312 quedaron en
   `trabajo_catalogo`. Solo cuando un pull completo desde cursor vacío
   terminó bien (todas las páginas, sin error), marcá como retiradas, con el
   motivo local `fuera_de_alcance`, las filas que no llegaron en ese barrido.
   - Nunca marques una que tenga un `trabajo_local` abierto.
   - Sin conexión no se toca nada.
5. **Sesión abierta sobre un trabajo retirado.** No cambies el
   comportamiento: el piloto puede terminar y cerrar. Si no puede volver a la
   sesión cuando «Inicio» deja de mostrar el trabajo, anotalo como pendiente
   sin decidir el flujo.
6. **Peticiones.** Actualizá las del 29/9 y el 1/10 con el PR y el SHA.

## Cómo repartir las etapas

- Etapa 1: migración v14 con su prueba.
- Etapa 2: pull, barrido, fixture, contrato e idempotencia.
- Etapa 3: lectura (órdenes, «Inicio», límites), tests y peticiones.

## Qué NO hacer

- No borres filas de catálogo.
- No cambies el cierre de sesión ni de trabajo, ni el payload del sync.
- No decidas el flujo para volver a una sesión abierta.
- No edites nada de `agrocom-api`.

## Criterio de aceptación

- `./bin/verify` devuelve 0.
- v13→v14 conserva las filas y resetea el cursor.
- Retirar y volver a traer una orden la oculta y la muestra.
- El barrido completo marca solo lo que no llegó y nunca un trabajo con `trabajo_local` abierto; un pull sin conexión o cortado no marca nada.
- Los límites de un trabajo retirado coinciden con #313.

## Cierre obligatorio de cada etapa

- `runs/26.estado`: `PARCIAL`, `OK` o `BLOQUEADA`.
- `runs/26.md`: qué se hizo y qué falta.
- Al cerrar con `OK`, `runs/26.pr.md`, con el título en la primera línea.

## Commits

Uno por pieza: esquema, pull y barrido, lectura, documentos. En español, imperativo, con el porqué. Sin `Co-Authored-By`.
