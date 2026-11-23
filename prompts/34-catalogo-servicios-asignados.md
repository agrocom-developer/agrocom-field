<!-- ciclo: critica=si turno-noche=1 rama=feature/catalogo-servicios-asignados etapas=4 descongela=tests -->

# Tarea 34 — Catálogo de servicios asignados

## Qué hacer

Cargá `verificacion`, `protocolo-sync`, `flujo-git-pr`.

1. Los flavors `piloto` y `auxiliar` leen sus servicios asignados desde `drift`, sobre las tablas de la tarea 31, bajados con el pull con cursor. Objetivo: lista y detalle del servicio asignado sin red.
2. `CatalogoRepository.pull()` aplica `servicios[]` del catálogo con upsert idempotente y marca —nunca borra— los servicios retirados (cancelados o reasignados). El pull se repite en bucle hasta agotar páginas, con tope de iteraciones.
3. Lista «Mis servicios» y detalle en `piloto/servicio_asignado/` y `auxiliar/servicio_asignado/` (cada flavor su pantalla, sobre el repositorio compartido de `nucleo/catalogo`). Los datos de contacto del cliente solo aparecen en un servicio aceptado.
4. Elimina por completo la feature de órdenes del modelo anterior (`lib/features/ordenes`, repositorios, blocs y tests asociados) en commits de borrado separados y descritos. Los textos de la UI dicen «servicio».
5. Test de contrato con un fixture real del catálogo; test de pull idempotente (la misma página dos veces deja la base idéntica).

## Qué NO hacer

- No cambies el motor de push.
- No dejes referencias al catálogo de órdenes en `lib/` ni en `test/`.
- No toques `agrocom-api` ni edites `docs/api/openapi.yaml`.
- No agregues una dependencia sin motivo escrito en el PR.
- No leas ni imprimas credenciales, tokens, keystores ni `key.properties`.
- Los flavors `cliente/`, `piloto/` y `auxiliar/` no se importan entre sí; lo compartido va a `nucleo/`.

## Criterio de aceptación

- `./bin/verify` devuelve 0.
- `flutter test test/nucleo/catalogo test/piloto/servicio_asignado test/auxiliar/servicio_asignado` devuelve 0.
- `grep -rniE 'OrdenCatalogo|orden_catalogo|ordenes_vigentes' lib test` no devuelve coincidencias (exit 1 de grep).

## Cierre de cada etapa

`runs/34.estado` con una palabra (`PARCIAL`, `OK` o `BLOQUEADA`), `runs/34.md` con lo hecho y lo que falta, y al cerrar con `OK`, `runs/34.pr.md` con el título del PR en la primera línea y el cuerpo debajo.

## Commits

Uno por pieza coherente (esquema, dominio, repositorio, pantalla, tests), en español, imperativo, sin punto final, con el porqué. Sin `Co-Authored-By`. Los borrados van en commits separados y descritos. PR contra `develop` marcado «revisión línea por línea pendiente del dueño».
