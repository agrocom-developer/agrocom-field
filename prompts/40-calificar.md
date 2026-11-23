<!-- ciclo: critica=no turno-noche=1 rama=feature/calificar etapas=3 descongela=tests -->

# Tarea 40 — Calificar al proveedor y ver la calificación recibida

## Qué hacer

Cargá `verificacion`, `flujo-git-pr`.

1. Al completarse un servicio, el cliente califica al proveedor (1 a 5 y comentario opcional) en un registro propio. El proveedor ve las calificaciones que recibe, solo lectura; el admin las modera en `agrocom-api`.
2. El proveedor califica al cliente con un registro propio del proveedor, desde el servicio completado; esa escritura pasa por el outbox del flavor `piloto` (con `uuid_cliente`), porque ocurre al cierre en el lote.
3. Una calificación enviada no se edita; una calificación moderada se muestra como retirada sin revelar al cliente el motivo interno. Un solo rol escritor por registro.
4. Contrato: `docs/api/openapi.yaml` de `agrocom-api` en `develop` (`/Applications/MAMP/htdocs/agrocom-api`, solo lectura). Si un endpoint que esta tarea necesita todavía no está publicado, abrí un PR en borrador con la diferencia exacta, marcá `runs/40.estado` como `BLOQUEADA` y detenete; no inventes el contrato.

## Qué NO hacer

- No permitas que el proveedor edite o responda la calificación del cliente.
- No muestres calificaciones de otros proveedores.
- No toques `agrocom-api` ni edites `docs/api/openapi.yaml`.
- No agregues una dependencia sin motivo escrito en el PR.
- No leas ni imprimas credenciales, tokens, keystores ni `key.properties`.
- Los flavors `cliente/`, `piloto/` y `auxiliar/` no se importan entre sí; lo compartido va a `nucleo/`.

## Criterio de aceptación

- `./bin/verify` devuelve 0.
- `flutter test test/cliente/calificar test/piloto/calificaciones` devuelve 0, con casos: calificar una vez, no editar, moderada oculta, calificación del proveedor al cliente por outbox idempotente.
- `flutter test test/nucleo/sync/replay_test.dart` devuelve 0.

## Cierre de cada etapa

`runs/40.estado` con una palabra (`PARCIAL`, `OK` o `BLOQUEADA`), `runs/40.md` con lo hecho y lo que falta, y al cerrar con `OK`, `runs/40.pr.md` con el título del PR en la primera línea y el cuerpo debajo.

## Commits

Uno por pieza coherente (esquema, dominio, repositorio, pantalla, tests), en español, imperativo, sin punto final, con el porqué. Sin `Co-Authored-By`. Los borrados van en commits separados y descritos. PR contra `develop`.
