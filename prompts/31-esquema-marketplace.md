<!-- ciclo: critica=si turno-noche=1 rama=feature/esquema-marketplace etapas=4 descongela=tests -->

# Tarea 31 — Adaptación del esquema `drift` al servicio asignado (migración crítica)

## Qué hacer

Cargá `verificacion`, `protocolo-sync`, `flujo-git-pr`.

1. Adaptá el esquema local de `piloto` y `auxiliar` al marketplace con **una sola migración** que conserva todo registro ya capturado y no sincronizado.
2. Primero leé el esquema actual (`lib/nucleo/db/`) y el `GET /api/sync/catalogo` del contrato. Escribí en el PR la tabla de correspondencia entre lo que hay y lo que queda.
3. Tablas de lectura (catálogo bajado): `servicio_asignado` (uuid del servicio, estado, lote con geometría, hectáreas declaradas como decimal exacto, producto, dosis, límites de vuelo, fecha, datos de contacto del cliente), `dron_asignado` y `persona_asignada`. Reemplazan al catálogo anterior; el cursor del pull se reinicia en la migración para bajar el catálogo nuevo.
4. Tablas de escritura del lote (trabajo y sesión locales, condiciones, incidencias, evidencias, `cola_sync`): se conservan. Si una referencia apuntaba a una orden, pasa a apuntar al servicio por su `uuid`; los registros pendientes en `cola_sync` conservan su `uuid_cliente` y su `secuencia`.
5. Las columnas de hectáreas, litros y dinero son texto decimal exacto (ADR 0002), nunca real.
6. Test de migración: parte de una base de la versión anterior con filas en cada tabla de escritura y en `cola_sync`, migra y comprueba que las filas siguen, con el mismo `uuid_cliente` y orden. Cubrí también una base vacía.
7. La prueba de replay de `nucleo/sync` sigue pasando sin cambiar su criterio.
8. Retirá del esquema solo lo que ya no tiene lectores ni escritores; los borrados van en commits separados y descritos.

## Qué NO hacer

- Nada de `DROP TABLE` ni `DELETE FROM` sin filtro sobre tablas de escritura del lote (el guardarraíl lo bloquea).
- No cambies el payload de `POST /api/sync` ni la lógica del motor de sync salvo lo que obligue la correspondencia de referencias.
- No generes un `uuid_cliente` nuevo para un registro que ya existe.
- No toques `agrocom-api` ni edites `docs/api/openapi.yaml`.
- No agregues una dependencia sin motivo escrito en el PR.
- No leas ni imprimas credenciales, tokens, keystores ni `key.properties`.
- Los flavors `cliente/`, `piloto/` y `auxiliar/` no se importan entre sí; lo compartido va a `nucleo/`.

## Criterio de aceptación

- `./bin/verify` devuelve 0.
- `flutter test test/nucleo/db/migracion_marketplace_test.dart` devuelve 0 (migración con datos, sin pérdida).
- `flutter test test/nucleo/sync/replay_test.dart` devuelve 0.

## Cierre de cada etapa

`runs/31.estado` con una palabra (`PARCIAL`, `OK` o `BLOQUEADA`), `runs/31.md` con lo hecho y lo que falta, y al cerrar con `OK`, `runs/31.pr.md` con el título del PR en la primera línea y el cuerpo debajo.

## Commits

Uno por pieza coherente (esquema, dominio, repositorio, pantalla, tests), en español, imperativo, sin punto final, con el porqué. Sin `Co-Authored-By`. Los borrados van en commits separados y descritos. PR contra `develop` marcado «revisión línea por línea pendiente del dueño».
