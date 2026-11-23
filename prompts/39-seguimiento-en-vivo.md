<!-- ciclo: critica=no turno-noche=1 rama=feature/seguimiento-en-vivo etapas=3 descongela=tests -->

# Tarea 39 — Seguimiento en vivo del servicio para el cliente

## Qué hacer

Cargá `verificacion`, `flujo-git-pr`.

1. El cliente ve el avance de su servicio en el flavor `cliente`: línea de estados (buscando proveedor, asignado, en camino, en ejecución, completado, cancelado), proveedor asignado con su calificación, y durante la ejecución la posición del dron sobre el lote y las hectáreas completadas.
2. Actualización por polling con intervalo moderado o el canal en vivo que publique el contrato; se pausa en segundo plano y al cerrar el servicio. Sin red: se muestra el último estado conocido con su hora y un aviso.
3. Privacidad: la posición solo se muestra mientras el servicio está activo; no se guarda en caché persistente ni en logs. El cliente ve del proveedor solo nombre, calificación y dron.
4. Lista «Mis servicios» del cliente con activos e historial.
5. Contrato: `docs/api/openapi.yaml` de `agrocom-api` en `develop` (`/Applications/MAMP/htdocs/agrocom-api`, solo lectura). Si un endpoint que esta tarea necesita todavía no está publicado, abrí un PR en borrador con la diferencia exacta, marcá `runs/39.estado` como `BLOQUEADA` y detenete; no inventes el contrato.

## Qué NO hacer

- No guardes el rastro de posiciones en el dispositivo.
- Calidad de UI: seguí la política de `CLAUDE.md`. Tokens de `nucleo/ui`, una acción principal por pantalla, estados de carga, vacío, error, sin red y éxito, textos en español con acentos, golden tests en teléfono pequeño y grande.
- No toques `agrocom-api` ni edites `docs/api/openapi.yaml`.
- No agregues una dependencia sin motivo escrito en el PR.
- No leas ni imprimas credenciales, tokens, keystores ni `key.properties`.
- Los flavors `cliente/`, `piloto/` y `auxiliar/` no se importan entre sí; lo compartido va a `nucleo/`.

## Criterio de aceptación

- `./bin/verify` devuelve 0.
- `flutter test test/cliente/seguimiento` devuelve 0, con casos: cada estado de la línea, posición solo en ejecución, sin red muestra el último estado y el cierre del servicio detiene el polling.

## Cierre de cada etapa

`runs/39.estado` con una palabra (`PARCIAL`, `OK` o `BLOQUEADA`), `runs/39.md` con lo hecho y lo que falta, y al cerrar con `OK`, `runs/39.pr.md` con el título del PR en la primera línea y el cuerpo debajo.

## Commits

Uno por pieza coherente (esquema, dominio, repositorio, pantalla, tests), en español, imperativo, sin punto final, con el porqué. Sin `Co-Authored-By`. Los borrados van en commits separados y descritos. PR contra `develop`.
