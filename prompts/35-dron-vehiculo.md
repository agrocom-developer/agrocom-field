<!-- ciclo: critica=no turno-noche=1 rama=feature/dron-vehiculo etapas=3 descongela=tests -->

# Tarea 35 — Dron como vehículo del proveedor

## Qué hacer

Cargá `verificacion`, `flujo-git-pr`.

1. El proveedor administra sus drones desde el flavor `piloto`: lista, alta, edición y baja lógica de un dron (matrícula o serie, modelo, capacidad de tanque como decimal exacto, estado, propietario), y elige con cuál ejecuta un servicio.
2. Los ciclos de batería se conservan dentro del dron (contador y fecha del último registro); el resto del mantenimiento no se modela.
3. Con red: lectura y escritura contra la API. El dron elegido para un servicio asignado se guarda en `drift` y viaja por el outbox al abrir la sesión de vuelo (columna `dron_id` de la sesión).
4. Un proveedor ve solo sus drones; un dron de Agrocom se ve como asignado, sin editar.
5. Contrato: `docs/api/openapi.yaml` de `agrocom-api` en `develop` (`/Applications/MAMP/htdocs/agrocom-api`, solo lectura). Si un endpoint que esta tarea necesita todavía no está publicado, abrí un PR en borrador con la diferencia exacta, marcá `runs/35.estado` como `BLOQUEADA` y detenete; no inventes el contrato.

## Qué NO hacer

- No agregues mantenimiento, inventario ni repuestos.
- La capacidad de tanque no usa `double`.
- No toques `agrocom-api` ni edites `docs/api/openapi.yaml`.
- No agregues una dependencia sin motivo escrito en el PR.
- No leas ni imprimas credenciales, tokens, keystores ni `key.properties`.
- Los flavors `cliente/`, `piloto/` y `auxiliar/` no se importan entre sí; lo compartido va a `nucleo/`.

## Criterio de aceptación

- `./bin/verify` devuelve 0.
- `flutter test test/nucleo/marketplace/proveedor` devuelve 0, con casos de alta, baja lógica, selección para un servicio y escritura de `dron_id` en la sesión de vuelo.

## Cierre de cada etapa

`runs/35.estado` con una palabra (`PARCIAL`, `OK` o `BLOQUEADA`), `runs/35.md` con lo hecho y lo que falta, y al cerrar con `OK`, `runs/35.pr.md` con el título del PR en la primera línea y el cuerpo debajo.

## Commits

Uno por pieza coherente (esquema, dominio, repositorio, pantalla, tests), en español, imperativo, sin punto final, con el porqué. Sin `Co-Authored-By`. Los borrados van en commits separados y descritos. PR contra `develop`.
